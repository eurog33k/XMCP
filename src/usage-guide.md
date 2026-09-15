# XMCP Usage Guide for AI Assistants

This file is automatically loaded as an MCP resource when you connect to XMCP. It describes XMCP's capabilities, known limitations, and how to choose the right approach for each task. You can edit this file to add project-specific notes or customise the guidance.

---

## Prerequisites — before using any XMCP tools

**XMCP cannot start Xojo IDE.** All tools communicate via a macOS domain socket (`/tmp/XojoIDE`) that Xojo IDE creates when it launches. If the IDE is not running, every tool call will fail with "IPC socket not found".

**The user must:**

1. Start Xojo IDE manually
2. Open the project they want to work with (File > Open) — XMCP cannot open projects
3. Wait a few seconds after launch before the IPC socket is ready — if tools fail immediately after IDE start, ask the user to wait and retry

**Do not attempt any XMCP tool calls until the user confirms that Xojo IDE is open and the project is loaded.**

---

## What XMCP can do

XMCP gives you direct control over the Xojo IDE via 34 tools (33 on Windows — see *Platform differences* below):

- **Navigate**: `list_project_items`, `get_current_location`, `select_project_item`
- **Read/write code**: `get_code`, `set_code`, `get_selected_text`, `set_selected_text`
- **Build and run**: `build_project`, `run_project`, `stop_project` — `stop_project` asks the IDE to stop the app, then looks for a live debug build under the project folder and terminates it directly if the IDE's Kill did not, because Kill does not stop a console debug build. It says which of the two happened, and distinguishes both from having found nothing running
- **A build blocks the IDE.** While it compiles, the IDE answers *no* tool at all; `build_project` and `run_project` wait 30 minutes by default (`timeout`, in ms). If a build outlasts that, it still completes in the IDE, and every tool refuses with a *still executing an earlier request* message until the IDE has answered. That refusal is deliberate: the connection is kept open so the IDE can reply safely, because closing it makes the IDE crash with SIGPIPE when it finally writes. Do not call other tools in a loop to "check" on a build, and do not restart the MCP client while one is running. Wait, then check the Builds folder or build again
- **Save**: `save_project` — writes the IDE's in-memory project to disk. Call this after `set_code`, `create_project_item`, `constant_value` or `get_item_description` so your changes reach disk
- **Analyze**: `analyze_project` — runs the IDE's Analyze Project (or one item) and reports errors and warnings without building; `build_project` never reports warnings, only this does
- **Debug sessions**: `debug_control` — step over/into/out, resume, pause
- **Create items**: `create_project_item`
- **Inspect and modify**: `get_item_description`, `constant_value`, `get_project_info`, `revert_project`
- **Inspect what an item contains**: `describe_item` lists every method with its full signature, plus properties, constants, enums, event implementations and, for a window, its control event handlers and control tree. This reads the project FILES rather than asking the IDE, which is the only way to get any of it
- **Create a usable method**: `create_project_item` makes an unnamed `Untitled` item, then `set_declaration` gives it a name, parameters, return type and scope, then `set_code` fills in the body. The IDE re-indents whatever `set_code` writes, so a body read back after a save is normalised to IDE style rather than byte-identical to what you sent. All three are needed - `set_code` writes bodies only, so passing a `Function ...` signature line as code just writes it as text. `delete_project_item` removes an item if you created the wrong thing
- **IDE scripting**: `run_ide_script` (escape hatch for anything not covered)
- **Generate and validate disk edits**: `scaffold_code_block` (generate a correctly formatted `#tag` block), `lint_project_file` (validate a `.xojo_code`/`.xojo_window` file on disk)
- **Documentation**: `search_docs`, `lookup_class`, `list_doc_topics`, `search_notes` (personal notes curated in XDOX)
- **Third-party docsets**: `list_docsets`, `search_docset`, `get_docset_entry` (Dash/Zeal `.docset` bundles registered via `--docset-path`)
- **Debugging**: `get_debug_log`, `get_system_log` (macOS only)
- **Cost estimation**: `estimate_request_cost` — call this proactively before broad or documentation-heavy tasks to check whether the approach is likely to be expensive, and to get suggestions for cheaper alternatives

---

## Trust model — XMCP is a full-trust local bridge

XMCP runs as a local process that drives a real Xojo IDE on the user's machine. It is **not** a sandbox. In particular:

- **`run_ide_script` is an unrestricted escape hatch.** It executes arbitrary Xojo IDE scripting code with the IDE's full authority — read or write any file the IDE can reach, modify project code, build, run, install, or shell out via the IDE's scripting surface.
- **`set_code`, `create_project_item`, `build_project`, `run_project`, `revert_project`, `save_project`, `analyze_project`, `debug_control`** all mutate the user's project, run user-authored code, or discard work. None of them ask the IDE for confirmation.
- **Direct file edits** to `.xojo_code` / `.xojo_window` / `.xojo_project` files happen at the filesystem layer with the user's normal write permissions.

This is appropriate for the intended use case: a single trusted MCP client (Claude Code) on the developer's own workstation acting on their explicit instructions. It is **not** appropriate to expose XMCP to an untrusted client or a multi-tenant context — there is no privilege separation, no per-tool capability check, and no audit trail beyond `/tmp/xmcp_debug.log`.

If you (the AI assistant) are about to take a destructive or hard-to-reverse action (build, run, revert, overwriting code, mass file edits), confirm with the user first, even when a tool will technically succeed without asking. The trust the user extends to XMCP is the trust they extend to you.

---


---

## Known limitations and how to work around them

### 0. Two sources of truth: the IDE, and the files

