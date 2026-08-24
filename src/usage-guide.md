# XMCP Usage Guide for AI Assistants

This file is automatically loaded as an MCP resource when you connect to XMCP. It describes XMCP's capabilities, known limitations, and fallback strategies. You can edit this file to add project-specific notes or customise the guidance.

---

## What XMCP can do

XMCP gives you direct control over the Xojo IDE via 22 tools (21 on Windows — see *Platform differences* below):

- **Navigate**: `list_project_items`, `get_current_location`, `select_project_item`
- **Read/write code**: `get_code`, `set_code`, `get_selected_text`, `set_selected_text`
- **Build and run**: `build_project`, `run_project`, `stop_project`
- **Create items**: `create_project_item`
- **Inspect and modify**: `get_item_description`, `constant_value`, `get_project_info`, `revert_project`
- **IDE scripting**: `run_ide_script` (escape hatch for anything not covered)
- **Documentation**: `search_docs`, `lookup_class`, `list_doc_topics`
- **Debugging**: `get_debug_log`, `get_system_log` (macOS only)
- **Cost estimation**: `estimate_request_cost` — call this proactively before broad or documentation-heavy tasks to check whether the approach is likely to be expensive, and to get suggestions for cheaper alternatives

---

## Known limitations of the IDE scripting API

### 1. Cannot navigate to method-level items or events with `select_project_item`

The Xojo IDE scripting API (`SelectProjectItem`) can navigate to top-level items, classes, modules, and windows — but **not** to individual methods, properties, or event implementations within them.

`list_project_items` also does not list events — only methods, properties, and constants appear as children.

**Symptom**: `select_project_item` returns `ERROR: Could not select 'Window1.Button1.Pressed'. The IDE scripting API cannot navigate to method-level items...`

**Solution**: Use `get_code` or `set_code` with the full dot-separated path. These tools navigate automatically before reading or writing.

```
get_code(location: "Window1.Button1.Pressed")      ✓
get_code(location: "App.UnhandledException")       ✓
set_code(code: "...", location: "App.MyMethod")    ✓
select_project_item(item_path: "App.UnhandledException") ✗
list_project_items(location: "App")  → events not listed  ✗
```

### 2. Window event handlers cannot be accessed via IDE tools

Window event handlers (e.g. `Window1.Opening`, `Window1.Close`, `Window1.Resized`) live in `.xojo_window` files and cannot be read or written through the IDE scripting API.

**Symptom**: `get_code` or `set_code` returns `ERROR: Could not navigate to: Window1.Opening`

**Solution**: Edit the `.xojo_window` file directly on disk (see fallback workflow below).

### 3. Parallel tool calls are not supported

The Xojo IDE accepts only one IPC connection at a time. If the MCP client sends parallel tool calls, some will fail with connection errors.

**Solution**: Always use sequential tool calls when working with XMCP.

### 4. IPC socket timing after navigation

After certain navigation operations, the Xojo IDE briefly closes its IPC socket (~2–3 seconds). XMCP retries automatically (up to 5 × 1 second), so most calls recover. If a tool times out immediately after navigation, retry once.

---

## Platform differences

XMCP runs on macOS and Windows. What changes:

| | macOS | Windows |
|---|---|---|
| IDE socket | `/tmp/XojoIDE` | `%LOCALAPPDATA%\Temp\XojoIDE` (no file exists at that path — the endpoint is a named pipe) |
| Debug log | `/tmp/xmcp_debug.log` | `%TEMP%\xmcp_debug.log` |
| `get_system_log` | available | **not registered** — no unified-log equivalent |
| `revert_project` | works | **not supported** — ask the user to reopen the project (see below) |
| Docs location | `~/Library/Application Support/Xojo/Xojo/` | `%APPDATA%\Xojo\Xojo\` |
| `get_project_info` paths | POSIX paths | long paths (XMCP converts the IDE's 8.3 short paths back) |

Consequences when writing code for the user:

- Any `App.UnhandledException` handler you add must branch on `TargetWindows` to pick the debug log path — `SpecialFolder.Temporary` is right on Windows but wrong on macOS. See *Tips* below.
- On Windows you cannot read `System.DebugLog` output at all. If the user needs runtime diagnostics there, write to a log file from the app instead of calling `System.DebugLog`.
- XMCP must run as the same OS user as the Xojo IDE on Windows, because the socket path is under that user's profile. A "No IDE listener" error lists every path that was tried.
- If every tool fails with "No IDE listener" on Windows and the IDE seems to close by itself, check for `XOJO_AUTOMATION=TRUE` in the environment: on Windows the IDE exits right after loading a project when that is set. Tell the user to unset it and relaunch the IDE.
- **On Windows, `revert_project` cannot reload the project.** The only non-interactive reload is `CloseProject` + `OpenFile`, and closing the last project window quits the Xojo IDE. `DoCommand "Revert"` is not a way around it: it needs a modal confirmation click and blocks the IDE while the dialog is open. So on Windows: write your edits to disk as usual, then **tell the user to reload the project** (File > Revert to Saved, or close and reopen) before you read the changed items back. Do not call `revert_project` and assume it worked - it returns an explicit failure there and changes nothing.

---

## Fallback: direct file editing

> **Windows:** step 2 below (`revert_project`) does not work - see *Platform differences*. Write the file, then ask the user to close and reopen the project in the IDE.

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
