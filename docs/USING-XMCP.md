# Using XMCP with a Xojo project

A practical guide to working on a Xojo project through an AI assistant. For installation and a
tool-by-tool reference see the [README](../README.md); for what the assistant itself is told, see
[`src/usage-guide.md`](../src/usage-guide.md).

---

## 1. Before you start

| | |
|---|---|
| **Xojo IDE running** | XMCP drives the IDE. No IDE, no IDE tools. |
| **A saved project open** | Tools act on the project in the frontmost workspace window. An unsaved, never-written project has no path, and some tools need one. |
| **Same OS user, not elevated** | XMCP finds the IDE through a per-user socket path. An elevated assistant cannot see an IDE running as you. |
| **Local documentation installed** *(optional)* | **Xojo IDE → Preferences → General → Install Local Documentation** enables `search_docs`, `lookup_class` and `list_doc_topics`. |

You can start XMCP before the IDE. IDE tools return a clear error until the socket appears, then
start working on their own — no restart needed.

---

## 2. The mental model

This is the one thing worth internalising, because most surprises come from getting it wrong.

**There are two copies of your project: the one in the IDE's memory, and the files on disk.**

```
   your assistant
         │
         ▼
    ┌────────┐   IPC socket   ┌───────────────┐
    │  XMCP  │ ─────────────► │   Xojo IDE    │
    └────────┘                │  (in memory)  │
                              └───────┬───────┘
                                      │ save / reload
                                      ▼
                              ┌───────────────┐
                              │ .xojo_project │
                              │ .xojo_code    │   ← git lives here
                              │ .xojo_window  │
                              └───────────────┘
```

Some questions only the **files** can answer: what members a class has, a method's signature,
whether a name is overloaded, and anything inside a `.xojo_window`. IDE scripting exposes none of
those. `describe_item` reads the files for you, and `get_code` and `list_project_items` fall back to
them when the IDE draws a blank.

**Anything that reads the files reports what is on disk, and does not save first.** These tools used
to save, on the reasoning that the IDE offers no way to ask whether it has unsaved changes. That made
reading destructive: a member deleted through the IDE stays undoable with `revert_project` until
something saves, and checking the delete was the something. A read should not end an undo. Every such
tool says in its output that it read without saving. Two things follow:

- **What the IDE holds unsaved will not appear** - and something deleted in the IDE but not saved
  will still appear. Call `save_project` if you need them to match, remembering that the save is
  what makes an IDE-side delete permanent.
- **The first IDE save after you hand-edit a file rewrites it in the IDE's format** — methods
  reordered alphabetically, indentation normalised, the standard `#tag ViewProperty` block added.
  The code is unchanged, but the diff is large the first time and empty thereafter. Worth committing
  on its own so later diffs stay readable.
- **A project written by a newer Xojo than your IDE is never saved** — that would rewrite it in the
  older format. XMCP skips the save and warns that the files may be behind.

Binary projects can't be read at all; save as Text or XML.

Consequences that matter in daily use:

- `set_code` changes the IDE's copy. The files on disk do not change until something saves.
- `build_project` compiles the IDE's copy. **Editing a file on disk and then building will build
  the old code** and report success.
- `save_project` pushes the IDE's copy to disk. `revert_project` pulls disk back into the IDE,
  discarding unsaved IDE changes.

---

## 3. A first session

Ask for these in order; the assistant will call the matching tools.

**Get oriented.** "What project is open?" → `get_project_info` returns the project path, the Xojo
version, and the current Navigator location.