Most tools ask the IDE, which holds the project in memory. Four things the IDE cannot answer at all - a class's members, a method's signature, whether a name is overloaded, and anything inside a `.xojo_window` - are answered instead by parsing the project files. `describe_item` always does this; `get_code` and `list_project_items` fall back to it when the IDE draws a blank.

**Reading the files does NOT save first.** These tools report what is on disk, and say so in their output. They used to save - the IDE cannot be asked whether it has unsaved changes, so writing memory out was the only way to make the two agree - but that made reading destructive: an item deleted through the IDE is undoable with `revert_project` until something saves, and checking the result was the something. Reading no longer ends an undo.

Consequences worth holding on to:

- **Unsaved IDE state is invisible here.** An item you created in the IDE but have not saved will not appear; one you deleted will still appear. Call `save_project` if you need the files to match - remembering that the save is what makes an IDE-side delete permanent.
- **The first IDE save after hand-editing a file rewrites that file in the IDE's own format**: methods reordered alphabetically, indentation normalised, and the standard `#tag ViewProperty` block filled in. Nothing is lost - it is the same code - but expect a large diff the first time, and none afterwards.
- **No save happens if the project was written by a newer Xojo than the running IDE.** Saving would rewrite it in the older format, so XMCP refuses and tells you the files may be behind the IDE instead.
- **`delete_project_item`'s file route is the one place a save still happens.** It has to: it cuts a block out of a file and reloads, so the file must match the IDE first. Every reason to refuse is checked before that save, so a refusal writes nothing - and if the save itself changes the answer, the message says so.

Binary projects (`.xojo_binary_project`) cannot be read at all - the format is not text. Save as Text or XML, which is what you want for version control anyway. Individual items are a separate question from the project format: a text project can hold external items written as XML (`.xojo_xml_code`, `.xojo_xml_window`), which is the usual shape for code shared between projects, and those are read too.

**`save_project` does not migrate anything.** Saving a legacy API 1 project through XMCP leaves it API 1: the file comes back byte-identical, window blocks stay `Window` rather than `DesktopWindow`, and API 1 control types are untouched. Verified on a 40-control API 1 project by comparing md5 before and after. Opening a project in a newer Xojo does not convert it either. If a project looks part-migrated, it already was.

**External items are read, in both project formats.** An external item lives outside the project - the project only holds a reference to it - and both the text and XML formats are followed now. Two things to expect: a *binary* external (`.xojo_binary_code`) cannot be read, and `describe_item` says so rather than calling the item empty; and an external file that is missing on this machine is reported as missing, since an external can be absent from a checkout that does not include it.

### 1. `list_project_items` does not list a class's members

`list_project_items` shows contained project *items* — the classes and modules inside a folder or module — not the methods, properties or events inside a class. Listing a class often returns `{}`.

**Solution**: `describe_item` lists them, by parsing the files. To act on one, navigate to it by name instead. `select_project_item`, `get_code`, `set_code`, `set_declaration` and `delete_project_item` all accept a full dot-separated path and reach methods, properties and event implementations:

```
select_project_item(item_path: "App.Configure")     ✓  → "Selected: App.Configure (Event Implementation)"
get_code(location: "IDECommunicator.NextTag")       ✓
set_code(code: "...", location: "App.MyMethod")     ✓
list_project_items(location: "IDECommunicator")     →  {}   (members are not items)
```

A path that does not exist is reported as `ERROR: Could not navigate to: ...` rather than silently reading the wrong item.

`lookup_class` returns Xojo's shipped documentation verbatim. If a member the compiler accepts is missing from it, the documentation omits it - the compiler is authoritative, not the tool. Do not tell the user their code will not compile on the strength of a doc lookup.

**Descriptions are hex-encoded on disk.** In a `.xojo_code` file a description sits on the `#tag` line as `Description = 5265616473...`, not as readable text - worth knowing before hand-editing one.

**Folders cannot be selected.** IDE scripting has no way to select a folder: `SelectProjectItem` returns False for one and `Location` will not take it, even though `list_project_items` lists its contents perfectly well. So `select_project_item` and `delete_project_item` fail on a folder path - the latter says so specifically rather than claiming the folder does not exist.

**`constant_value` needs a qualified name.** `App.kVersion` works; a bare `kVersion` resolves only against whatever is selected in the Navigator and usually returns nothing. Folder names are not part of the path.

**`describe_item` reaches every member, not just methods.** A member path returns one member on its own: every overload of a method with its code, or a property, computed property, constant, enum or note. Naming a control returns the control and its handlers. The rule is that anything the container listing prints by name can be asked for by that name. `get_code` is the exception - it goes through the IDE, so for an overloaded name it still returns whichever is declared first.

**Overloads are the exception.** A name with several signatures - `Module1.GetFileExtention(f As FolderItem)` and `Module1.GetFileExtention(s As String)` - resolves to one of them, with nothing in the result saying which, and there is no way to name a signature. Call `describe_item` on the member path: it reports every declaration with its signature and code. (This used to say read the `.xojo_code` file by hand, which is what `describe_item` now does for you.)

### 2. Window event handlers cannot be accessed via IDE tools

Window event handlers (e.g. `Window1.Opening`, `Window1.Close`, `Window1.Resized`) live in `.xojo_window` files and cannot be read or written through the IDE scripting API.

**Symptom**: `get_code` or `set_code` returns `ERROR: Could not navigate to: Window1.Opening`

**To read one**: `describe_item` on the window lists every handler with its signature, and a member path returns one on its own - `Window1.Opening`, or `Window1.Timer1.Action` for a control's. It reads the `.xojo_window` file rather than asking the IDE, which is why it can see what `get_code` cannot.

**To write one**: edit the `.xojo_window` file directly on disk and call `revert_project` (see the fallback workflow below). There is no scriptable way to create a handler that does not exist yet - `create_project_item` rejects `AddEventImplementation` because Xojo's command for it never answers.

