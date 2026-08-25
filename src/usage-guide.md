# XMCP Usage Guide for AI Assistants

This file is automatically loaded as an MCP resource when you connect to XMCP. It describes XMCP's capabilities, known limitations, and fallback strategies. You can edit this file to add project-specific notes or customise the guidance.

---

## What XMCP can do

XMCP gives you direct control over the Xojo IDE via 26 tools (25 on Windows — see *Platform differences* below):

- **Navigate**: `list_project_items`, `get_current_location`, `select_project_item`
- **Read/write code**: `get_code`, `set_code`, `get_selected_text`, `set_selected_text`
- **Build and run**: `build_project`, `run_project`, `stop_project` — `stop_project` verifies the app actually exited and terminates it directly if the IDE could not, because the IDE's Kill command does not stop a console debug build
- **Save**: `save_project` — writes the IDE's in-memory project to disk. Call this after `set_code`, `create_project_item`, `constant_value` or `get_item_description` so your changes reach disk
- **Create items**: `create_project_item`
- **Inspect and modify**: `get_item_description`, `constant_value`, `get_project_info`, `revert_project`
- **Inspect what an item contains**: `describe_item` lists every method with its full signature, plus properties, constants, enums, event implementations and, for a window, its control event handlers and control tree. This reads the project FILES rather than asking the IDE, which is the only way to get any of it
- **Create a usable method**: `create_project_item` makes an unnamed `Untitled` item, then `set_declaration` gives it a name, parameters, return type and scope, then `set_code` fills in the body. The IDE re-indents whatever `set_code` writes, so a body read back after a save is normalised to IDE style rather than byte-identical to what you sent. All three are needed - `set_code` writes bodies only, so passing a `Function ...` signature line as code just writes it as text. `delete_project_item` removes an item if you created the wrong thing
- **IDE scripting**: `run_ide_script` (escape hatch for anything not covered)
- **Documentation**: `search_docs`, `lookup_class`, `list_doc_topics`
- **Debugging**: `get_debug_log`, `get_system_log` (macOS only)
- **Cost estimation**: `estimate_request_cost` — call this proactively before broad or documentation-heavy tasks to check whether the approach is likely to be expensive, and to get suggestions for cheaper alternatives

---

## Known limitations of the IDE scripting API

### 0. Two sources of truth: the IDE, and the files

Most tools ask the IDE, which holds the project in memory. Four things the IDE cannot answer at all - a class's members, a method's signature, whether a name is overloaded, and anything inside a `.xojo_window` - are answered instead by parsing the project files. `describe_item` always does this; `get_code` and `list_project_items` fall back to it when the IDE draws a blank.

**Reading the files means saving first.** The IDE cannot be asked whether it has unsaved changes - no such command exists - so the only way to guarantee the files match memory is to write memory out. Any tool that reads the files therefore issues a save first and says so in its output.

Three consequences worth holding on to:

- **If you have edited a file on disk and not reloaded, that save overwrites your edit** with the IDE's older copy. This is the clobber hazard below, now reachable automatically. Call `revert_project` before anything that reads the files.
- **The first IDE save after hand-editing a file rewrites that file in the IDE's own format**: methods reordered alphabetically, indentation normalised, and the standard `#tag ViewProperty` block filled in. Nothing is lost - it is the same code - but expect a large diff the first time, and none afterwards.
- **No save happens if the project was written by a newer Xojo than the running IDE.** Saving would rewrite it in the older format, so XMCP refuses and tells you the files may be behind the IDE instead.

Binary projects (`.xojo_binary_project`) cannot be read at all - the format is not text. Save as Text or XML, which is what you want for version control anyway.

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

**Folders cannot be selected.** IDE scripting has no way to select a folder: `SelectProjectItem` returns False for one and `Location` will not take it, even though `list_project_items` lists its contents perfectly well. So `select_project_item` and `delete_project_item` fail on a folder path - the latter says so specifically rather than claiming the folder does not exist.

**`constant_value` needs a qualified name.** `App.kVersion` works; a bare `kVersion` resolves only against whatever is selected in the Navigator and usually returns nothing. Folder names are not part of the path.

**Overloads: `describe_item` shows them all.** `get_code` still returns whichever the IDE resolves the bare name to, which is the first declared in the file.

**Overloads are the exception.** A name with several signatures - `Module1.GetFileExtention(f As FolderItem)` and `Module1.GetFileExtention(s As String)` - resolves to one of them, with nothing in the result saying which, and there is no way to name a signature. When you know a method is overloaded, read the `.xojo_code` file on disk to see every version.

### 2. Window event handlers cannot be accessed via IDE tools

Window event handlers (e.g. `Window1.Opening`, `Window1.Close`, `Window1.Resized`) live in `.xojo_window` files and cannot be read or written through the IDE scripting API.

**Symptom**: `get_code` or `set_code` returns `ERROR: Could not navigate to: Window1.Opening`

**Solution**: Edit the `.xojo_window` file directly on disk (see fallback workflow below).

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
| IDE socket | `/tmp/XojoIDE` | `%LOCALAPPDATA%\Temp\XojoIDE` (no file exists at that path — the endpoint is a named pipe) |
| Debug log | `/tmp/xmcp_debug.log` | `%TEMP%\xmcp_debug.log` |
| `get_system_log` | available | **not registered** — no unified-log equivalent |
| `revert_project` | works | works — opens an empty project first if yours is the only window |
| `delete_project_item` | works for items and members | works for **items only** — members must go via disk (delete the `#tag Method` block, then `revert_project`) |
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

---

## Fallback: direct file editing

> **`build_project` builds the IDE's in-memory project, not the files on disk.** So on Windows, editing a file on disk and then building will build the *old* code and report success. Either get the project reloaded first, or avoid the disk route entirely: `set_code` writes into the IDE directly and `save_project` writes it out to disk. That `set_code` → `save_project` → `build_project` loop needs no reload in either direction and is the better default on Windows.

When IDE tools cannot access an item, edit the source files directly on disk and reload the project.

### Step-by-step

1. **Find the project directory**
   Call `get_project_info` — it returns a `Project Directory:` line with the full path to the folder containing all source files.

2. **Find the right file**
   - Each class, module, or app-level code is one `.xojo_code` file (named after the class)
   - Window UI and event handlers are in `.xojo_window` files (one per window)
   - The project manifest is `<ProjectName>.xojo_project` (XML — edit sparingly)

3. **Edit the file directly**
   Use standard file read/write tools. The `.xojo_code` format is plain text with `#tag` markers. Follow the existing structure exactly.

   Window event handlers (Opening, Close, Resized, etc.) go in `#tag WindowCode` using `#tag Event` tags:
   ```
   #tag WindowCode
   	#tag Event
   		Sub Opening()
   		  ' your code here
   		End Sub
   	#tag EndEvent
   #tag EndWindowCode
   ```

4. **Reload in the IDE**
   Call `revert_project` to reload all changed files from disk into the IDE. The user may see a confirmation prompt in the IDE — they need to accept it for the reload to complete.

### When to use direct file editing

| Situation | Use direct editing? |
|-----------|-------------------|
| Window event handler (Opening, Close, Resized, etc.) | Yes — always |
| `select_project_item` fails for a method path | No — use `get_code`/`set_code` with path instead |
| `get_code` fails with "No code editor is active" | Yes — item may not be a code item |
| Adding a new method to an existing class | Either — IDE tools or direct editing both work |
| Modifying window layout or controls | Yes — edit `.xojo_window` directly |

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
