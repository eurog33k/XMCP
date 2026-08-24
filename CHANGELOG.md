# Changelog

All notable changes to XMCP will be documented here.

## [Unreleased]

## [1.3.0] - 2026-08-24

### Added
- `docs/USING-XMCP.md` — a practical guide to working on a Xojo project through XMCP: the two-copies mental model, a first session, the two edit routes and how not to lose work, debugging built apps, platform differences, and troubleshooting
- `select_project_item`, `get_code` and `set_code` now reach methods, properties and event implementations. They navigate by assigning the IDE's `Location`, which reaches members, instead of relying on `SelectProjectItem`, which only reaches top-level items and silently failed on anything deeper. A path that does not exist is reported rather than silently reading the previously selected item
- `revert_project` now works on Windows. Reloading needs the project closed and reopened, and closing the last project window quits the Xojo IDE there - so the close is performed while a generated throwaway project (`%TEMP%\XMCP Host`, stamped with the IDE's own version so it opens without warnings) holds the IDE open, then closed again. `OpenFile` on an already-open project focuses it without reloading, which is what makes the ordering controllable, and every step is verified against `ProjectShellPath`
- `save_project` tool — saves the IDE's in-memory project to disk via `DoCommand "SaveFile"`. Together with `set_code` this gives a complete round trip that needs no project reload, which matters on Windows where `revert_project` is unavailable
- **Windows support.** All platform-dependent paths now live in a new `Platform` module: IPC socket discovery, the debug log location, and the documentation root. Verified on Windows 11 with Xojo 2026r1.1 — MCP handshake, tool listing, IDE connection, documentation lookup, and `revert_project` (against a binary project) all work
- IPC socket discovery now mirrors `FindIPCPath` from Xojo's shipped IDECommunicator v2 example, probing candidate *folders* for writability instead of testing the socket path itself. On Windows the socket resolves to `%LOCALAPPDATA%\Temp\XojoIDE`
- `XOJO_IPCPATH` is now honoured, so XMCP can talk to a specific IDE when several are running side by side
- Connection failures now list every path that was tried and ask whether the IDE is running

### Fixed
- **`build_project` never actually built anything while always reporting success.** Its build-type table was wrong (`14` is iOS Device, not Windows 64-bit; `9` is macOS Universal, not Windows 32-bit) and `0` was not a valid target at all. It also used `DoCommand "BuildApp"`, which answers `{}` both on success and when the IDE ignores the command. Now uses the `BuildApp(type, reveal)` function, which returns the built path, so success is verifiable; an empty result is reported as a failure
- **`revert_project` reported IDE script errors as success** and assumed the reload happened. It now verifies the project state through `ProjectShellPath` rather than trusting the reply, and reports the resolved project path
- JSON-RPC responses are now terminated with an explicit LF. `Print` is `StandardOutputStream.WriteLine`, which emits the platform `EndOfLine` — CRLF on Windows — while the stdio transport is LF delimited. Incoming lines are trimmed so a CRLF-terminated request does not leave a stray CR on the JSON
- Never probe the IPC socket path with `FolderItem.Exists`: on Windows the endpoint has no filesystem entry, so `Exists` is always `False` even while the IDE is listening. The check survives as a fast path on macOS and Linux only, and a bounded connect timeout rules out wrong candidates elsewhere
- `get_project_info` returns long paths on Windows instead of the 8.3 short paths that `ProjectShellPath` hands back

### Known limitations
- `get_system_log` is macOS only and is no longer registered elsewhere (Windows exposes 21 tools instead of 22). `System.DebugLog` goes to `OutputDebugString` on Windows, which only an attached debugger sees — use a file-based `App.UnhandledException` handler with `get_debug_log`
- `revert_project` does not work on Windows. Every reload route was tested: `CloseProject` + `OpenFile` reloads but quits the IDE when it closes the last project window; `DoCommand "Revert"` is undocumented, needs a pending change, and always raises a modal confirmation that blocks the IDE's script engine; re-opening the same project with `OpenFile` is a silent no-op. The tool fails explicitly without touching the IDE
- Do not set `XOJO_AUTOMATION=TRUE` on Windows — the IDE exits immediately after loading a project

## [1.2.0] - 2026-02-24

### Added
- MCP `resources` protocol support: `resources/list` and `resources/read` — clients can now fetch `usage-guide.md` as an MCP resource at session start
- `get_project_info` now returns a `Project Directory:` line with the full path to the project folder, enabling direct file editing workflows
- `usage-guide.md` is now distributed next to the binary and exposed as an MCP resource — AI clients receive it automatically; users can edit it without rebuilding

### Fixed
- Shell injection prevention in `get_system_log`: `process_name` parameter is now validated against a whitelist regex before interpolation into the shell command
- JSON-RPC `id` type preservation: integer ids are now correctly echoed back as integers (not coerced to strings), fixing protocol compliance
- `ToolParameter.ToJSONItem` now emits correct JSON types for Boolean and Integer defaults (not always String)
- `MCPKit.Error()` now emits JSON `null` for missing ids instead of an empty string
- `get_selected_text` and `set_selected_text` now return `Failure` instead of `Success` when the IDE returns an `ERROR:` string
- RequestID lookup fixed: integer ids no longer cause the server to exit with "Missing id" on subsequent requests

### Changed
- `get_system_log` now works for both debug builds (`AppName.debug`) and built apps (`AppName`) — not just debug builds as previously documented
- Actionable error messages in `select_project_item`, `get_code`, and `set_code`: errors now guide the AI to the correct alternative strategy (direct file editing, `revert_project`, etc.)
- `usage-guide.md` expanded with tested guidance: window event handler file format, `list_project_items` event limitation, debug vs. built app logging behavior

## [1.1.0] - 2026-02-23

### Added
- `get_debug_log` tool: reads crash/exception info written by `App.UnhandledException` handlers to `/tmp/xmcp_debug.log`
- `get_system_log` tool: reads `System.DebugLog` output from the macOS unified log for a named debug app process (e.g. `MyApp.debug`)

### Fixed
- `build_project` now correctly passes build type and reveal flag to `DoCommand "BuildApp"` as a single string argument (e.g. `"BuildApp 24 True"`) — comma-separated arguments caused a script compiler error
- XMCP server processes now terminate gracefully when the MCP client closes stdin, preventing zombie processes from accumulating
- `run_project` and `build_project` now correctly capture and report compile errors from the Xojo IDE instead of always returning success
- Error output is formatted as a readable list with error type, message, location, and position

### Changed
- `search_docs` description clarified: it searches guides and tutorials, not the API reference — use `lookup_class` for class/method/property lookups

## [1.0.0] - 2026-01-01

### Added
- Initial release with 20 tools for controlling the Xojo IDE via MCP