### 3. Parallel tool calls are not supported

The Xojo IDE accepts only one IPC connection at a time. If the MCP client sends parallel tool calls, some will fail with connection errors.

**Solution**: Always use sequential tool calls when working with XMCP.

### 4. `run_ide_script` returns only the first `Print`

The IDE answers with the value of the **first** `Print` in a script and discards every later one. `Print "one"` followed by `Print "two"` returns `one`. Xojo's protocol documentation says the last value; measured behaviour on 2025r3.1 is the first.

This is a trap worth knowing, because it looks like something else. A script that prints a status line, runs a command, then prints the result returns the *status line* - so the command appears to have produced nothing, or to have killed the script. It didn't; the second `Print` was simply thrown away.

```
Print "before: " + Location          ' <- this is what comes back
ChangeDeclaration("X", "", "", 0, "")
Print "after: " + Location           ' <- discarded, though it ran fine
```

**Solution**: print once, at the point whose value you want. To confirm an effect, make a second `run_ide_script` call. Also note that a command with no value to give - `PropertyValue` on an item it does not support - yields an empty result, which is not a failure either.

**IDE script is XojoScript, not Xojo** - a smaller language than the one you are writing for. Two that bite:

| Fails | Use instead |
|---|---|
| `Str(aBoolean)` - *expects type Double* | `aBoolean.ToString` |
| `Catch e As RuntimeException` - *class RuntimeException is not available* | a bare `Catch` |

Commands that answer nothing at all, so verify in a second call rather than printing after them: `CloseProject`, `DoCommand("Delete")`, `DoCommand("DeleteSelection")`, `DoCommand("Revert")`, `ChangeDeclaration`.

### 5. IPC socket timing after navigation

After certain navigation operations, the Xojo IDE briefly closes its IPC socket (~2–3 seconds). XMCP retries automatically (up to 5 × 1 second), so most calls recover. If a tool times out immediately after navigation, retry once.

---

## Platform differences

XMCP runs on macOS and Windows. What changes:

| | macOS | Windows |
|---|---|---|
| IDE socket | `/tmp/XojoIDE` | `%LOCALAPPDATA%\Temp\XojoIDE` (no file exists at that path — on Windows an `IPCSocket` is a TCP socket on localhost whose port is hashed from that path string) |
| Debug log | `/tmp/xmcp_debug.log` | `%TEMP%\xmcp_debug.log` |
| `get_system_log` | available | **not registered** — no unified-log equivalent |
| `revert_project` | works | works — opens an empty project first if yours is the only window |
| `delete_project_item` | works for items and members | works for both — members are removed by editing the project file, so that deletion is already on disk |
| Docs location | `~/Library/Application Support/Xojo/Xojo/` | `%APPDATA%\Xojo\Xojo\` |
| `get_project_info` paths | POSIX paths | long paths (XMCP converts the IDE's 8.3 short paths back) |

Consequences when writing code for the user:

- Any `App.UnhandledException` handler you add must branch on `TargetWindows` to pick the debug log path — `SpecialFolder.Temporary` is right on Windows but wrong on macOS. See *Tips* below.
- On Windows you cannot read `System.DebugLog` output at all. If the user needs runtime diagnostics there, write to a log file from the app instead of calling `System.DebugLog`.
- XMCP must run as the same OS user as the Xojo IDE on Windows, because the socket path is under that user's profile. A "No IDE listener" error lists every path that was tried.
- If every tool fails with "No IDE listener" on Windows and the IDE seems to close by itself, check for `XOJO_AUTOMATION=TRUE` in the environment: on Windows the IDE exits right after loading a project when that is set. Tell the user to unset it and relaunch the IDE.
- **`revert_project` works on Windows, sometimes with a visible side effect.** Reloading needs the project closed and reopened, and closing the last project window quits the Xojo IDE - so if the project is the only window open, XMCP creates an empty unsaved project to hold the IDE up and discards it afterwards. The user may see a window appear and disappear. If another project is already open, nothing extra is created. If it fails partway it says so and names the path to reopen; it never leaves the IDE dead.

---

## Two routes, and why not to mix them

The IDE keeps its own in-memory copy of the project. There are two ways to change code, and they write to different places:

| Route | Writes to | Gets to the other side by |
|---|---|---|
| `set_code`, `create_project_item`, `constant_value` | the IDE's memory | `save_project` |
| Editing `.xojo_code` / `.xojo_window` on disk | the files | `revert_project` |

**Do not interleave them.** If you edit files on disk and then anything saves from the IDE side - `save_project`, or the user pressing Ctrl/Cmd+S - the IDE writes its in-memory copy over your edits and they are gone. Likewise a reload discards unsaved IDE changes.

Pick one route per change and finish it:

- **Preferred:** `set_code` → `save_project`. Fully scripted, no reload, no clobber risk. Use this for anything IDE scripting can reach.
- **Fallback:** write the file, then `revert_project` before touching the IDE again. Needed for window event handlers and items `get_code` cannot reach. Never call `save_project` after editing files on disk - that overwrites your edits with the IDE's older copy.

## Starting work on a new project — recommended first steps

When you connect to a new Xojo project via XMCP:

1. Call `get_project_info` to confirm the IDE is connected and get the project directory path
2. Check whether `App` already has an `UnhandledException` handler (see below)
3. **If not, proactively offer to add it** — this is essential for diagnosing crashes in built apps

---

## Crash reporting — add UnhandledException to App

In built apps, runtime exceptions are silent unless you add an `UnhandledException` handler. Without it, crashes produce no output visible to XMCP.

Add this to `App.xojo_code` (before the `#tag ViewBehavior` section):

