# XMCP upstream PR — test checklist

Live working copy. Tick here as you run things. The master template lives in this
project's memory (`xmcp-pr-test-checklist`); if the *protocol* changes, update that
one too. Legend: ☐ not run · ✅ passed · ❌ failed · ⬚ n/a

**Rule agreed 2026-09-17: no PR is opened until every applicable box for that PR is
ticked on both platforms, or the gap is explicitly accepted and written down.**

---

No XMCP PR goes to `o3jvind/XMCP` until Gate A passes on both platforms plus that
PR's own list. Tick per platform — macOS and Windows are separate runs, not one.

**Why:** the repo has no automated tests, so the compiler and manual MCP round-trips
are the entire safety net. Three classes of defect have shipped past a green build
here: a binary that cannot start (`Killed: 9`, no output), a build that "succeeds"
while destroying its own executable, and fixes correct for the reported case that
broke the neighbouring one. None are visible without running the thing.

**How to apply:** run Gate A after the final commit on the PR branch, not mid-work.
Record the Windows result explicitly — "untested on Windows" is a legitimate PR
caveat, but it must be stated, never implied.

## How to actually run these

Almost every check is an **MCP tool call**, run by the Claude Code session on that
machine with XMCP connected — not a command you type. There is no CLI for
`lint_project_file` or `analyze_project`. Shell commands below are run from the
**repo root**, not `src/`.

**A1 — lint.** Get the list of files this PR changed that can be linted:

```bash
git diff --name-only upstream/main HEAD | grep -E '\.xojo_(code|window)$'
```

Then ask Claude: *"run lint_project_file on each of these"* and paste the list.
Only `.xojo_code` and `.xojo_window` are lintable; `.xojo_project` and `.md` are not.

**A2 — analyze.** Ask Claude: *"run analyze_project"*. Full project scope, not
`item`. Report warnings as well as errors.

**A3 — build.** Ask Claude: *"run build_project"* with **no** `build_type`.
Note which target it picks and where it writes.

**A4 — is the binary a binary?** Against the path A3 reported:

```bash
file "<build folder>/XMCP"          # macOS: must say Mach-O
```
```cmd
dir "<build folder>\XMCP.exe"       :: Windows: millions of bytes, not thousands
```

**A5 — does it start?** and **A6 — real IDE round-trip** in one command:

```bash
python3 probe-handshake.py "<build folder>/XMCP" --call get_project_info
```
```cmd
python probe-handshake.py "<build folder>\XMCP.exe" --call get_project_info
```

Exit 0 means the binary started and returned `serverInfo`. With `--call` it also
makes a real `get_project_info` round-trip to the live IDE, which is A6.

Do **not** use a bare `printf ... | XMCP` pipeline: the server does not exit when
stdin closes, so it hangs and leaves a stray process. That was in an earlier draft
of this file and it is wrong. On Windows, run the `.exe` in place — it needs its
DLLs and `XMCP Libs` folder as siblings.

**A6** — covered by the `--call` above. It exercises the socket resolution this
PR changes, so it is the check that actually matters on Windows.

> **Never deploy a themed PR build over `/Applications/XMCP`.** Every themed branch
> is cut from `upstream/main`, so each is a deliberate *subset* of what you run day
> to day. Measured 2026-09-17: installed = 1.11.0.144 with 34 tools; PR 1's build =
> 1.10.1 with 31, losing `describe_item`, `set_declaration` and `delete_project_item`
> and gaining nothing. Test the built binary with `probe-handshake.py --call`
> instead; if a PR truly needs an installed server, deploy to `/Applications/XMCP-test`
> with its own MCP entry.

**A7 — signature, macOS only.** The path is the **deploy target**, e.g.
`/Applications/XMCP` — not the build output.

```bash
codesign --force --sign - /Applications/XMCP && codesign -v /Applications/XMCP && echo OK
```

Only needed when the thing you signed is a *bundle*. Check which you have:

