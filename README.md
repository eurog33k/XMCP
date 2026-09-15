# XMCP

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that gives AI assistants direct control over the [Xojo IDE](https://www.xojo.com). Built in Xojo using [MCPKit](https://github.com/gkjpettet/MCPKit) by Garry Pettet.

XMCP connects to the Xojo IDE via its IPC socket and exposes 34 tools (33 on Windows, where `get_system_log` has no equivalent) that let an AI navigate projects, read and write code, build, run and save projects, create project items, inspect and modify item descriptions and constants, look up Xojo documentation, read debug logs and system output, and estimate request cost - all through the standard MCP protocol over stdin/stdout.

XMCP is built Xojo-first: the IDE tools, the bundled documentation search, and the `examples/` reference templates all exist because the author is a Xojo developer. But nothing in its architecture is Xojo-*only* — the documentation layer (see [Adapting XMCP to your stack](#adapting-xmcp-to-your-stack)) works for any language with a Dash/Zeal docset, and a project working in multiple languages can register several at once.

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
5. On macOS, re-sign afterwards: `codesign --force --sign - /path/to/XMCP` — Xojo signs the build folder ad hoc, and adding the guide to it invalidates that signature. macOS then kills the binary on launch with `Killed: 9` and no output

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
**OpenAI Codex CLI** (`~/.codex/config.toml`):

```toml
[mcp_servers.xmcp]
command = "/path/to/XMCP"
```

Any other MCP-capable client works the same way — XMCP speaks standard MCP over stdin/stdout, so point the client at the binary as its server command.

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

To register one or more third-party `.docset` bundles (repeat the flag per bundle — see [Adapting XMCP to your stack](#adapting-xmcp-to-your-stack)):

```json
{
  "mcpServers": {
    "xmcp": {
      "command": "/path/to/XMCP",
      "args": [
        "--docset-path", "/path/to/PHP.docset",
        "--docset-path", "/path/to/JavaScript.docset"
      ]
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
| `--docset-path PATH` | Path to a Dash/Zeal-style `.docset` bundle. Repeatable — pass once per bundle. |

The server communicates via JSON-RPC over stdin/stdout following the MCP protocol. It is not meant to be run interactively - it is launched by an MCP client (like Claude Code, Codex CLI, or Claude Desktop).

You can start XMCP before the Xojo IDE. IDE-dependent tools will return an error until the IDE socket is available.
XMCP retries both standard socket paths on each IDE request, so tools begin working automatically once the IDE starts.

## Tools

XMCP exposes 31 MCP tools organized into six categories.

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

Reads the source code at the current location in the IDE editor. The `location` parameter is unreliable — omit it and use the IDE's current selection instead.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | No | Dot-separated path to navigate to before reading. If empty, reads from current location. |

#### `set_code`

Writes source code to the current location in the IDE editor. Replaces the entire code content at that location. The `location` parameter is unreliable — omit it and use the IDE's current selection instead. Does not save to disk; the user must save manually (Cmd+S).

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

Builds the current Xojo project. Returns the path to the built application on success, or build errors on failure.

A build blocks the IDE's main thread, so the IDE answers **no** tool until it is done, and a large project takes minutes. The default wait is 30 minutes, sized from measured builds rather than from demos: warm builds of small projects take seconds, the same build after a cold IDE start has taken two minutes, and a real project takes longer still. If the build outlasts it, the build still completes: XMCP keeps the connection open so the IDE can deliver its late reply safely (closing it would kill the IDE - see [Long-running requests](#long-running-requests)), and every tool refuses with a *still executing an earlier request* message until the IDE has answered. Wait, then check the Builds folder or build again.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `build_type` | Integer | No | `3` Windows 32-bit, `19` Windows 64-bit Intel, `25` Windows 64-bit ARM, `9` macOS Universal, `16` macOS 64-bit Intel, `24` macOS 64-bit ARM, `17` Linux 64-bit Intel, `18` Linux 32-bit ARM, `26` Linux 64-bit ARM, `4` Linux 32-bit Intel. Omit to build for the platform XMCP runs on. The target must be enabled in Build Settings. |
| `reveal` | Boolean | No | Reveal the built app in Finder/Explorer after building. Default: false. |
| `timeout` | Integer | No | How long to wait, in milliseconds. Default: 1800000 (30 minutes). Giving up does not stop the build. |

The result carries the built app's path with the IDE's shell escaping removed, so it can be opened as it is. A `buildError` is reported as its error list, and the undocumented `missingFiles` answer - the IDE's way of saying a target needs configuring first, such as an Android build with no key store - is reported as exactly that instead of as an unrecognised object.

#### `run_project`

Runs the current Xojo project in debug mode. Compiling the debug build blocks the IDE the same way `build_project` does, and the same rules apply if it outlasts the timeout.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `timeout` | Integer | No | How long to wait for the debug build to compile and start, in milliseconds. Default: 1800000 (30 minutes). |

#### `stop_project`

Stops the currently running debug session, and verifies it stopped.

The IDE's `DoCommand "Kill"` stops a desktop app but **leaves a console debug build running**, reporting nothing either way. So this asks the IDE first, then checks whether a debug build of the open project (an executable under the project folder whose path contains `.debug`) is still alive, and terminates that process directly if so. It reports which of the two routes worked, and skips XMCP's own executable so it can never stop the server answering the call.

*No parameters.*

#### `save_project`

Saves the current Xojo project to disk (File > Save). The IDE holds changes made by `set_code`, `create_project_item`, `constant_value` and `get_item_description` in memory until saved. Note that `build_project` builds the **in-memory** project, so saving is about getting changes onto disk (for git, for external tools, or for editing files directly), not about making them visible to a build.

*No parameters.*

#### `describe_item`

Lists what a class, module, window or interface contains: every method with its full signature and scope, plus properties, computed properties, constants, enums, event implementations and notes. For a window it also lists control event handlers and the control tree. Members carry their scope and, for a property, whether it is `Shared` or an array; enum values are listed with the numbers they carry, implicit ones included. Pass a member path instead of a container path to get one member on its own — every overload of a method with its code, or a property, computed property, constant, enum or note. Naming a control returns the control and every handler under it. **Anything the listing shows by name can be asked for by that name.**

This is the only way to get any of it — IDE scripting cannot enumerate a class's members, report a signature, reveal that a name is overloaded, or see inside a `.xojo_window`. It works by parsing the project files with [XojoKit](#acknowledgments), so it reports what is **on disk** — it does not save first; see [Reading the project files](#reading-the-project-files).

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `location` | String | Yes | Path to a container (`IDECommunicator`, `Window1`) or a member (`Module1.Foo`, `Window1.Button1.Pressed`). |
| `include_code` | Boolean | No | For a member path, include each match's body. Default: true. |

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

Deletes a project item. Requires an explicit `item_path` and never acts on the current selection. Deleting a container deletes its contents. Reversible with `revert_project` until the project is saved.

Three routes, because the IDE has two independent selections and one of its delete commands is unimplemented. For a **top-level item** (class, module, folder) the tool selects it in the Navigator and issues `DoCommand("Delete")` — both platforms. For a **member** (a method, property or constant) `SelectProjectItem` cannot reach it and the Navigator stays on the *parent*, so `Delete` is never fired there; the tool points the editor at the member and uses `DoCommand("DeleteSelection")`, which works on macOS. Where that does nothing — Windows — it falls back to cutting the member's `#tag` block out of the `.xojo_code` file and reloading the project, and says so, because unlike the other two routes that deletion is already on disk. It refuses rather than guess if the name is overloaded.

Verification is retried until the IDE actually answers: a delete suppresses the output of the script that follows it, and an unanswered check used to be read as success.

Before deleting an item the tool checks that `ProjectItem` — the IDE's Navigator selection — is the item you asked for, so a mismatch refuses rather than deleting the wrong thing.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item_path` | String | Yes | Dot-separated path of the item to delete. |

#### `create_project_item`

Creates a new project item in the Xojo IDE.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `item_type` | String | Yes | One of: `NewClass`, `NewModule`, `NewMethod`, `NewProperty`, `NewConstant`, `NewEvent`, `NewNote`, `NewMenuHandler`, `NewComputedProperty`, `NewSharedMethod`, `NewSharedProperty`, `NewEnum`, `NewStructure`, `NewDelegate`, `NewInterface`, `NewWindow`, `NewContainerControl`, `NewFolder`. `AddEventImplementation` is documented by Xojo but rejected here — see [Known Limitations](#known-limitations). |
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
| `name` | String | Yes | The fully-qualified constant name (e.g. `App.kVersion`). A bare name (e.g. `kVersion`) silently fails in the Xojo IDE scripting API — always qualify with the containing module or class. |
| `value` | String | No | If provided, sets the constant to this value. If omitted, returns the current value. |

#### `save_project`

Saves the current Xojo project to disk. Call this after making changes via `set_code` or other IDE tools to persist them before building or running.

*No parameters.*

#### `analyze_project`

Analyzes the current Xojo project for compile errors and warnings without building. Reports unused variables, type mismatches, deprecated API usage, and other issues. Warnings return as success (they don't block building); errors return as failure.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | String | No | `"project"` (default) — analyze entire project; `"item"` — analyze only the currently selected item. |

#### `debug_control`

Controls an active Xojo debug session. Requires a running debug session started with `run_project`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | String | Yes | One of: `"step_over"`, `"step_into"`, `"step_out"`, `"resume"`, `"pause"`. |

### Documentation Tools

These tools provide access to the local Xojo documentation, enabling the AI to look up classes, search for APIs, and browse available topics. Documentation is auto-detected from `~/Library/Application Support/Xojo/Xojo/<version>/Documentation/` or can be specified with `--docs-path`.

#### `search_docs`

Searches the local Xojo documentation guides and tutorials. Returns matching sections with title and content. Use this for conceptual questions about language features, patterns, and best practices. To look up a specific class, method, or property by name, use `lookup_class` instead.

`search_docs` searches a RAG database and degrades gracefully through three tiers — no configuration required:

1. **Semantic (hybrid)** — when the RAG database is found *and* the embedding server responds on `localhost:8089` (the [XDOX](https://github.com/o3jvind/XDOX) app manages one automatically while it runs).
2. **Keyword (BM25)** — when only the database is available: FTS5 full-text search, still high quality.
3. **Plain text scan** of `llms-full.txt` — last resort when no database exists.

**Database discovery order:** `--db-path` (explicit) → `~/Library/Application Support/dk.o3jvind.xdox/xdox.db` (built and kept up to date by the XDOX app — the recommended setup) → `xojo_rag.db` next to the documentation (legacy XMCP-RAG-Indexer output).

**Multiple Xojo versions:** when XDOX has indexed more than one Xojo version, `search_docs` returns results for the version XDOX currently has active (its status-bar version picker), plus version-independent chunks — the active version is read fresh on every search, so switching it in XDOX takes effect immediately with no restart. Result headers name that version. Legacy databases without per-version data are unaffected.

**Hybrid search pipeline:**
1. Embeds the query with the local embedding model
2. Scores all chunks by cosine similarity (vector search)
3. Scores matching chunks with BM25 (FTS5 full-text search) — catches exact API names that semantic search may miss
4. Combines: `final = 0.7 × cosine + 0.3 × fts`
5. Deduplicates chunks from the same source with near-identical scores
6. Expands context by fetching adjacent chunks for high-scoring matches (score ≥ 0.72)
7. Returns results sorted logically by document position within each source

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | String | Yes | The search term (e.g. `JSONItem`, `FolderItem`, `database`). |
| `max_results` | Integer | No | Maximum number of matching sections to return. Default: 5. |
| `context_lines` | Integer | No | Number of lines of context before and after each match (keyword search only). Default: 10. |

#### `search_notes`

Searches the user's personal Xojo notes, written and curated in the [XDOX](https://github.com/o3jvind/XDOX) app. Notes capture the user's own conventions, hard-won fixes and project-specific knowledge — a complement to the official docs. All notes are searched regardless of which Xojo version is active. Notes marked as version-specific in XDOX and written for an older version are flagged `[possibly outdated — written for Xojo <version>]`; notes marked global (version-independent) are never flagged.

Requires the XDOX database (see discovery order above); against a legacy `xojo_rag.db` the tool responds gracefully that no notes database exists.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | String | Yes | The search term to look for in note titles and bodies. |
| `max_results` | Integer | No | Maximum number of notes to return. Default: 5. |

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

### Docset Tools

These tools search third-party documentation from Dash/Zeal-style `.docset` bundles — the same format used by [Dash](https://kapeli.com/dash) (macOS) and [Zeal](https://zealdocs.org) (Windows/Linux), covering hundreds of languages, frameworks, and libraries via [Dash-User-Contributions](https://github.com/Kapeli/Dash-User-Contributions). Independent of the Xojo-specific documentation tools above — register one or more bundles with `--docset-path` (repeatable) and they're immediately searchable, no restart-time indexing required.

Two on-disk docset layouts are supported: a plain `Contents/Resources/Documents/` HTML tree, and Dash's space-saving `tarix.tgz` archive layout — the latter is extracted once into `~/Library/Application Support/dk.o3jvind.xmcp/docset-cache/` on first read and served from that cache afterward.

#### `list_docsets`

Lists the registered `.docset` bundles by name, with their entry counts. Call this first to discover available docset names before calling `search_docset` or `get_docset_entry`.

*No parameters.*

#### `search_docset`

Searches entry names (class, method, function, guide, etc.) across all registered docsets, or a single one via `docset_name`. Results are grouped by docset when searching all of them.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `query` | String | Yes | The search term to look for (e.g. a class, method, or function name). |
| `docset_name` | String | No | Limit the search to one registered docset by name (as returned by `list_docsets`). If omitted, all registered docsets are searched. |
| `max_results` | Integer | No | Maximum number of matching entries to return per docset. Default: 10. |

#### `get_docset_entry`

Reads the full documentation content for a specific entry from a registered docset, as plain text (HTML stripped). Use `search_docset` first to find the exact `entry_name`.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `docset_name` | String | Yes | The registered docset to read from (as returned by `list_docsets`). |
| `entry_name` | String | Yes | The exact entry name to read (as returned by `search_docset`). |

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

### Disk-File Generation and Validation Tools

These tools generate or validate `.xojo_code`/`.xojo_window` `#tag` syntax directly on disk — no IDE socket call, so they work even when the Xojo IDE is closed. Both read their format rules (block ordering, `Flags`/keyword mapping, Constant `Default` escaping) from a machine-readable JSON block embedded in `usage-guide.md`, so a rule fix takes effect on the next tool call with no rebuild.

#### `scaffold_code_block`

Generates a correctly formatted `#tag` block (Method, Property, Constant, Event definition, Shared method, control event handler, or window event handler) for the caller to insert into a file directly, instead of hand-writing `#tag` syntax from memory.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `block_kind` | String | Yes | One of: `method`, `property`, `constant`, `event_definition`, `shared_method`, `control_event`, `window_event`. |
| `name` | String | Yes | Method/property/constant/event name, or the control name for `control_event`. |
| `visibility` | String | No | `public`, `protected`, or `private`. Applies to `method`/`property`/`shared_method`. Default: `public`. |
| `event_or_signature` | String | No | Event signature (e.g. `Pressed()`) for `control_event`/`window_event`, or parameter list for `event_definition`. |
| `constant_type` | String | No | For `constant` only: `String`, `Integer`, `Double`, `Boolean`, or `Color`. Default: `String`. |
| `default_value` | String | No | For `constant` only: the raw, unescaped default value — this tool escapes it automatically. |
| `target_file_type` | String | No | `xojo_code` or `xojo_window`. Informational only — escaping is identical for both. Default: `xojo_code`. |

#### `lint_project_file`

Validates a `.xojo_code` or `.xojo_window` file on disk for known structural errors: wrong `#tag` block ordering, `Flags`/keyword mismatches, unclosed or mismatched `#tag`/`#tag End` pairs, and unescaped characters in Constant `Default` values. Call this after editing a file directly on disk and before `revert_project`. Reports errors and warnings; never modifies the file.

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | String | Yes | Absolute path to the `.xojo_code` or `.xojo_window` file to validate. |

## Resources

XMCP exposes MCP resources that AI clients can fetch at session start:

| URI                        | Name                | Description                                                                                        |
|----------------------------|----------------------|----------------------------------------------------------------------------------------------------|
| `file://usage-guide.md`    | XMCP Usage Guide     | AI-facing guide: capabilities, limitations, when to use IDE tools vs. direct file editing, and tips |
| `file://examples/<name>`   | Example: `<name>`    | One resource per file in `examples/` — reference templates for correct `.xojo_code`/`.xojo_window` structure |

Both `usage-guide.md` and `examples/` are distributed next to the XMCP binary and are plain files on disk — no rebuild required to change either. Compatible MCP clients (e.g. Claude Code) fetch them automatically via `resources/list` and `resources/read`.

## Adapting XMCP to your stack

XMCP ships configured for Xojo development: the default `usage-guide.md` biases the AI toward IDE tools and Xojo documentation, and `examples/` holds Xojo reference templates. Nothing about the underlying mechanism is Xojo-specific, though — three parts of XMCP are meant to be edited per project or per developer, not just per Xojo version:

- **`--docset-path`** — register any Dash/Zeal `.docset` bundle (see [Docset Tools](#docset-tools)) to make a language, framework, or library's documentation searchable alongside — or instead of — Xojo's own docs. A project mixing Xojo with an HTML/JS/CSS front end, for example, can register docsets for all three and search whichever is relevant.
- **`examples/`** — swap the reference templates for whatever the current language or project actually looks like. The mechanism (one MCP resource per file, auto-discovered from the folder) doesn't care what's in it.
- **`usage-guide.md`** — rewrite the guidance itself: which tools to prefer, in what order, for this particular mix of languages and conventions. It's plain text fetched into the AI's context at session start, not enforced code — treat it as a strong steer, not a guarantee, and back anything that must hold every time (a required namespace, a formatting rule) with a mechanical check like `lint_project_file` instead.

None of this requires touching XMCP's source — a `.xojo_project`-free setup (docsets only, no Xojo IDE running) works fine for the documentation tools; the IDE tools simply return connection errors until a project is opened.

## Architecture

```
XMCP
├── App                    — MCP server entry point, tool registration, docs auto-detection
├── IDECommunicator        — IPC socket communication with Xojo IDE (protocol v2)
├── SemanticSearch         — Optional hybrid search (vector + FTS5, neighbour expansion, cache)
├── Docset                 — Reads a single Dash/Zeal .docset bundle (SQLite index + HTML/tarix)
├── MCPKit/                — MCP protocol framework
│   ├── ServerApplication  — JSON-RPC stdin/stdout server loop
│   ├── Tool               — Base class for MCP tools
│   ├── ToolParameter      — Tool parameter definitions
│   ├── ToolArgument       — Parsed tool arguments
│   ├── ToolResult         — Success/Failure result type
│   ├── OptionParser       — CLI argument parsing
│   └── Option             — CLI option definition
└── Tools/                 — 31 MCP tool implementations
    ├── IDE tools (19)     — Control the Xojo IDE via IPC
    ├── Doc tools (3)      — Search and browse local Xojo documentation
    ├── Docset tools (3)   — Search third-party Dash/Zeal .docset bundles
    ├── Debug tools (2)    — Read crash logs and system diagnostic output
    ├── Cost tools (1)     — Estimate request token cost and alternatives
    └── Disk-file tools (2)— Generate/validate .xojo_code/.xojo_window syntax
```

### IDE Communication

XMCP connects to the Xojo IDE via an `IPCSocket` - a Unix domain socket on macOS and Linux, a TCP socket on `localhost` on Windows (see [The transport underneath](#the-transport-underneath)). It uses the **IDE Communicator Protocol v2**, where messages are NUL-terminated JSON objects:

1. On connect, sends `{"protocol": 2}` to upgrade to protocol v2
2. Requests are sent as `{"tag": "xmcp_1", "script": "Print Location"}`
3. Responses arrive as `{"tag": "xmcp_1", "response": "App.Constructor"}`
4. Tags correlate requests with responses for synchronous operation

One reply can arrive as **several messages under the same tag**: a script's `Print` output and a compiler warning about that script land about a millisecond apart, and an analysis answers with its `buildError` and the `Print` sentinel together. XMCP keeps reading for a short window after the first matching frame (longer when the first part is only a warning, since the real output is then still on its way) and merges the parts: an error part is the answer, otherwise the output is, and a warning is only the answer when it is all there is. The other parts stay attached, which is how a tool can report the warning that accompanied a successful script rather than one or the other.

The reply shapes XMCP recognises: a string (what the script printed), an empty object (the script printed nothing), `scriptError` - a **heterogeneous** array whose entries are `scriptCompilerError`, `scriptRuntimeError` or `scriptCompilerWarning`, so a warnings-only array means the script ran - `buildError` with `errors` and `warnings`, `missingFiles`, `openErrors` and `loadError`. Script error line numbers are reported one lower than the IDE sends them, because the IDE wraps every script in a line of boilerplate before compiling it.

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

- **Windows endpoints have no filesystem entry**, because on Windows an `IPCSocket` is not a file at all but a TCP socket on `localhost` whose port is derived from the path string. `FolderItem.Exists` on the socket path is therefore always `False` there, even while the IDE is listening, so it must never gate the connect. XMCP keeps the existence check as a fast path on macOS and Linux only, and on Windows rules a candidate out with a short (1.5 s) connect timeout instead.
- **The path is per-user.** `%LOCALAPPDATA%` differs between accounts, so XMCP must run as the same Windows user as the IDE. When no listener is found, the error message lists every path that was tried.

If all attempts fail, the tool returns a detailed connection/timeout error.

#### The transport underneath

`IPCSocket` presents one API on every platform - `Path`, `Listen`, `Connect`, `Poll`, `ReadAll`, `IsConnected`, `Close` - but is built on two different things, and several XMCP behaviours follow from which one is in play.

| | macOS / Linux | Windows |
|---|---|---|
| Underneath | Unix domain socket | TCP socket bound to `localhost` |
| `Path` means | a real filesystem entry (`/tmp/XojoIDE`) | a string that is **hashed into the port number** (1025-65535); no file exists |
| Can be pre-checked with `FolderItem.Exists` | yes | never |
| While the IDE is busy (a build) | connects complete into the listen backlog; the IDE removes and recreates its socket file around a build | connects complete into the listen backlog |
| The IDE writes to a peer XMCP has closed | `SIGPIPE`, and the IDE dies (see below) | the write fails with an error; nothing dies |

The Windows facts come from Xojo engineer Joe Ranieri on the Xojo forum: *"On Windows, Xojo IPCSockets are just a TCP socket bound to localhost. The port it listens on is determined by the 'path' of the IPCSocket"* ([IPCSocket path](https://forum.xojo.com/t/ipcsocket-path/13634)). Xojo has said it would like to move Windows to named pipes at some point; until it does, two consequences matter:

- **The path string must match the IDE's exactly** - same drive letter case, same separators, same folder - or XMCP hashes to a different port and finds nothing listening. That is why `Platform.IPCSocketPaths` mirrors the IDE's own `FindIPCPath` step for step rather than approximating it.
- **The port is shared with the rest of the machine.** Any local process can connect to it, and a hash collision with an unrelated service is possible in principle. A `No IDE listener` on Windows with the IDE visibly running is worth checking against `netstat` before assuming a path problem.

Other facts from the [`IPCSocket` reference](https://documentation.xojo.com/api/networking/ipcsocket.html) that XMCP relies on: `Path` is limited to 103 characters; one side must `Listen` before the other can `Connect`; `Close` on one end raises the other end's `Error` event with error 102, which is how `DrainPending` sees the IDE go away; a socket file may linger after the connection closes; and latency is lowest when polling explicitly, which is why `IDECommunicator` drives the socket with `Poll` rather than events. Xojo's own reference client, `Example Projects/.../IDE Scripting/IDECommunicator/v2`, connects, writes the script, polls once and never reads a reply - the tagged request/response framing is the IDE's side of protocol 2, which XMCP implements in full.

An independent implementation worth knowing about is Lodgit's [xojo-ide-communicator](https://github.com/Lodgit/xojo-ide-communicator), a Go CLI for CI use (open, run, build, and drive XojoUnit tests) that speaks the same protocol without any Xojo code. It agrees with XMCP on every point of the wire format - one `{"protocol":2}` NUL-terminated frame after connect, then `{"tag","script"}` requests and `{"tag","response"}` replies, `Print` for values, `Print BuildApp(type, reveal)` for builds - and it treats the same four keys as errors: `buildError`, `loadError`, `openErrors`, `scriptError`, all of which XMCP handles in the tools where they can occur. Two of its choices differ from XMCP's and are instructive. It opens **one connection for the whole session** and sends every request down it, where XMCP connects per request; the IDE supports both, and the per-request model is what produced the queue of abandoned connections described below before parking was added. And it **waits for a reply with no timeout at all** - its socket library blocks in `Read` with no deadline - which is the other way of never closing a socket the IDE will still write to. It is Unix-only (`/private/tmp/XojoIDE` on macOS, `/tmp/XojoIDE` on Linux), so it never met the Windows port hashing.

#### Long-running requests

The IDE executes scripts one at a time on its main thread. A build, or a modal dialog waiting for a click, holds it for minutes, during which it accepts new connections into the listen backlog but answers nothing - and when it is free again it answers everything that queued up, on the connections the requests arrived on.

That is why a request XMCP has given up on must **not** be closed. A write into a closed peer raises `SIGPIPE`, and the Xojo IDE does not ignore that signal: it dies on the spot, mid-build, with no crash report - the system log shows only `exited due to SIGPIPE`. XMCP used to close timed-out sockets, and a 2.5-minute build under the old 120 s limit killed the IDE exactly this way.

So a socket whose request was delivered but not answered in time is *parked* open (`IDECommunicator.AddPending`). While any parked request is outstanding, every new request is refused immediately with the tag, age and script of what the IDE is still working on, rather than being queued behind it and abandoned in turn. `DrainPending`, run before each request, releases a parked socket once the IDE has replied (the reply is discarded), once the IDE has closed the connection (it quit or crashed), or after two hours. The remaining gap is XMCP's own exit: if the MCP client stops the server while a build is running, the sockets close with the process and the IDE is exposed again, so do not restart the client during a long build.

### Reading the project files

Four things IDE scripting cannot answer — a class's members, a method's signature, whether a name is overloaded, and anything inside a `.xojo_window` — are answered by parsing the project files instead. `describe_item` always does this; `get_code` and `list_project_items` fall back to it when the IDE returns nothing.

Those tools read the **files** while every other tool reads the IDE's **memory**, so the two can disagree. They report what is on disk and **do not save first** — each says so in its output.

That is a deliberate reversal. They used to save, on the reasoning that the IDE offers no way to ask whether it has unsaved changes, so writing memory out was the only way to guarantee the two agreed. It also made reading destructive: a member deleted through the IDE stays undoable with `revert_project` until something saves, and inspecting the result was the something. A tool that told you the delete was reversible handed you a verification step that made it permanent. A read should not end an undo.

Two consequences:

- **What the IDE holds unsaved is not shown.** An item created or deleted in the IDE but not yet saved will be missing or still present. Call `save_project` if you need the files to match — bearing in mind that a save is exactly what makes an IDE-side delete permanent.
- **A newer project is never saved either way.** If the project's `RBProjectVersion` is greater than the running IDE's version, saving would rewrite it in the older format, so XMCP refuses and says the files may be behind the IDE.

| Project format | Readable |
|---|---|
| Text (`.xojo_project`) | yes |
| XML (`.xojo_xml_project`) | yes |
| Binary (`.xojo_binary_project`) | **no** — not a text format; save as Text or XML |

### Documentation Auto-Detection

On startup, XMCP scans `SpecialFolder.ApplicationData/Xojo/Xojo/` - `~/Library/Application Support/Xojo/Xojo/` on macOS, `%APPDATA%\Xojo\Xojo\` on Windows - for the newest Xojo version directory that contains `Documentation/llms-full.txt`. This file (along with `llms.txt` and `_sources/*.rst.txt`) is available via **Xojo IDE → Preferences → General → Install Local Documentation** and is intended specifically for LLM consumption.

## Known Limitations

- **`create_project_item` rejects `AddEventImplementation`** — Xojo documents the command, but it never answers and blocks the connection for the full timeout, after which no handler has been added. Verified 2026-08-25 on Windows 11 with Xojo 2026r1.1. XMCP refuses it immediately with the reason rather than hanging. To add an event handler, edit the `.xojo_window` or `.xojo_code` file on disk — a `#tag Events` block for a control, a `#tag Event` block for the window or class itself — and call `revert_project`. This is also why a window-level handler that does not exist yet cannot be created through XMCP at all.

- **`get_system_log` is macOS-only** — it reads the macOS unified log, which has no equivalent elsewhere. On Windows `System.DebugLog` goes to `OutputDebugString`, visible only to an attached debugger, so the tool is not registered there and XMCP exposes 25 tools instead of 26. Use a file-based `App.UnhandledException` handler with `get_debug_log` instead.
- **`revert_project` may briefly open an empty project on Windows** — reloading needs `CloseProject(False)` + `OpenFile`, and on Windows closing the last project window quits the IDE. So when the target is the only workspace window open, `NewConsoleProject` creates an empty unsaved one to hold the IDE up, and it is discarded afterwards; you may see a window appear and disappear. When another project is already open, `WindowCount` reports it and nothing extra is created. On both platforms the reload discards unsaved IDE changes and loses open editor tabs, since the project really is closed and reopened.
- **Do not set `XOJO_AUTOMATION=TRUE` on Windows** — Xojo documents this variable for build automation (it skips the Feedback Crash and Restore Previous Project dialogs), but on Windows the IDE exits immediately after loading a project when it is set. Verified 2026-08-24 with Xojo 2026r1.1: the same `Start-Process` launch keeps the project open with the variable unset or `FALSE`, and shuts the IDE down with it set to `TRUE`. XMCP then reports `No IDE listener` for every tool, because there is no IDE left to talk to.
- **Linux is untested** — the path resolution in `Platform.xojo_code` covers it, but nothing has been verified on Linux.
- **IDE tools require an open project** — the Xojo IDE scripting socket must be available and a project must be loaded.
- **Documentation tools require local docs** — depend on `llms-full.txt`, `llms.txt`, and `_sources/*.rst.txt` files shipped with the Xojo IDE.
- **Docset tools require registered bundles** — `list_docsets`, `search_docset`, and `get_docset_entry` return an error until at least one `--docset-path` is supplied; a docset shipped as a `tarix.tgz` archive is extracted to a local cache on first read, which can take a few seconds for a large bundle.
- **`get_code`, `set_code`, `get_selected_text`, `set_selected_text` require a method or property to be active** — these tools operate on the code editor view. If the selected item in the Navigator is a class, module, or folder (not a method, property, or other code item), they return an error: `No code editor is active. Navigate to a method or property first.`
- **`list_project_items` does not list a class's members** — it enumerates contained project *items*, so listing a class usually returns `{}`. Navigate to members by name instead: `select_project_item`, `get_code` and `set_code` accept full dot-separated paths and reach methods, properties and event implementations. (These navigate by assigning the IDE's `Location`, which reaches members; the `SelectProjectItem` scripting function alone cannot, and is kept only as a fallback for folders.)
- **IPC socket timing after navigation** — the Xojo IDE briefly closes its IPC socket (~2–3 seconds) after certain navigation operations. XMCP handles this with automatic retries (up to 5 × 1 second), so tools work reliably, but sequential IDE calls may take a few seconds longer after navigation.
- **Parallel tool calls are not supported** — the Xojo IDE accepts only one IPC connection at a time. MCP clients that send parallel tool calls (e.g. Claude Code in some modes) may see connection errors on concurrent requests. Sequential tool calls work reliably.

## Acknowledgments

- [MCPKit](https://github.com/gkjpettet/MCPKit) by Garry Pettet — the Xojo MCP framework that XMCP is built on
- [XojoKit](https://github.com/gkjpettet/xojotool) by Garry Pettet — the Xojo project file parser behind `describe_item`, vendored in `src/XojoKit`

## License

MIT