```xojo
#tag Event
    Sub UnhandledException(error As RuntimeException)
      Var msg As String = "Error: " + error.Message + EndOfLine
      msg = msg + "Error Number: " + Str(error.ErrorNumber) + EndOfLine
      If error.Stack <> Nil Then
        msg = msg + "Stack:" + EndOfLine
        For Each frame As String In error.Stack
          msg = msg + "  " + frame + EndOfLine
        Next
      End If

      Var f As New FolderItem("/tmp/xmcp_debug.log")
      Var stream As TextOutputStream = TextOutputStream.Open(f)
      stream.Write(msg)
      stream.Close
    End Sub
#tag EndEvent
```

After adding, ask the user for permission to call `revert_project` to reload the project.

Once in place, use `get_debug_log` after a crash **in a built app** to retrieve the full exception message and stack trace. Without this handler, `get_debug_log` will always return empty — there is nothing to log.

**`UnhandledException` does NOT fire in debug mode.** The Xojo debugger intercepts all exceptions before they reach this handler — they appear in the IDE debugger instead. This handler is only useful in built apps.

**The log file is not cleared automatically.** It may contain data from a previous crash rather than the current one. Always call `get_debug_log` with `clear: true` after reading, so the next crash produces a fresh log.

---

## How to edit code

**Always edit source files directly on disk** — for both `.xojo_code` and `.xojo_window` files. This is the primary editing path, not a fallback.