**Look around.** "List the top-level items" → `list_project_items` with no location. Pass a folder
or module name to descend. Note that listing a *class* returns `{}` — see
[section 4](#4-what-works-well-and-what-doesnt).

**Read some code.** "Show me `IDECommunicator.NextTag`" → `get_code` with a dot-separated path.
Methods, properties and event implementations all work.

**Change something.** "Add a guard clause to that method" → `set_code`. This writes into the IDE.
Then "save it" → `save_project` if you want it on disk.

**Build and run.** "Build it" → `build_project`. Omit the build type and it targets the platform
you are on; pass one to cross-compile (`19` Windows 64-bit Intel, `9` macOS Universal,
`17` Linux 64-bit Intel — the full table is in the tool's description). "Run it" → `run_project`,
and `stop_project` to end the debug session — which confirms the app really exited, and terminates
the process itself if the IDE couldn't (the IDE's Kill command doesn't stop a console debug build).

**Ask what something contains.** "What's in `IDECommunicator`?" → `describe_item` lists every method
with its signature and scope, plus properties, constants and enums. On a window it also lists the
control event handlers and the control tree. Pass a member path to see one member on its own - every overload of a method with its code, or a property, constant, enum or note. Naming a control returns the control and its handlers. Whatever the listing shows by name can be asked for by that name.

**Create a method from scratch.** Three calls, because the IDE separates them: `create_project_item`
makes an unnamed `Untitled` method, `set_declaration` gives it a name, parameters, return type and
scope, and `set_code` writes the body. `set_code` alone won't do it — it writes bodies only, so a
`Function …` signature passed as code lands as literal text. `delete_project_item` removes an item
if you made the wrong one.

**Anything not covered.** "Run this IDE script: …" → `run_ide_script` is the escape hatch for any
IDE scripting command without a dedicated tool. One trap: the IDE returns only the **first** `Print`
in a script and discards the rest, so print once, at the point whose value you want.

---

## 4. What works well, and what doesn't

**Works well**

- Navigating to and reading/writing any code item by dot-separated path — methods, properties,
  event implementations, constants.
- Building, running and stopping; creating classes, modules, methods, properties and more.
- Reading and setting item descriptions and constant values.
- Searching the local documentation.

**Known rough edges**

| Behaviour | Why | What to do |
|---|---|---|
| `list_project_items` on a class returns `{}` | it lists contained *items*, not a class's members | use `describe_item`, which parses the files; `list_project_items` now falls back to it |
| `get_code` says *"No code editor is active"* | the current location isn't a code item (a class or folder is selected) | pass an explicit `location` to `get_code` instead of relying on the current selection |
| Window event handlers are invisible to IDE scripting | they live in `.xojo_window` | `describe_item` lists them and `get_code` reads them, both by parsing the file; to *change* one, edit the file and `revert_project` — see [section 5](#5-editing-safely) |
| Xojo project formats | Text and XML are readable; binary is not | save as Text or XML — which is what version control wants anyway |
| `set_code` leaves a trailing blank line, and the IDE re-indents the body | code goes through the code editor, which normalises it | harmless; do not expect a byte-identical round-trip |
| A save reformats hand-edited files wholesale | the IDE writes its own canonical layout and ordering | commit that normalisation once; subsequent saves are stable |
| An overloaded method reads back one version | paths carry no signature, so the IDE returns whichever is declared first in the file | read the `.xojo_code` file on disk when you need to see every overload |
| A folder path fails to select or delete | IDE scripting cannot select folders at all, though `list_project_items` still lists their contents | act on the items inside, or use the IDE for the folder itself |
| `constant_value` returns nothing for a bare name | an unqualified name resolves only against the current Navigator selection | qualify it: `App.kVersion` |
| Two tool calls at once fail | the IDE accepts one IPC connection at a time | keep calls sequential |
| A call right after navigation times out | the IDE briefly closes its socket after some navigation | XMCP retries automatically; if one still fails, just retry |
| `run_ide_script` seems to ignore a command | only the first `Print` is returned; a status line printed first is what comes back | print once, and verify effects in a second call |
| `lookup_class` omits a member the compiler accepts | it returns Xojo's shipped docs verbatim, and those docs are sometimes incomplete | treat the compiler as authoritative, not the doc lookup |

---

## 5. Editing safely

There are two routes for changing code, and they write to different places. **Pick one per change
and finish it.**

| Route | Writes to | Gets to the other side by |
|---|---|---|
| `set_code`, `set_declaration`, `create_project_item`, `delete_project_item`, `constant_value` | the IDE's memory | `save_project` |
| Editing `.xojo_code` / `.xojo_window` on disk | the files | `revert_project` |

**The way to lose work** is to interleave them. Edit a file on disk, then let anything save from
the IDE side — `save_project`, or pressing Ctrl/Cmd+S — and the IDE writes its older copy straight
over your edits. In the other direction, a reload discards unsaved IDE changes. Neither tool asks
for confirmation, because both are doing exactly what they were asked.

So:

- **Prefer the IDE route.** `set_code` → `save_project` needs no reload and cannot clobber anything.
- **Use the disk route** for window event handlers and anything `get_code` can't reach. Write the
  file, then `revert_project` *before* touching the IDE again. Never `save_project` after editing
  files on disk.

`revert_project` genuinely closes and reopens the project, so unsaved IDE changes are discarded and
open editor tabs are lost. On Windows, if the project is your only open window, you will also see an
empty project flash open and closed — that's XMCP holding the IDE alive, explained in
[section 7](#7-windows-and-macos).

---

## 6. Debugging a built app

The Xojo debugger intercepts exceptions during debug runs, so `App.UnhandledException` only fires
in **built** apps. Add this to your `App` class and XMCP can read the crash afterwards with
`get_debug_log`:

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

	  #If TargetWindows Then
	    Var f As FolderItem = SpecialFolder.Temporary.Child("xmcp_debug.log")
	  #Else
	    Var f As New FolderItem("/tmp/xmcp_debug.log")
	  #EndIf
	  Var stream As TextOutputStream = TextOutputStream.Open(f)
	  stream.Write(msg)
	  stream.Close
	End Sub
#tag EndEvent
```

The `#If` matters: the handler must write to the same file `get_debug_log` reads —
`/tmp/xmcp_debug.log` on macOS and Linux, `%TEMP%\xmcp_debug.log` on Windows. `SpecialFolder.Temporary`
is deliberately *not* used on macOS, where it resolves to a per-process path the two would not share.

For `System.DebugLog` output on macOS, `get_system_log` reads the unified log — pass the process
name, which for debug builds is your app name plus `.debug`. There is no equivalent on Windows or
Linux, so write to a log file there instead.

---

## 7. Windows and macOS

| | macOS | Windows |
|---|---|---|
| Tools available | 26 | 25 |
| IDE socket | `/tmp/XojoIDE` | `%LOCALAPPDATA%\Temp\XojoIDE` (a named pipe — no file exists at that path) |
| Debug log | `/tmp/xmcp_debug.log` | `%TEMP%\xmcp_debug.log` |
| Documentation | `~/Library/Application Support/Xojo/Xojo/` | `%APPDATA%\Xojo\Xojo\` |
| `get_system_log` | available | **not available** — `System.DebugLog` goes to `OutputDebugString`, which only an attached debugger sees |
| `revert_project` | closes and reopens the project | same, but first opens an empty project to hold the IDE up — skipped if you already have another project open |
| `delete_project_item` | items and members, in memory | items in memory; **members by editing the file**, so already on disk — use source control to undo |

Everything else behaves identically. Two Windows-specific rules:

- **Run the assistant natively**, not under WSL. The IDE's endpoint is a Windows named pipe, which
  a Linux process cannot open — there is nothing to reach through `/mnt/c`.
- **Never set `XOJO_AUTOMATION=TRUE`.** Xojo documents it for build automation, but on Windows the
  IDE exits right after loading a project, and every tool then reports `No IDE listener`.

Running several IDEs at once? Launch each with a distinct `XOJO_IPCPATH` (letters, digits and
underscores only) and set the same value for XMCP, so it talks to the one you mean.

---

## 8. Troubleshooting

**`No IDE listener at …`** — nothing is listening on any candidate path. In order of likelihood:
the IDE isn't running; no project is open; the assistant is running as a different user or
elevated; or (Windows) `XOJO_AUTOMATION` is set and the IDE quit on startup. The error lists every
path that was tried, and `XMCP --help` prints the same list for comparison.

**`No code editor is active`** — the current Navigator location isn't a code item. Pass an explicit
`location` rather than relying on what happens to be selected.

**`Could not navigate to: X`** — no such item at that path. Check spelling and the full dot path.
This error means nothing was read or written, so it is never silently wrong.

**A build succeeded but nothing changed** — you edited files on disk and built without reloading, so
the IDE compiled its own older copy. `revert_project` first, or use `set_code` instead.

**Documentation tools report no documentation** — install it from
**Preferences → General → Install Local Documentation**, or point XMCP at a copy with `--docs-path`.

**Everything hangs** — check the IDE for a modal dialog. While one is open the IDE's script engine
is blocked and every tool waits. Dismiss it and calls resume.

---

## 9. Keeping the cost down

Documentation searches and broad project sweeps are the expensive calls. `estimate_request_cost`
takes a description of what you're about to ask for and estimates the token cost with cheaper
alternatives — worth calling before a wide-ranging task, and free, since it never touches the IDE.