```bash
codesign -dv <path> 2>&1 | grep Format
```

`Format=bundle ...` means the signature seals the whole folder, so copying
`usage-guide.md` in afterwards breaks it and macOS kills the binary on launch with
`Killed: 9` and no output. `Format=Mach-O thin ...` means the signature is embedded
in the executable and covers only that file — copying files beside it is harmless,
and A7 does not apply.

**A8 — no cross-theme leakage.**

```bash
git diff upstream/main HEAD | grep -E 'ReplyKind|MergeReply|DrainPending|XojoKit|ProjectSource|DescribeItem|SetDeclaration'
```

No output is a pass.

**A9 — read the diff.** `git diff upstream/main HEAD`, hunk by hunk, deliberately.
A person or a Claude session, but not skimmed.

**Order matters.** A3 → A4 → A5 before anything else: if the binary is not a
binary, every later result is meaningless.

**Why A1/A8/A9 are per-platform even though they only read files.** `.gitattributes`
sets `* text=auto`, so the Windows working tree has **CRLF** where macOS has LF. You
are linting and reading a different byte stream there, which is precisely where the
`#tag` scanning and constant-escaping failures differ.

---

## Precondition — the IDE does not know git exists

Run **`revert_project` after any git operation that changes files**: `switch`,
`checkout`, `rebase`, `reset --hard`, `merge`, `stash`. The Xojo IDE holds the
project it last loaded; git rewriting the working tree underneath it changes
nothing in the IDE's memory.

Skipping this does not produce an error. It produces a **clean pass against the
wrong code** — `analyze_project` reports no errors, `build_project` builds, and
every result describes a branch you are no longer on. It is the same failure shape
as building one target and generalising from it.

Caught 2026-09-17: a rebase checked out `theme/ide-connection` while the IDE still
held `theme/connect-cleanup`. Nothing had been measured in that window, but the
next `analyze_project` would have been meaningless and would have looked fine.

Cheap confirmation that the IDE matches disk, using something only the current
branch has:

```
describe_item <Class>.<MemberOnlyThisBranchHas>   # reads disk
analyze_project                                    # reads the IDE
```

`get_project_info` is not sufficient — it reports the project *path*, which does
not change when git rewrites the files under it.

---

## Gate A — every PR, both platforms