The recommended workflow, when adding a new `#tag` block (a method, property, constant, event, or event handler):
1. Call `scaffold_code_block` to generate the correctly formatted block instead of hand-writing `#tag` syntax from memory — it produces the right `Flags`/keyword pairing and `.xojo_window` escaping automatically.
2. Insert the generated block into the file on disk (using your client's own `Edit`/`Write` tools).
3. Call `lint_project_file` on the file as a safety net — it catches the four known failure modes (wrong block ordering, `Flags`/keyword mismatches, unclosed `#tag` pairs, `.xojo_window` escape errors), including ones introduced by freehand edits `scaffold_code_block` wasn't used for.
4. Call `revert_project` to reload the file in the IDE.

For edits that only touch code *inside* an existing method body (no new `#tag` blocks), steps 1 and 3 are optional — `scaffold_code_block` has nothing to generate, but running `lint_project_file` afterward is still cheap insurance if you're at all unsure the edit preserved the surrounding tag structure. The minimal workflow is still available:
1. Edit the file on disk (using your client's own `Edit`/`Write` tools)
2. Call `revert_project` to reload it in the IDE

**Do not route edits through `run_ide_script` + `DoShellCommand` + Python/sed.** That path exists as a last resort; it adds fragile quoting, whitespace-sensitivity, and encoding failure modes that the direct approach avoids entirely. If you find yourself writing a shell script to modify a Xojo source file, stop and use your file editing tools instead.

**Do not use `set_code` to write code** — it only covers top-level navigable items, cannot target individual methods, and does not work at all for `.xojo_window` files.

The only exception is when the user explicitly asks you to read or edit code they have selected in the IDE. In that case, `get_code` and `set_code` without a location parameter work reliably for reading the current selection or replacing it. After writing with `set_code`, always remind the user to save the project (Cmd+S) — `set_code` writes to the IDE editor but does not save to disk.

---

## Direct file editing — how to do it

> **`build_project` builds the IDE's in-memory project, not the files on disk.** So on Windows, editing a file on disk and then building will build the *old* code and report success. Either get the project reloaded first, or avoid the disk route entirely: `set_code` writes into the IDE directly and `save_project` writes it out to disk. That `set_code` → `save_project` → `build_project` loop needs no reload in either direction and is the better default on Windows.

When IDE tools cannot access an item, edit the source files directly on disk and reload the project.

Reference examples of all common file structures are in the `examples/` folder next to this file. Use them as templates when creating or editing `.xojo_code` and `.xojo_window` files. If you are editing one of these example files itself (not just copying from it), open `examples/Examples.xojo_project` in Xojo IDE and run Analyze/Build on it afterward — the examples are a real, buildable Desktop project, so a mistake there is caught by the compiler instead of silently being copied into every future session's code.

| File type | Used for | Example |
| --- | --- | --- |
| `<Name>.xojo_code` | Class, module, interface, app-level code | `MyClass.xojo_code`, `App.xojo_code` |
| `<Name>.xojo_window` | Window UI layout, controls, window events, control events | `MainWindow.xojo_window` |
| `<Name>.xojo_menu` | Menu bar definition (separate file, not embedded in window) | `MainMenuBar.xojo_menu` |
| `<Name>.xojo_project` | Project manifest — lists all files and build settings | edit sparingly |

1. **Find the project directory**
   Call `get_project_info` — it returns a `Project Directory:` line with the full path.

2. **Find the right file**
   - Classes, modules, interfaces, app-level code → `<ClassName>.xojo_code`
   - Window UI, controls, and event handlers → `<WindowName>.xojo_window`
   - Menu bars → `<MenuBarName>.xojo_menu`
   - Project manifest → `<ProjectName>.xojo_project`

3. **Edit the file**
   `.xojo_code` and `.xojo_window` are plain text with `#tag` markers. Follow the existing structure exactly — Xojo is sensitive to block ordering (see below).

   Window-level event handlers go in `#tag WindowCode`:

   ```xojo
   #tag WindowCode
       #tag Event
           Sub Opening()
             ' your code here
           End Sub
       #tag EndEvent
   #tag EndWindowCode
   ```

   Control event handlers (e.g. a `DesktopButton`'s `Pressed` event) go in a `#tag Events ControlName` block *after* `#tag EndWindowCode`:

   ```xojo
   #tag Events Button1
       #tag Event
           Sub Pressed()
             MessageBox("Hi")
           End Sub
       #tag EndEvent
   #tag EndEvents
   ```

   Menu item handlers go in `#tag WindowCode` as `#tag MenuHandler` blocks:

   ```xojo
   #tag MenuHandler
       Function FileOpen() As Boolean Handles FileOpen.Action
         ' handle File > Open
         Return True
       End Function
   #tag EndMenuHandler
   ```

4. **Reload in the IDE**
   Ask the user for permission first, then call `revert_project`. The reload is destructive to any unsaved IDE-side edits — saving them first would overwrite the disk changes we just made, so the tool deliberately does not save.

---

## Xojo file structure rules

### Block ordering in `.xojo_code` files

Blocks **must** appear in this order or Xojo will reject or silently corrupt the file:

**Class file:**
1. `#tag Event` definitions (custom events the class can raise)
2. `#tag Method` blocks (Constructor first by convention, then others)
3. `#tag Property` blocks
4. `#tag Constant` blocks
5. `#tag ViewBehavior` — **always last, never add anything after it**

**Module file** (same as class but no `#tag Event`):
1. `#tag Method` blocks
2. `#tag Constant` blocks
3. `#tag Property` blocks
4. `#tag ViewBehavior` — **always last**

**`#tag Note` blocks are exempt from this ordering** — confirmed by direct testing in the Xojo IDE, `#tag Note` compiles successfully anywhere after the opening `#tag Method`/`#tag Class`/`#tag Module` line (e.g. `OptionParser.xojo_code` in this codebase places `Note` blocks between `Method` and `Property`). Only avoid placing a `Note` after `#tag ViewBehavior`, which must still always be last.

**Window file:**
1. `#tag DesktopWindow` … `#tag EndDesktopWindow` (control layout block)
2. `#tag WindowCode` … `#tag EndWindowCode` (window events, menu handlers, methods, properties)
3. `#tag Events ControlName` … `#tag EndEvents` blocks (one per control that has events)
4. `#tag ViewBehavior` — **always last**

### Access modifier flags

Every `#tag Method` and `#tag Property` line carries a `Flags = &hXX` value. The flag **and** the keyword in the declaration line must match — both are required.

| Flag | Modifier | Applies to |
| --- | --- | --- |
| `&h0` | Public | Methods, Properties |
| `&h1` | Protected | Methods, Properties |
| `&h21` | Private | Methods, Properties |

The keyword goes on the declaration line inside the block:

```xojo
#tag Method, Flags = &h1
    Protected Function Helper() As String
      Return "x"
    End Function
#tag EndMethod

#tag Property, Flags = &h21
    Private mName As String
#tag EndProperty
```

**Constants use a different format** — all metadata is on the `#tag Constant` line itself, nothing inside the block:

```xojo
#tag Constant, Name = kMaxItems, Type = Integer, Dynamic = False, Default = "100", Scope = Public
#tag EndConstant

#tag Constant, Name = kSecret, Type = String, Dynamic = False, Default = "", Scope = Private
#tag EndConstant
```

Valid `Scope` values for constants: `Public`, `Protected`, `Private`. Valid `Type` values: `String`, `Integer`, `Double`, `Boolean`, `Color`.

### Shared (class-level) methods

Add the `Shared` keyword before `Function` or `Sub`. The flag value is identical to instance methods:

```xojo
#tag Method, Flags = &h0
    Shared Function Create(name As String) As MyClass
      Return New MyClass(name)
    End Function
#tag EndMethod
```

Called as `MyClass.Create("foo")` — no instance needed.

### Custom event definitions

A `#tag Hook` block inside a **class body** *defines* a new event the class can fire — confirmed by direct IDE testing (2026-09-06, `examples/MyClass.xojo_code`). It contains only the signature — no body:

```xojo
#tag Hook, Flags = &h0
    Event CountChanged(newCount As Integer)
#tag EndHook
```

**`#tag Event` (no `Hook`) is used only for overriding an event the class already inherits** — e.g. a `DesktopButton` subclass overriding its inherited `Pressed` event (see `examples/MyButton.xojo_code`). Writing a hand-authored `#tag Event, Description = "..."` block to *define* a brand-new custom event (rather than override an inherited one) does not match what the IDE itself generates — use `#tag Hook` for that case instead.

Raise a custom event from within the class with `RaiseEvent CountChanged(mCount)`. Consumers implement the handler via `AddEventImplementation` in the IDE, or by editing the `.xojo_window` file directly.

### Non-singleton windows (`ImplicitInstance = False`)

Windows that can be opened multiple times (editor dialogs, detail panels) use `ImplicitInstance = False` in the control block. They must be instantiated explicitly:

```xojo
Var w As New DetailWindow
w.LoadItem("Title", "Body text")
w.Show        ' non-blocking — caller continues
' -- or --
w.ShowModal   ' blocks until window closes
```

The `DetailWindow.xojo_window` example in `examples/` demonstrates this pattern including a `LoadItem()` method, `LayoutControls()`, and `Default`/`Cancel` button flags.

### Note blocks

`#tag Note` blocks are plain-text documentation embedded in the file. They appear before `#tag ViewBehavior`:

```xojo
#tag Note, Name = DesignNotes
    Explain design decisions, invariants, or usage here.
    Free-form text — no special markup needed.
#tag EndNote
```

### String constants in `.xojo_code` and `.xojo_window` files

**Both** file types use the same escaping for `,` / `=` / `'` / non-ASCII characters in a Constant's `Default` value — confirmed empirically (2026-09-05) by round-tripping test values through `constant_value` on a real `.xojo_code` file and reading the resulting bytes on disk. The two file types differ only in how they escape the double quote character.

| Character | `.xojo_code` and `.xojo_window` encoding |
| --- | --- |
| `'` (single quote) | `\'` |
| `=` | `\x3D` |
| `,` (comma) | `\x2C` |
| newline | `\n` |
| Non-ASCII (e.g. `°`) | UTF-8 bytes e.g. `\xC2\xB0` — **not** `\uXXXX` |

**Double quote (`"`) — the two file types differ:**

- **`.xojo_window`**: every `"` in the value is escaped as `\"`.
- **`.xojo_code`**: every `"` in the value is escaped as `\"`, **except the very last `"` character on the line**, which is left raw (`"`) because it is what the parser uses to find the end of the `Default = "..."` field. This holds regardless of where that quote falls in the text — even a value that is a single `"` character encodes as `Default = \"\""` (the first `\"` opens the field, the second bare `"` closes it). A value with quotes only in the middle, e.g. `a"b`, encodes as `Default = \"a\"b"` — the middle quote is escaped, the trailing one is not.

Note: this differs from the isolated, in-method string literal escaping in `.xojo_code` (`""` for an embedded quote inside ordinary code, e.g. `"He said ""hi"""`) — that ordinary-code rule is unrelated to and does not apply to a `#tag Constant` line's `Default` field.

**Fully plain values are written with NO escaping at all, including the opening quote itself** — the IDE only escapes the opening quote when something later in the value requires escaping. `Default = "MyApp"` (a value with no special characters) is written exactly like that, with a raw opening quote and no backslash anywhere on the line. Confirmed directly in the Xojo IDE: this compiles and builds with **no error whatsoever**, but Xojo silently drops the value's first character when the constant is read back — `Default = "MyApp"` round-trips as `"yApp"`, not `"MyApp"`. This is a real, silent data-corruption bug distinct from the truncation bugs below, and it cannot be told apart from a legitimately unescaped plain value just by reading the file — the only fix is to re-enter the value through the IDE's own constant editor (which will then escape it correctly, or leave it alone if it's genuinely safe).

**Never write HTML, JavaScript, or any string containing commas, quotes, or single quotes directly into a constant `Default` value in a `.xojo_code` or `.xojo_window` file on disk.** Missed characters silently truncate the value with no error — this is a project-file-level `#tag Constant` parsing limitation, not limited to `.xojo_window` as earlier assumed.

Use one of these approaches instead:

1. **Paste via the IDE** — enter the raw value in the constant's Default Value field in the Xojo IDE, let the IDE escape it, then save (Cmd+S).
2. **Build at runtime** — assemble the string in a Xojo method using string concatenation. This avoids escaping entirely and is more readable.

### Format Rules (machine-readable — do not restructure this block)

The rules above (block ordering, Flags/keyword mapping, `.xojo_window` escaping) are also encoded here as JSON. `scaffold_code_block` and `lint_project_file` both parse this exact block at runtime — it is their single source of truth, kept next to the prose explanation so a person only edits one place. If Xojo's own format ever changes, or a new edge case is found in practice (like the ones logged in XDOX's project notes — e.g. a literal comma also truncating `.xojo_code` constant defaults, not just `.xojo_window` ones), update the JSON here; both tools pick it up on their next call, no rebuild required.

Keep the fenced block valid JSON. Do not remove keys the tools rely on without updating both tools to match.

```json
{
  "flags": {
    "&h0": {"keyword": "", "visibility": "public"},
    "&h1": {"keyword": "Protected", "visibility": "protected"},
    "&h21": {"keyword": "Private", "visibility": "private"}
  },
  "block_order": {
    "xojo_code_class": ["Event", "Method", "Property", "Constant", "ViewBehavior"],
    "xojo_code_module": ["Method", "Constant", "Property", "ViewBehavior"],
    "xojo_window": ["DesktopWindow", "WindowCode", "Events", "ViewBehavior"]
  },
  "constant_escape": {
    "'": "\\'",
    "=": "\\x3D",
    ",": "\\x2C",
    "\n": "\\n",
    "\r": ""
  },
  "constant_quote_rule": {
    "xojo_window": "all quotes escaped as \\\"",
    "xojo_code": "all quotes escaped as \\\" except the last quote character on the line, which stays raw \""
  },
  "constant_types": ["String", "Integer", "Double", "Boolean", "Color"]
}
```

---

## IDE tool limitations to be aware of

### `run_ide_script` shows an empty `Print` result as the literal text `{}`

If a script's `Print` output is an empty string, `run_ide_script` shows this as the literal two-character text `{}` — that reflects an empty result, not an error. Structured tools that go through the same underlying IDE communication (`list_project_items`, `debug_control`, `constant_value`, etc.) normalize this correctly internally and don't leak `{}` into their own success/failure logic, but their MCP output can still render as an empty-looking result when the underlying value genuinely is empty — that's expected, not a sign of failure.

### Never use `DoCommand "Insert..."` to add controls to windows

Using `DoCommand "Insert..."` commands (e.g. `DoCommand "InsertDesktopButton"`) to add UI controls to a window **disconnects the Xojo IDE's IPC socket**, making all subsequent XMCP tool calls fail until the IDE is restarted.

Always add controls by editing the `.xojo_window` file directly on disk instead. Use `examples/Window1.xojo_window` as a reference for the correct control block format and event handler structure.

**`create_project_item` is not affected by this and is safe to use.** The disconnect bug is specific to inserting a control instance onto an already-open window design canvas (`DoCommand "InsertDesktopButton"` and similar `Insert...` commands), not to creating new top-level project items — `create_project_item`'s `item_type` list (`NewMethod`, `NewNote`, `NewWindow`, `NewContainerControl`, etc.) doesn't include any `Insert...` commands, so it can't trigger this bug. New items land only in the IDE's in-memory project state until `save_project` is called, same as `set_code`.

### `select_project_item` cannot navigate to methods or events

The IDE scripting API can navigate to top-level items, classes, modules, and windows — but not to individual methods, properties, or event implementations. Edit the source file directly on disk instead.

This is why the `location` parameter on `get_code`, `set_code`, and `get_item_description` only works for top-level items (classes, modules, windows) — passing a method or property path (e.g. `Module1.AddNumbers`) returns `"Could not navigate to: ..."` even when that method exists, because the underlying navigation call can't reach it. Omit `location` and rely on whatever the user currently has open in the IDE's code editor instead.

`list_project_items` also does not list events — only methods, properties, and constants appear as children.

**In practice this is narrower than it sounds.** `list_project_items` wraps the IDE's `SubLocations` scripting function directly, with no XMCP-side filtering. It returns real children for a location that contains sub-*classes* (e.g. a module like `MCPKit` that holds several classes returns those class names correctly), but returns an empty result for a plain module or class whose only children are methods/properties/constants (e.g. a module with just a `Load` method) — with no error to distinguish that from "this location has no members." There is no reliable way to enumerate a module's methods via IDE tools; read the `.xojo_code` file directly instead.

### `get_current_location` only reflects code-level selections, not module/class rows

The underlying IDE scripting function `Location` (and therefore `get_current_location`, plus `list_project_items` / `get_code` called with no `location` argument, which implicitly use it) updates correctly when the user clicks a **code-level item** in the Navigator — a method, property, or event implementation.

It does **not** update when the user clicks a **module or class row itself** in the Navigator — `Location` keeps reporting the last code-level item that was open inside it instead. The IDE scripting API has no concept of "a module is selected," only "the last code item that was open."

**How to apply:** Don't rely on `get_current_location` (or the no-argument form of other tools) to infer what the user is currently looking at, unless you already know they're focused on a specific method/property/event rather than browsing at the module/class level. When in doubt, ask the user, or use an explicit `location` argument instead of relying on IDE-side "current" state.

### `get_item_description` — real scope limit: code-level items only

`ItemDescription` in the IDE scripting language only applies to code-level items — methods, properties, constants, events. Setting it on a **module or class itself** (e.g. a bare module or class name) silently does nothing: no error, but the value is never readable afterward and is never written to disk, because Xojo's `.xojo_code` format has no `Description=` slot on the class/module header itself. Setting it on a method/property/constant/event works correctly and persists to disk (as a hex-encoded `Description=` attribute on that item's `#tag` line) once `save_project` is called.

**How to apply:** only use `get_item_description`'s `value` parameter on a method/property/constant/event location, not a bare class or module name — the module case reports `"OK"` without actually doing anything.

**Note:** `save_project` can rewrite more of a `.xojo_code` file than the one property being changed — it may normalize trailing whitespace and add the module's default `ViewBehavior` property block (Name/Index/Super/Left/Top) if that module didn't already have one on disk. This is normal Xojo IDE save behavior, not an XMCP bug, but it means a `save_project` call after an unrelated small edit can produce a larger git diff than expected.

### `constant_value` — always use the fully-qualified name

The IDE scripting assignment `ConstantValue(name) = value` never raises an error, even for a name that doesn't exist at all — it silently no-ops. A bare name (e.g. `kVersion`) never resolves, even with the containing module currently selected in the IDE — only the fully-qualified form (`Module.ConstantName`) works. `constant_value` reads the value back after a write and compares it, returning a proper error (`"Constant '...' was not found or the value did not take effect. Use the fully-qualified form Module.ConstantName."`) if the write didn't actually take effect, instead of a false `"OK"`.

**How to apply:** always pass `Module.ConstantName` (or `App.kSomething`) to `constant_value` — never a bare constant name, even if the module is currently selected in the IDE.

### Documentation tools — use search_docs and lookup_class, not list_doc_topics

- `search_docs` — search guides and tutorials by natural-language query. Use this first for any conceptual or how-to question.
- `lookup_class` — look up a specific class or method in the API reference.
- `list_doc_topics` — returns the full documentation index (143,000+ characters). **Never call this to find information** — it wastes tokens and requires multiple slow read passes. Use `search_docs` instead. Only call `list_doc_topics` if the user explicitly asks for a topic overview.

### Third-party docsets — list_docsets, search_docset, get_docset_entry

These three tools are separate from `search_docs`/`lookup_class`/`list_doc_topics` above: they search **Dash/Zeal `.docset` bundles** the user registered with one or more `--docset-path` flags (e.g. framework, language, or library docs unrelated to Xojo itself), not the Xojo documentation. If none are registered, all three fail with a message telling the user to use `--docset-path`.

- `list_docsets` — lists the registered docsets by name with entry counts. Call this first when a docset search might be relevant, to learn the exact docset names available.
- `search_docset` — searches entry names (class, method, function, guide, etc.) across all registered docsets, or a single one via the optional `docset_name` parameter. Prefer scoping to one docset with `docset_name` once you know which one is relevant — it avoids irrelevant matches from unrelated docsets.
- `get_docset_entry` — reads the full plain-text content of one entry. Requires both `docset_name` and the exact `entry_name` as returned by `search_docset`.

Recommended flow: `list_docsets` → `search_docset` (optionally scoped) → `get_docset_entry` for the full content of a specific match.

### IDE scripting quirks (run_ide_script)

- `SelectProjectItem` returns a Boolean — always capture the return value: `Dim r As Boolean = SelectProjectItem("Window1")`
- `GetProjectItem` does not exist in the IDE scripting language — using it causes a compile error
- Avoid declaring variables as `ProjectItem` — it is a method name in the scripting language, not a type

### Parallel tool calls are not supported

The Xojo IDE accepts only one IPC connection at a time. Always use sequential tool calls.

### IPC socket timing after navigation

After certain navigation operations, the IDE briefly closes its IPC socket (~2–3 seconds). XMCP retries automatically. If a tool times out immediately after navigation, retry once.

---

## Running and building — rules and workflow

### Never act without explicit user request

- **Never call `build_project` unless the user explicitly asks you to build**
- **Never call `run_project` unless the user explicitly asks you to run**
- **Never call `revert_project` without asking the user first** — it discards any unsaved IDE-side edits. (XMCP cannot save them first: that would overwrite the disk changes the reload is meant to ingest.)

Always wait for the user's answer before proceeding. Asking a question and then acting anyway defeats the purpose.

### Recommended workflow when the user asks to build

1. **Offer to run first**: Before building, offer to call `run_project` to catch syntax errors. **Note:** Runtime errors will only be visible to the user in the Xojo IDE debugger — not to XMCP.
2. **Run and ask for feedback**: After `run_project` returns, always ask the user if they see any errors or exceptions in the IDE — XMCP cannot see runtime behaviour in debug mode.
3. **Only build if run succeeds** — or if the user explicitly wants to build anyway.

### What run_project and build_project can and cannot see

| | `run_project` | `build_project` |
| --- | --- | --- |
| Syntax errors | ✓ Returns error | ✓ Returns error |
| Runtime exceptions (debug mode) | ✗ Invisible — IDE debugger catches them | — |
| Runtime exceptions (built app) | — | ✗ Invisible without `UnhandledException` |
| Build output on disk | — | ✓ Verify `.app` exists after build |

**After `run_project` returns "Project launched in debug mode"**: always ask the user if the app is behaving correctly and if they see any exceptions in the IDE debugger.

**Note:** `run_project` catches syntax errors. Runtime exceptions are visible to the user in the Xojo IDE debugger — but not to XMCP.

### save_project — when and why to call it

`set_code` writes to the IDE's in-memory editor but does **not** save to disk. After writing code with `set_code`, call `save_project` before building or running so that the changes are persisted. (Direct file edits on disk are already saved; `save_project` is only needed after `set_code`.)

### analyze_project — check before building

Use `analyze_project` to catch errors and warnings without triggering a full build. It is faster than `build_project` and useful for a quick sanity check after editing code.

- **`scope="project"`** (default) — analyzes the entire project. Use before a build.
- **`scope="item"`** — analyzes only the currently selected item. Use for a fast check on the item you just edited.

Warnings return as success (they don't block building). Errors return as failure with a formatted list identical to `build_project` output.

**Recommended pre-build workflow:**
1. Edit code (direct file edit or `set_code`)
2. `save_project` (if you used `set_code`)
3. `analyze_project` — fix any errors before proceeding
4. `run_project` or `build_project`

### debug_control — stepping through a debug session

When a debug session is active (started with `run_project`) and the app is paused at a breakpoint or exception, use `debug_control` to drive execution:

| Action | Equivalent IDE action |
| --- | --- |
| `step_over` | Step over the current line |
| `step_into` | Step into the method call on the current line |
| `step_out` | Step out of the current method |
| `resume` | Continue running until the next breakpoint or pause |
| `pause` | Pause a running debug session |

**Note:** XMCP cannot read variable values, set breakpoints, or inspect the call stack — those require the Xojo IDE debugger UI. `debug_control` only drives execution flow.

### build_project uses the IDE's Build Settings

`build_project` takes no parameters — it builds using whatever target platforms the user has configured in the IDE's Build Settings (`BuildMac`, `BuildWin32`, etc.). On success it returns "Build succeeded."; on failure it returns the list of build errors. The success message does not include a path, so to confirm the build location, check the project's `Builds - <ProjectName>/` directory.

### Debug mode vs. built app — exception visibility

| Scenario | Exceptions visible to XMCP? | Where to look |
| --- | --- | --- |
| `run_project` (debug mode) | No | User sees them in Xojo IDE debugger |
| Built app with `UnhandledException` | Yes — via `get_debug_log` | `/tmp/xmcp_debug.log` |
| Built app without `UnhandledException` | No | Nowhere — add the handler |

---

## Tips for working effectively with XMCP

- Call `get_project_info` early to understand the project structure and get the directory path
- Use `list_project_items` to explore the project tree before navigating
- Use `run_ide_script` to run arbitrary IDE scripting commands when no dedicated tool exists
- Use `get_system_log` to retrieve `System.DebugLog` output — works for both debug builds (`AppName.debug`) and built apps (`AppName`). **macOS only**: it reads the unified log, which has no equivalent elsewhere, so the tool is not registered on Windows or Linux
- The Xojo debugger intercepts unhandled exceptions in debug builds — `UnhandledException` is not called; exceptions are shown in the IDE debugger instead
- For built apps, add an `App.UnhandledException` handler that writes to the debug log file, then use `get_debug_log` after a crash to retrieve the full exception message and stack trace. The handler must pick the same path XMCP reads — note that `SpecialFolder.Temporary` is correct on Windows but **not** on macOS, where it resolves to a per-process `/var/folders/.../T` path:

    ```xojo
    #If TargetWindows Then
      Var f As FolderItem = SpecialFolder.Temporary.Child("xmcp_debug.log")
    #Else
      Var f As New FolderItem("/tmp/xmcp_debug.log")
    #EndIf
    ```
- On Windows, `get_system_log` is unavailable, so a file-based `UnhandledException` handler is the only way to get diagnostics out of a built app

---

*This file can be edited to add project-specific notes, custom conventions, or additional guidance for your AI assistant.*
