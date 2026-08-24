# XMCP

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that gives AI assistants direct control over the [Xojo IDE](https://www.xojo.com). Built in Xojo using [MCPKit](https://github.com/gkjpettet/MCPKit) by Garry Pettet.

XMCP connects to the Xojo IDE via its IPC socket and exposes 25 tools (24 on Windows, where `get_system_log` has no equivalent) that let an AI navigate projects, read and write code, build, run and save projects, create project items, inspect and modify item descriptions and constants, look up Xojo documentation, read debug logs and system output, and estimate request cost - all through the standard MCP protocol over stdin/stdout.

XMCP also ships a `usage-guide.md` file next to the binary, exposed as an MCP resource. Compatible clients (e.g. Claude Code) fetch it automatically at session start, giving the AI immediate awareness of XMCP's capabilities, known IDE scripting limitations, and fallback strategies — without any extra configuration. You can edit the file to add project-specific notes without rebuilding.

**New to XMCP?** See [docs/USING-XMCP.md](docs/USING-XMCP.md) for a practical guide to working on a Xojo project with it — the mental model, a first session, how to edit without losing work, and troubleshooting.

## Requirements

- **Xojo IDE** available for IDE tools (its IPC socket path is discovered automatically; see [IDE Communication](#ide-communication))
- **macOS or Windows** - both are supported. On Windows the socket resolves to `%LOCALAPPDATA%\Temp\XojoIDE` and `get_system_log` is unavailable (see [Known Limitations](#known-limitations)); Linux is untested
- **Xojo documentation** (optional) - install via **Xojo IDE → Preferences → General → Install Local Documentation**, then auto-detected by XMCP

## Installation

1. Open `src/XMCP.xojo_project` in the Xojo IDE
2. Enable the target you want under **Build Settings** (macOS and/or Windows), then build (Build > Build)
3. Note the path to the built binary — `XMCP` on macOS, `XMCP.exe` on Windows
4. Copy `src/usage-guide.md` next to the binary so XMCP can serve it as an MCP resource

**On Windows**, a Xojo console build produces `XMCP.exe` alongside `XojoConsoleFramework64.dll`, the MSVC redistributable DLLs, and an `XMCP Libs` folder of plugin DLLs (`RegExx64.dll` and friends). Keep the whole folder together and point your MCP client at the `.exe` in place — moving the `.exe` on its own will leave it unable to start.

### Configure your MCP client

**Claude Code** (`~/.claude.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "xmcp": {
      "command": "/path/to/XMCP"
    }
  }
}
```

**Claude Desktop** (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "xmcp": {
      "command": "/path/to/XMCP"
    }
  }
}
```

**On Windows**, use the full path to the `.exe` and escape the backslashes:

```json
{
  "mcpServers": {
    "xmcp": {
      "command": "C:\\Users\\you\\XMCP\\XMCP.exe"
    }
  }
}
```

To specify a custom documentation path:

```json
{
  "mcpServers": {
    "xmcp": {
      "command": "/path/to/XMCP",
      "args": ["--docs-path", "/path/to/Documentation"]
    }
  }
}
```

## Usage

```
XMCP [options]
```

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help and list all available tools |
| `-v`, `--verbose` | Enable verbose debug logging to stderr |
| `-d`, `--docs-path PATH` | Path to Xojo documentation directory (auto-detected if omitted) |

The server communicates via JSON-RPC over stdin/stdout following the MCP protocol. It is not meant to be run interactively - it is launched by an MCP client (like Claude Code or Claude Desktop).

You can start XMCP before the Xojo IDE. IDE-dependent tools will return an error until the IDE socket is available.
XMCP retries both standard socket paths on each IDE request, so tools begin working automatically once the IDE starts.

## Tools

XMCP exposes 22 MCP tools organized into four categories.

### IDE Tools

These tools communicate with the Xojo IDE through its IPC socket to navigate, read, write, build, and manage projects.

#### `list_project_items`

Lists child items at a given location in the Xojo IDE Navigator. Returns a tab-delimited list of item names.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | No | Dot-separated project path (e.g. `App` or `Module1.Method1`). Leave empty for top-level items. |

#### `get_current_location`

Returns the currently selected location in the Xojo IDE Navigator and its type (e.g. Class, Method, Window).

*No parameters.*

#### `select_project_item`

Navigates to a specific item in the Xojo IDE Navigator using a dot-separated path.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item_path` | String | Yes | Dot-separated path to the project item (e.g. `App`, `Module1.MyMethod`). |

#### `get_code`

Reads the source code at the current or specified location.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | No | Dot-separated path to navigate to before reading. If empty, reads from current location. |

#### `set_code`

Writes source code to the current or specified location. Replaces the entire code content at that location.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `code` | String | Yes | The source code to write. |
| `location` | String | No | Dot-separated path to navigate to before writing. If empty, writes to current location. |

#### `get_selected_text`

Returns the currently selected text in the code editor, along with selection position and length.

*No parameters.*

#### `set_selected_text`

Replaces the currently selected text in the code editor with new text.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | String | Yes | The replacement text to insert. |
| `selection_start` | Integer | No | Character offset to set the selection start before replacing. Default: -1 (use current). |
| `selection_length` | Integer | No | Number of characters to select before replacing. Default: 0. |

#### `build_project`

Builds the current Xojo project. Returns the path to the built application on success, or build errors on failure. Uses a 120-second timeout for long builds.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `build_type` | Integer | No | `0` Default, `5` macOS (Cocoa), `9` Windows 32-bit, `14` Windows 64-bit, `16` Linux 32-bit, `17` Linux 64-bit, `18` Linux ARM, `24` macOS Universal. Default: 0. |
| `reveal` | Boolean | No | Reveal the built app in Finder after building. Default: false. |

#### `run_project`

Runs the current Xojo project in debug mode.

*No parameters.*

#### `stop_project`

Stops the currently running debug session.

*No parameters.*

#### `save_project`

Saves the current Xojo project to disk (File > Save). The IDE holds changes made by `set_code`, `create_project_item`, `constant_value` and `get_item_description` in memory until saved. Note that `build_project` builds the **in-memory** project, so saving is about getting changes onto disk (for git, for external tools, or for editing files directly), not about making them visible to a build.

*No parameters.*

#### `set_declaration`

Sets a method or property declaration — name, parameters, return type, scope, and what it implements. `create_project_item` creates an unnamed item, so this is the second half of making a usable method: create, declare, then `set_code` for the body. Also renames existing members. For a property, `parameters` carries the default value.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | Yes | New name, without parameters or return type. |
| `location` | String | No | Path to navigate to first. Default: current selection. |
| `parameters` | String | No | Parameter list without brackets, e.g. `fi As FolderItem`. For a property, its default value. |
| `return_type` | String | No | e.g. `String`. Empty for a subroutine. |
| `scope` | Integer | No | `0` Public, `1` Protected, `2` Private. Default: 0. |
| `implements` | String | No | Interface method being implemented. |

#### `delete_project_item`

**macOS only.** Deletes a project item — method, property, constant, class, module or folder. Requires an explicit `item_path` and never acts on the current selection. Deleting a container deletes its contents. Reversible with `revert_project` until the project is saved.

On Windows the underlying `DoCommand "DeleteSelection"` is documented as not implemented and does nothing, so the tool reports failure and changes nothing — delete the item in the IDE instead. It is still attempted rather than refused outright, so it will start working on its own if a future Xojo implements it.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item_path` | String | Yes | Dot-separated path of the item to delete. |

#### `create_project_item`

Creates a new project item in the Xojo IDE.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item_type` | String | Yes | One of: `NewClass`, `NewModule`, `NewMethod`, `NewProperty`, `NewConstant`, `NewEvent`, `NewNote`, `NewMenuHandler`, `NewComputedProperty`, `NewSharedMethod`, `NewSharedProperty`, `NewEnum`, `NewStructure`, `NewDelegate`, `NewInterface`, `NewWindow`, `NewContainerControl`, `NewFolder`, `AddEventImplementation`. |
| `parent_location` | String | No | Dot-separated path to navigate to before creating the item (e.g. `Module1`). |

#### `run_ide_script`

Executes an arbitrary Xojo IDE script. This is an escape hatch for any IDE scripting command not covered by other tools.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `script` | String | Yes | The IDE script code to execute. Use `Print` to return output values. |
| `timeout` | Integer | No | Timeout in milliseconds. Default: 10000 (10 seconds). |

#### `get_project_info`

Returns information about the currently open project including the project file path, Xojo IDE version, current location, location type, and selected item.

*No parameters.*

#### `revert_project`

Reverts the current Xojo project to the version saved on disk. Use this after modifying project files (e.g. `.xojo_window`, `.xojo_code`) directly to reload them in the IDE.

*No parameters.*

#### `get_item_description`

Gets or sets the description of the currently selected project item (method, property, event, etc.).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | No | Dot-separated path to navigate to before reading/writing (e.g. `App.MyMethod`). If empty, uses current location. |
| `value` | String | No | If provided, sets the description to this value. If omitted, returns the current description. |

#### `constant_value`

Gets or sets the value of a project constant. The constant must already exist in the project.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `name` | String | Yes | The constant name. Can be simple (e.g. `kVersion`) or fully qualified (e.g. `App.kVersion`). |
| `value` | String | No | If provided, sets the constant to this value. If omitted, returns the current value. |

### Documentation Tools

These tools provide access to the local Xojo documentation, enabling the AI to look up classes, search for APIs, and browse available topics. Documentation is auto-detected from `~/Library/Application Support/Xojo/Xojo/<version>/Documentation/` or can be specified with `--docs-path`.

#### `search_docs`

Searches the local Xojo documentation guides and tutorials by keyword. Returns matching sections with surrounding context lines. Use this for conceptual questions about language features, patterns, and best practices. To look up a specific class, method, or property by name, use `lookup_class` instead.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | String | Yes | The search term (e.g. `JSONItem`, `FolderItem`, `database`). |
| `max_results` | Integer | No | Maximum number of matching sections to return. Default: 5. |
| `context_lines` | Integer | No | Number of lines of context before and after each match. Default: 10. |

The documentation text is cached in memory after the first search for fast subsequent queries.

#### `lookup_class`

Looks up detailed documentation for a specific Xojo class, control, data type, or API by name. Returns the full structured reStructuredText reference including properties, methods, events, and examples.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `class_name` | String | Yes | The name of the class (e.g. `DesktopButton`, `JSONItem`, `FolderItem`, `String`). |

Automatically tries common prefixes (`Desktop`, `Web`) if the exact name isn't found.

#### `list_doc_topics`

Lists available Xojo documentation topics and pages from the `llms.txt` index. Use this to discover what documentation is available before looking up specific classes.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `filter` | String | No | Keyword to filter topics (e.g. `Desktop`, `database`, `networking`). If empty, returns all topics. |

### Debug Tools

These tools help diagnose runtime errors in Xojo apps by reading exception logs and system diagnostic output. For best results when building an app from scratch with XMCP, add an `App.UnhandledException` handler that writes to `/tmp/xmcp_debug.log`.

#### `get_debug_log`

Reads crash and exception info from `/tmp/xmcp_debug.log` (macOS and Linux) or `%TEMP%\xmcp_debug.log` (Windows). This file is written by `App.UnhandledException` handlers in Xojo apps that use the XMCP debug pattern — see `usage-guide.md` for a handler that picks the right path per platform. Call this after a crash or unexpected termination to retrieve exception details.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `clear` | Boolean | No | If true, deletes the log file after reading it. Default: false. |

#### `get_system_log`

**macOS only** — not registered on other platforms. Reads recent `System.DebugLog` output from the macOS unified log. Works for both debug builds (`AppName.debug`) and built apps (`AppName`).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `process_name` | String | Yes | The process name to filter by. Debug builds use `AppName.debug`; built apps use `AppName`. Use `get_project_info` to find the project name. |
| `seconds` | Integer | No | How many seconds back to search the log. Default: 60, max: 3600. |

### Cost Awareness Tools

These tools estimate likely token cost before execution and suggest lower-cost approaches.

#### `estimate_request_cost`

Estimates expected token impact for a proposed request and optionally uses planned tool names to refine the estimate. Returns `LOW`, `MEDIUM`, or `HIGH`, with reasons and cheaper alternatives.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `request` | String | Yes | Natural-language request to estimate (for example: `Add a ListBox to Window1`). |
| `planned_tools` | String | No | Optional comma-separated tool names you expect to call (for example: `select_project_item,create_project_item`). |

## Resources

XMCP exposes one MCP resource that AI clients can fetch at session start:

| URI | Name | Description |
|-----|------|-------------|
| `file://usage-guide.md` | XMCP Usage Guide | AI-facing guide: capabilities, known limitations, fallback strategies, and tips |

The `usage-guide.md` file is distributed next to the XMCP binary. You can edit it to add project-specific notes or custom conventions without rebuilding. Compatible MCP clients (e.g. Claude Code) fetch it automatically via `resources/list` and `resources/read`.

## Architecture

```
XMCP
├── App                    — MCP server entry point, tool registration, docs auto-detection
├── IDECommunicator        — IPC socket communication with Xojo IDE (protocol v2)
├── MCPKit/                — MCP protocol framework
│   ├── ServerApplication  — JSON-RPC stdin/stdout server loop
│   ├── Tool               — Base class for MCP tools
│   ├── ToolParameter      — Tool parameter definitions
│   ├── ToolArgument       — Parsed tool arguments
│   ├── ToolResult         — Success/Failure result type
│   ├── OptionParser       — CLI argument parsing
│   └── Option             — CLI option definition
└── Tools/                 — 22 MCP tool implementations
    ├── IDE tools (16)     — Control the Xojo IDE via IPC
    ├── Doc tools (3)      — Search and browse local Xojo documentation
    ├── Debug tools (2)    — Read crash logs and system diagnostic output
    └── Cost tools (1)     — Estimate request token cost and alternatives
```

### IDE Communication

XMCP connects to the Xojo IDE via an `IPCSocket` - a Unix domain socket on macOS and Linux, a named-pipe endpoint on Windows. It uses the **IDE Communicator Protocol v2**, where messages are NUL-terminated JSON objects:

1. On connect, sends `{"protocol": 2}` to upgrade to protocol v2
2. Requests are sent as `{"tag": "xmcp_1", "script": "Print Location"}`
3. Responses arrive as `{"tag": "xmcp_1", "response": "App.Constructor"}`
4. Tags correlate requests with responses for synchronous operation

The `IDECommunicator` class handles connection management, tag generation, synchronous send/receive with configurable timeouts, and NUL-terminated message framing using direct `IPCSocket` communication.

For each IDE request, XMCP tries the last successful socket path first, then every candidate path for the platform. Candidates are derived by `Platform.IPCSocketPaths`, which mirrors `FindIPCPath` in Xojo's shipped IDECommunicator v2 example - the reference implementation of the IDE's own path resolution. It probes each candidate *folder* for writability, in the IDE's own order:

| Rung | macOS / Linux | Windows |
|------|---------------|---------|
| 1 | `/tmp` | `C:\tmp` (rarely exists) |
| 2 | `/var/tmp` | `C:\var\tmp` (rarely exists) |
| 3 | `SpecialFolder.Temporary` | `%LOCALAPPDATA%\Temp` <- **in practice, this one** |
| 4 | `SpecialFolder.Home` | `%USERPROFILE%` (follows OneDrive when active) |

The socket file name is `XojoIDE`, or the value of the `XOJO_IPCPATH` environment variable when set - which is how you address one specific IDE when several are running.

Two platform differences matter:

- **Windows endpoints have no filesystem entry.** `FolderItem.Exists` on the socket path is always `False` there, even while the IDE is listening, so it must never gate the connect. XMCP keeps the existence check as a fast path on macOS and Linux only, and on Windows rules a candidate out with a short (1.5 s) connect timeout instead.
- **The path is per-user.** `%LOCALAPPDATA%` differs between accounts, so XMCP must run as the same Windows user as the IDE. When no listener is found, the error message lists every path that was tried.

If all attempts fail, the tool returns a detailed connection/timeout error.

### Documentation Auto-Detection

On startup, XMCP scans `SpecialFolder.ApplicationData/Xojo/Xojo/` - `~/Library/Application Support/Xojo/Xojo/` on macOS, `%APPDATA%\Xojo\Xojo\` on Windows - for the newest Xojo version directory that contains `Documentation/llms-full.txt`. This file (along with `llms.txt` and `_sources/*.rst.txt`) is available via **Xojo IDE → Preferences → General → Install Local Documentation** and is intended specifically for LLM consumption.

## Known Limitations

- **`get_system_log` is macOS-only** — it reads the macOS unified log, which has no equivalent elsewhere. On Windows `System.DebugLog` goes to `OutputDebugString`, visible only to an attached debugger, so the tool is not registered there and XMCP exposes 24 tools instead of 25. Use a file-based `App.UnhandledException` handler with `get_debug_log` instead.
- **`revert_project` may briefly open an empty project on Windows** — reloading needs `CloseProject(False)` + `OpenFile`, and on Windows closing the last project window quits the IDE. So when the target is the only workspace window open, `NewConsoleProject` creates an empty unsaved one to hold the IDE up, and it is discarded afterwards; you may see a window appear and disappear. When another project is already open, `WindowCount` reports it and nothing extra is created. On both platforms the reload discards unsaved IDE changes and loses open editor tabs, since the project really is closed and reopened.
- **Do not set `XOJO_AUTOMATION=TRUE` on Windows** — Xojo documents this variable for build automation (it skips the Feedback Crash and Restore Previous Project dialogs), but on Windows the IDE exits immediately after loading a project when it is set. Verified 2026-08-24 with Xojo 2026r1.1: the same `Start-Process` launch keeps the project open with the variable unset or `FALSE`, and shuts the IDE down with it set to `TRUE`. XMCP then reports `No IDE listener` for every tool, because there is no IDE left to talk to.
- **Linux is untested** — the path resolution in `Platform.xojo_code` covers it, but nothing has been verified on Linux.
- **IDE tools require an open project** — the Xojo IDE scripting socket must be available and a project must be loaded.
- **Documentation tools require local docs** — depend on `llms-full.txt`, `llms.txt`, and `_sources/*.rst.txt` files shipped with the Xojo IDE.
- **`get_code`, `set_code`, `get_selected_text`, `set_selected_text` require a method or property to be active** — these tools operate on the code editor view. If the selected item in the Navigator is a class, module, or folder (not a method, property, or other code item), they return an error: `No code editor is active. Navigate to a method or property first.`
- **`list_project_items` does not list a class's members** — it enumerates contained project *items*, so listing a class usually returns `{}`. Navigate to members by name instead: `select_project_item`, `get_code` and `set_code` accept full dot-separated paths and reach methods, properties and event implementations. (These navigate by assigning the IDE's `Location`, which reaches members; the `SelectProjectItem` scripting function alone cannot, and is kept only as a fallback for folders.)
- **IPC socket timing after navigation** — the Xojo IDE briefly closes its IPC socket (~2–3 seconds) after certain navigation operations. XMCP handles this with automatic retries (up to 5 × 1 second), so tools work reliably, but sequential IDE calls may take a few seconds longer after navigation.
- **Parallel tool calls are not supported** — the Xojo IDE accepts only one IPC connection at a time. MCP clients that send parallel tool calls (e.g. Claude Code in some modes) may see connection errors on concurrent requests. Sequential tool calls work reliably.

## Acknowledgments

- [MCPKit](https://github.com/gkjpettet/MCPKit) by Garry Pettet — the Xojo MCP framework that XMCP is built on

## License

MIT