| # | Check | mac | win |
|---|-------|-----|-----|
| A1 | `lint_project_file` clean on every edited `.xojo_code` / `.xojo_window` | ✅ |  ✅ |
| A2 | `analyze_project` (full project scope) — no errors, no new warnings | ✅ |  ✅ |
| A3 | `build_project` succeeds for **the target you ship**. On macOS pass `build_type: 24` or `16`; omitting it resolves to Universal, which the Xojo bug always corrupts, so A3-with-no-target cannot pass on macOS and measures Xojo rather than the PR. On Windows, omit it | ✅ |  ✅ |
| A4 | **Built file is actually an executable** — `file` reports Mach-O / PE32+, not text. **macOS Universal only**: a `CopyFilesBuildStep` overwrites the binary with `usage-guide.md` and still reports success. macOS 64 bit and ARM 64 are both correct. Check `file` on the target you actually ship | ✅ |  ✅ |
| A5 | Binary starts — `probe-handshake.py` returns `serverInfo`. (Do not pipe into it by hand; it does not exit on stdin EOF) | ✅ |  ✅ |
| A6 | `get_project_info` round-trips to the live IDE through the built binary (`--call` on the probe) | ✅ |  ✅ |
| A7 | macOS only, and **only when deploying to a bundle-shaped folder** such as `/Applications/XMCP`: re-sign after copying anything in, then `codesign -v` exits 0. N/A for a single-architecture build, whose signature is embedded in the Mach-O and seals only that file | ⬚ |  ⬚ |
| A8 | Diff contains nothing from a later theme (grep the diff for the other PRs' symbols) | ✅ |  ✅ |
| A9 | Upstream's version of every file we did not deliberately change is intact — `git diff upstream/main` reviewed hunk by hunk | ☐ |  ⬚ |

## PR 1 — Platform + Windows IPC socket

| # | Check | mac | win |
|---|-------|-----|-----|
| 1.1 | IDE open: socket found, tools answer | ✅ | ✅ |
| 1.2 | IDE closed: error names **every** path tried, no hang | ✅ | ✅ |
| 1.3 | Windows: resolved path is under `%LOCALAPPDATA%\Temp`, and XMCP runs as the same user as the IDE | ✅ | ✅ |
| 1.4 | `XOJO_IPCPATH=Xojo2026r1` with a second IDE — each session reaches its own IDE | ✅ | ✅ |
| 1.5 | `XOJO_IPCPATH=/some/path` (invalid per Xojo docs) is ignored, falls back to `XojoIDE` — **behaviour change from upstream on macOS**, confirm it breaks nobody | ✅ | ✅ |
| 1.6 | A long build does not stall: wrong candidates rule out in ~1.5 s each, not the full 120 s | ✅ | ✅ |
| 1.7 | `get_system_log` present on macOS, absent on Windows; `--help` tool count differs by exactly one | ✅ | ✅ |
| 1.8 | `get_debug_log` reads `/tmp/xmcp_debug.log` on macOS, `%TEMP%\xmcp_debug.log` on Windows; missing file returns a message, not a crash | ✅ | ✅ |

## PR 2 — IDE connection handling

| # | Check | mac | win |
|---|-------|-----|-----|
| 2.1 | A timed-out request does not SIGPIPE the next one; socket held, not closed | ☐ | ☐ |
| 2.2 | Split reply merged: a script that prints **and** raises a compiler warning reports both | ☐ | ☐ |
| 2.3 | `buildError` + `Print` sentinel arriving together resolve to the error | ☐ | ☐ |
| 2.4 | Warnings-only reply is treated as success, not failure | ☐ | ☐ |
| 2.5 | A failing build reports the **compile error**, not a 30 s IPC timeout | ☐ | ☐ |
| 2.6 | Script error line numbers match what the IDE shows (off-by-one boilerplate) | ☐ | ☐ |

## PR 3 — XojoKit parser

| # | Check | mac | win |
|---|-------|-----|-----|
| 3.1 | Constant `Default = "Hello, World"` parses whole — not truncated at the comma | ☐ | ☐ |
| 3.2 | `Sub Foo(msg As String = "Private eye")` keeps its default intact | ☐ | ☐ |
| 3.3 | Unterminated block sets `mLastError`; `ParseProject` does not return a silently truncated tree | ☐ | ☐ |
| 3.4 | `#tag EndEvents` does not terminate an inner event (prefix collision) | ☐ | ☐ |
| 3.5 | Every `#tag` comparison passes `ComparisonOptions.CaseSensitive` — `#Tag Instance` must not match | ☐ | ☐ |
| 3.6 | Enum value, constant platform override, parameter and view property are each reachable by NodeId (`AddChild` regression) | ☐ | ☐ |
| 3.7 | Deleted control disappears from `describe_item` and its old NodeId stops resolving | ☐ | ☐ |
| 3.8 | Round-trip a file with CRLF line endings — bytes unchanged where untouched | ☐ | ☐ |

## PR 4 — Item inspection and editing tools

| # | Check | mac | win |
|---|-------|-----|-----|
| 4.1 | `describe_item` on an external item (`.xojo_xml_code`) finds the file via the project folder, not the cwd | ☐ | ☐ |
| 4.2 | Anything `describe_item` prints by name is findable by that name (methods, events, properties, computed, constants, enums, notes, controls) | ☐ | ☐ |
| 4.3 | `set_declaration` on a busy IDE surfaces the real cause, not "not a method or property" | ☐ | ☐ |
| 4.4 | `delete_project_item` removes a member; count verified before **and** after save | ☐ | ☐ |
| 4.5 | Windows: no caret-editing path runs — `DeleteSelection` is macOS-only and must not corrupt the file | n/a | ☐ |
| 4.6 | Partial delete fails honestly rather than escalating to file surgery | ☐ | ☐ |

## PR 5 — Write-path integrity

| # | Check | mac | win |
|---|-------|-----|-----|
| 5.1 | A value that is multi-line **and** ends in a newline **and** contains a `"` round-trips byte-exact through `constant_value` | ☐ | ☐ |
| 5.2 | Same through `set_code`, `set_selected_text`, `set_item_description` | ☐ | ☐ |
| 5.3 | No spurious trailing blank line appended | ☐ | ☐ |
| 5.4 | LF content stays LF on a Windows-hosted IDE — no silent CRLF rewrite | n/a | ☐ |
| 5.5 | Verification compares against the **original** input, never a re-derived value (a tool's own check has validated a bug here before) | ☐ | ☐ |
| 5.6 | `constant_value` read of an unresolvable name fails instead of reporting success | ☐ | ☐ |

## PR 6 — Run / build / stop tooling

| # | Check | mac | win |
|---|-------|-----|-----|
| 6.1 | `build_project` with no `build_type` uses the IDE's configured Build Settings | ☐ | ☐ |
| 6.2 | A project with only one non-Universal target enabled still builds | ☐ | ☐ |
| 6.3 | A compile error is reported as a compile error, not blamed on the target | ☐ | ☐ |
| 6.4 | `stop_project` kills only the debug build — an unrelated process whose path contains the folder name survives | ☐ | ☐ |
| 6.5 | Windows: 8.3 short-path debug build is still matched | n/a | ☐ |
| 6.6 | `run_project` on a failing build reports the failure, not a 30 s timeout | ☐ | ☐ |

## PR 7 — Documentation

| # | Check | mac | win |
|---|-------|-----|-----|
| 7.1 | Tool counts in README / CLAUDE.md / `--help` agree with what registers at runtime | ☐ | ☐ |
| 7.2 | Every documented limitation still reproduces; none silently fixed | ☐ | ☐ |
| 7.3 | `usage-guide.md` next to the binary is served as an MCP resource | ☐ | ☐ |
| 7.4 | Build Automation: whatever is agreed, a fresh clone builds a **running** binary by the documented steps | ☐ | ☐ |

See [[xmcp-ide-script-gotchas]] for measured behaviours that contradict Xojo's docs.

---

## PR 1 status — as of 2026-09-17

Verified on macOS with Xojo **2026r2.1** (and earlier under 2025r3.1). Branch
`theme/windows-platform`, 3 commits, pushed to the fork. **Not opened as a PR.**

**Blocking:**

- **Every Windows box is unrun.** That machine last had build 1.3.0.66 and has not
  seen this branch. 1.3, 1.5 and 1.6 are the entire point of the PR and can only
  be answered there.
- **A9 not done as a formal pass.** The diff was constructed deliberately rather
  than merged, but nobody has read `git diff upstream/main` hunk by hunk.

**Resolved 2026-09-17 — A4.** An earlier entry failed A4 and blamed upstream's
`Build Automation`. Wrong: the fault is confined to the **macOS Universal** target.
Both single-architecture targets are correct: macOS 64 bit (6,554,464 B x86_64)
and ARM 64 (5,313,521 B arm64), each with `usage-guide.md` and `examples/` beside
the binary. Universal alone fails. A5 and A6 re-verified
against that binary — handshake returns XMCP 1.10.1, `get_project_info` round-trips.
Practical rule: `build_type` omitted resolves to Universal, so **check `file` on
whichever target you ship**, and prefer ARM 64 on this machine until the Universal
issue is understood.

**Note on 1.5:** `XOJO_IPCPATH` handling is a deliberate behaviour change on macOS.
Upstream accepted a value containing `/` as an absolute path; we ignore anything
outside `[A-Za-z0-9_]`. Xojo's docs back us (2026r2.1, issue 68115), but an existing
user relying on the old behaviour would silently stop connecting.

---

## PR 1 — VERIFIED ON BOTH PLATFORMS, 2026-09-17

Commit under test: **`e2053cf`**, `theme/windows-platform`, 4 commits off `upstream/main`.
Windows: fresh clone at `C:\XMCP-src`, Xojo 2026r2.1, built `Windows 64 bit`.
macOS: Xojo 2026r2.1, built `macOS ARM 64 bit`.

Everything passes. Findings that came out of the run, none of them blocking:

1. **Windows builds no `usage-guide.md`.** Upstream's `Build Automation` has copy
   steps only in the **Mac OS X** build step list; the Windows list is just
   `BuildProjectStep`. So the guide has always needed a manual copy there, as the
   README says. Not a regression, but it means the MCP resource is absent unless
   someone remembers.
2. **Failure time is multiplicative.** With no IDE listening, a tool call fails in
   ~11.5s: 5 attempts x 1.5s connect timeout + 4 x 1s retry pauses. Fine on this
   machine, which resolves exactly **one** candidate - but four writable candidates
   would make it ~34s. Argues for either trimming the chain to the two documented
   rungs, or not retrying a connect *timeout* as hard as a missing socket file.
   Worth raising with Ojvind rather than deciding quietly.
3. **`analyze_project` is not comparable across machines.** Same commit: macOS
   reported no warnings, Windows reported two (`ServerApplication.HandleInitialize`,
   `ListDocsets.Run` - both upstream code, both signature-mandated parameters).
   Per-install analyzer settings differ, so A2 means "no *new* warnings against that
   machine's baseline", never a number to compare.
4. **A9 is not per-platform after all.** `git diff` shows LF-normalised repository
   content, not the working tree, so the Windows read would be byte-identical to the
   macOS one. The CRLF justification holds for A1 (the linter reads the working tree)
   but not for A9. Marked n/a rather than run twice.
5. **The Windows install could not verify itself.** `C:\XMCP\XMCP.exe` is build
   1.3.0.66 with 25 tools and has neither `lint_project_file` nor `analyze_project`.
   The branch build was registered as a second MCP server (`xmcp-pr1`, 30 tools)
   rather than overwriting it, which also tested the new binary as a real server.
6. Cosmetic, out of PR 1's scope: `--help` still prints `"command": "/path/to/XMCP"`,
   a POSIX path, on Windows. Our `windows-support` branch prints the real executable
   path with escaped backslashes. Belongs in a later PR.

Key confirmations: the Universal build corruption is **macOS-only** - Windows
produced a correct 7,168,512-byte PE with the copy step absent entirely. The
`#If TargetWindows` branches compiled for the first time here and were clean.
`XOJO_IPCPATH` was tested both ways: a valid name reached a dedicated IDE, and
clearing it made that same IDE unreachable, so the first result was not a false pass.

---

## Addendum 2026-09-17 — `fd5d9ed`

PR 1 is now 5 commits / 7 files. The extra file is `src/Build Automation.xojo_code`:
the Windows `BuildStepList` gained `CopyUsageGuideWindows` and
`CopyExamplesFolderWindows`, named distinctly from the macOS pair.

Re-verified after the rebase and this fix, both platforms: lint clean on all four
changed sources, `analyze_project` clean, builds, binary handshakes and round-trips
`get_project_info`. Windows `--help` reports 30 tools with `get_system_log` absent
and the same single candidate path. Windows build output now contains
`usage-guide.md` and `examples\` with no manual step.

**New Gate A check earned by this:** after any change to build automation, delete the
artefacts from the build output *before* rebuilding. Otherwise a surviving file from
an earlier manual copy reads as a pass.

**Unrelated finding to pass to upstream:** the newly merged file tools default their
sandbox root to `/tmp` - a POSIX path - on every platform, so on Windows the default
`--file-root` cannot exist. Harmless while the tools are opt-in and off by default.
