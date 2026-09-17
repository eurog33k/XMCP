# Upstream PR plan — splitting `windows-support` into theme-based PRs

Working document. Tick boxes as we go. Nothing here is committed to a PR branch;
see "Housekeeping" at the end for whether this file should be tracked.

---

## 1. Where things stand

- **PR [#6](https://github.com/o3jvind/XMCP/pull/6)** — `eurog33k:windows-support` → `o3jvind:main`,
  opened 2026-09-15, **60 commits**, OPEN, MERGEABLE, no review decision recorded.
- We have **READ** permission on `o3jvind/XMCP`; a direct push to upstream was never possible.
  PR is the only route.
- Øjvind replied 2026-09-16 12:24 asking for fixes before merge, and offered to
  **take it in smaller chunks by theme** — which is what this plan does.
- Local `windows-support` is **1 commit ahead of `origin`** (`df88ae4` "Stamp build 144").
  Pushing updates PR #6 in place.

### Diff shape against `upstream/main` (1266ee6)

| | count | risk |
|---|---|---|
| Files **added** by us | 45 | none — upstream has no version to conflict with |
| Files **modified** by us | 31 | **this is the entire reconciliation surface** |
| Files deleted | 0 | — |

Every defect in the review lives in the 31 modified files. The 45 new files
(XojoKit, Platform, new tools) are additive.

---

## 2. The diagnosis, verified

Øjvind's theory was that the merge picked up our fork's older versions of
functions he had since fixed. **Verified, with one correction to the mechanism:**

- `upstream/main` has `Continue`; we have `Exit`. Confirmed by `git show`.
- But `ffeb6cd` — our commit *before* the merge — **already had `Exit`**.

So it is not a bad merge resolution. Our fork rewrote these functions wholesale
long ago, upstream fixed the same functions independently, and the merge at
`e3bbe47` simply never reconciled the logic. Same practical outcome, but it means
**re-running the merge would not help**; each site needs a decision.

### Consequence for strategy

The regressions **do not need their own PRs**. Upstream is already correct on
every one of them. They need to *not be present* in the PRs we send.

So there are two tracks:

- **Track A — reconciliation** (local, no PR): restore upstream's version at each
  regression site on our integration branch.
- **Track B — themed PRs**: carve our genuine improvements out, each branched
  fresh from `upstream/main`.

---

## 3. Verification status of the review

Checked against the working tree before planning. `file:line` is ours.

### Confirmed — server stability

- [ ] **`src/MCPKit/ServerApplication.xojo_code:64`** — `Exit` in the missing-`id`
      branch ends `Run()` and kills the process. Upstream: `Continue`.
- [ ] **`src/MCPKit.xojo_code:10`** — `If(id.Type = Variant.TypeNil, Nil, id)`.
      Upstream replaced this with an `If id = Nil Then` block and a comment
      recording *why*: "Calling `.Type` on a Nil Variant raises NilObjectException
      in Xojo, which terminates the stdio MCP server before the client can
      discover tools." **Note:** my own reading was that Variant is a value type
      and `.Type` on Nil is safe. Upstream's comment says it was observed to
      crash. Trust the observation, not the reasoning — but confirm with a
      throwaway test before changing anything else here.
- [ ] **`src/MCPKit/ServerApplication.xojo_code:32`** — stdin loop uses `Input`.
      Upstream uses `StdIn.ReadAll` chunk accumulation. Partially mitigated on our
      side (there *is* an `EndOfFile` check and a 10 ms sleep, so the 1.4.1 CPU
      spin may not reproduce), but the **partial-line risk on a large payload is
      real and unmitigated** — `Input` can return a fragment of a big `set_code`
      body. Upstream accumulates across polls precisely for this.

### Confirmed — write-path corruption

- [ ] **`src/Tools/ConstantValue.xojo_code:58`** and
      **`src/Tools/GetItemDescription.xojo_code:47`** — inline the value with
      quote-escaping only; `BuildStringVariableScript` is not called at all
      (0 references in both files; `SetCode` and `SetSelectedText` still use it).
      Any multi-line value puts a raw newline inside a quoted IDE-script literal.
- [ ] **`src/MCPKit/Tool.xojo_code:187`** — appends `+ EndOfLine` after *every*
      segment and trims only when the value does not already end in a line break,
      so a value ending in `\n` gains a stray blank line. Also normalises to the
      IDE's native `EndOfLine` instead of preserving the original bytes — on a
      Windows-hosted IDE that rewrites LF content to CRLF on every write.
      CLAUDE.md's dev notes describe the correct design: split CRLF/CR/LF
      individually and re-insert the exact separator as `Chr(13)`/`Chr(10)`
      outside the literals.

### Confirmed — XojoKit parser

- [ ] **`XKParser.xojo_code:31`** `ExtractTagAttribute` — splits on the first comma
      with no quote awareness. `Default = "Hello, World"` yields `"Hello`.
      Feeds `set_declaration`, so a write-back can persist the truncation.
- [ ] **`XKParser.xojo_code:1275-1281`** — `ReplaceAll("Private ", "")` etc. applied
      to the whole signature line, not just the part before the parameter list.
- [ ] **`XKParser.xojo_code:584`** — `BeginsWith("#tag EndEvent")` is a true prefix
      of `#tag EndEvents` (handled separately at :467). Also: CLAUDE.md warns
      `BeginsWith` is **case-insensitive by default** in this Xojo version and
      must be passed `ComparisonOptions.CaseSensitive` for `#tag` literals —
      worth auditing every `#tag` comparison in the file while we are here.
- [ ] **`XKParser.xojo_code`** — only 3 `mLastError` assignments, none for an
      unterminated block. A missing `End Sub` / `#tag EndMethod` silently
      consumes the rest of the file and `ParseProject` returns a non-Nil,
      truncated tree.

### Confirmed — XojoKit node tree

- [ ] **`AddChild` never called** in `XKEnum.AddValue`, `XKConstant.AddInstance`,
      `XKMethod.AddParameter`, `XKEvent.AddParameter`, and `AddViewProperty` in
      all three of `XKCodeContainer` / `XKWindow` / `XKWebPage`. Every sibling
      (`AddMethod`, `AddProperty`, `AddConstant`) does call it. These nodes get
      NodeIds from `XKJSONVisitor` but are unreachable via `FindNode`.
- [ ] **`XKWindow.ClearControls` / `XKWebPage.ClearControls`** — `mControls.RemoveAll`
      only; `mChildren` keeps the deleted controls.

### Confirmed — platform / path correctness

- [ ] **`ProjectSource.xojo_code:592` vs `:531`** — reads with
      `ReplaceLineEndings(Chr(10)).Split(Chr(10))`, writes with
      `String.FromArray(keep, EndOfLine)`. On Windows a one-member deletion
      rewrites the whole file LF→CRLF.
- [ ] **`Tools/DescribeItem.xojo_code:165`** — `New FolderItem(item.RelativePath,
      PathModes.Native)` resolves against XMCP's working directory, not the
      project folder. `ProjectSource.ItemFile` already exists for this.
- [ ] **`Tools/SetDeclaration.xojo_code:105`** — `Call App.IDE.SendAndReceive(...)`
      discards the result, so a real IDE-busy failure surfaces as a generic
      "not a method or property".
- [ ] **`Tools/StopProject.xojo_code:122`** — `underProject = lower.IndexOf(nameNeedle) >= 0`
      applies on all platforms, not just the Windows 8.3 short-path case it was
      added for. An unrelated process whose path contains the folder name matches.

### Confirmed — behaviour changes to discuss, not just fix

- [ ] **`Tools/BuildProject.xojo_code:49`** — omitting `build_type` resolves to a
      hardcoded 9/19/17 per OS instead of the IDE's configured Build Settings.
      **This contradicts our own `CLAUDE.md`**, which documents both that
      `build_project` calls the no-argument `DoCommand "BuildApp"` form and that
      leaving `build_type` off "resolves to the right macOS target on its own".
- [ ] **`src/Build Automation.xojo_code`** — now 17 lines with **no** `CopyFiles`
      steps for `usage-guide.md` / `examples/` at all. Removed on every platform.
      Øjvind explicitly wants to talk this through.
      **Corrected 2026-09-17.** An earlier note here claimed these steps destroy the
      build output outright. That was wrong, and overstated from a single target.
      Measured properly, the fault is **specific to the macOS Universal target**:

      | Target | Executable | Siblings produced |
      |---|---|---|
      | macOS 64 bit | 6,554,464 B Mach-O x86_64 | `XMCP Libs`, `examples`, `usage-guide.md` |
      | macOS ARM 64 bit | 5,313,521 B Mach-O arm64 | `XMCP Libs`, `examples`, `usage-guide.md` |
      | macOS Universal | **34,544 B of text** | `XMCP Libs`, `_CodeSignature` only |

      Both single-architecture targets are correct and identical. Universal is the
      sole failure, and it is also the only target that emits `_CodeSignature` while
      neither copy step lands its file - so Universal appears to treat the output as
      a bundle-like structure and the copy destination collapses onto the executable
      path. Worth filing with Xojo: reproducible on 2025r3.1 and 2026r2.1, silent
      (the build reports success and `codesign -v` passes on the wreckage).

      Isolated by running the *same* `build_project` call against each target, so
      neither the invocation nor a manual-vs-scripted difference explains it.
      Reproduces on 2025r3.1 and 2026r2.1. Note `build_project` with `build_type`
      omitted resolves to Universal, which is why every scripted build looked broken
      and every manual ARM build looked fine.

      **This weakens the case for removing the steps.** They work on the target
      most people build. The honest position for Øjvind is a Universal-target bug
      worth reporting to Xojo, not "the automation is broken, we deleted it".

---

## 4. The PR sequence

Each PR: branch fresh from `upstream/main`, cherry-pick or re-apply only that
theme, stamp the build, compile, smoke-test, open. Do not branch from
`windows-support` — that is what carries the regressions.

Naming: `theme/<slug>`.

### PR 1 — Platform module + Windows IPC socket  `theme/windows-platform`
The foundation; everything Windows depends on it.
- [ ] New: `src/Platform.xojo_code` (+ any new Windows-only helpers)
- [ ] Modified: `src/IDECommunicator.xojo_code` (candidate paths via `Platform.IPCSocketPaths`),
      `src/App.xojo_code` (tool registration / `kToolCount`, docs path)
- [ ] Carry the README "transport underneath" section — the TCP-port-hashed-from-path
      detail is the part a reviewer needs to accept the design
- [ ] Explicitly keep upstream's `ServerApplication` and `MCPKit.xojo_code` untouched
- [ ] Verify: `get_project_info` round-trip on macOS; note Windows result separately

### PR 2 — IDE connection handling  `theme/ide-connection`
- [ ] Modified: `src/IDECommunicator.xojo_code` — hold the socket open past a
      timeout instead of closing into a SIGPIPE; merge split replies; single
      reply classifier (`ffeb6cd`)
- [ ] Depends on PR 1 (same file). Rebase after PR 1 lands.
- [ ] This is the fix Øjvind called out as needed — lead with it in the description

### PR 3 — XojoKit parser  `theme/xojokit`
Additive: ~40 new files, no upstream version to conflict with.
- [ ] New: `src/XojoKit/**`, `src/ProjectSource.xojo_code`
- [ ] **Fix before sending, not after:** `ExtractTagAttribute` quote awareness;
      keyword stripping scoped to the pre-parameter portion; `mLastError` on
      unterminated blocks; `#tag EndEvent` prefix + `CaseSensitive` audit;
      `AddChild` in the five `Add*` methods; `ClearControls` clearing `mChildren`;
      `ProjectSource` write-back preserving the original line endings
- [ ] Add a focused test project under `src/examples/` exercising: a `Default`
      containing a comma, a parameter default containing `"Private "`, an
      unterminated block, an enum value and a view property addressed by NodeId

### PR 4 — Item inspection and editing tools  `theme/item-tools`
- [ ] New: `src/Tools/DescribeItem.xojo_code`, `SetDeclaration.xojo_code`,
      `DeleteProjectItem.xojo_code`
- [ ] Depends on PR 3
- [ ] Fix first: `DescribeItem` external-file path via `ProjectSource.ItemFile`;
      `SetDeclaration` surfacing the real `SendAndReceive` failure
- [ ] Carry the `DeleteSelection`-is-macOS-only reasoning in the commit message —
      it is the non-obvious part and reviewers will ask

### PR 5 — Write-path integrity  `theme/write-path`
Small and self-contained. **Mostly reverting to upstream**, plus the genuine
improvements we made on top.
- [ ] `MCPKit/Tool.xojo_code` — start from upstream's `BuildStringVariableScript`;
      re-apply only `HasTrailingEndOfLine` / `SplitLines` if they are a real
      improvement over it (they may be — decide by diffing, not by assuming)
- [ ] `ConstantValue` and `GetItemDescription` back onto `BuildStringVariableScript`
- [ ] Keep `ConstantValue`'s honest-failure work (`ReadConstant` / `Unresolved`) —
      that is ours and worth landing
- [ ] Verify with a value that is multi-line **and** ends in a newline **and**
      contains a double quote

### PR 6 — Run / build / stop tooling  `theme/process-tools`
- [ ] `Tools/StopProject.xojo_code` — gate the substring fallback to Windows
- [ ] `Tools/BuildProject.xojo_code` — restore the no-argument `DoCommand "BuildApp"`
      default, or argue for the change; either way make code and CLAUDE.md agree
- [ ] `Tools/RunProject.xojo_code` and the remaining small tool diffs

### PR 7 — Documentation  `theme/docs`
- [ ] `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `src/usage-guide.md`
- [ ] Land last so it describes what actually merged
- [ ] **Separate discussion thread** (PR comment, not a commit) for the
      `Build Automation` CopyFiles removal

---

## 5. Working agreements

- [ ] **Stamp per PR.** `NonRelease` = `git rev-list --count HEAD`, then
      `revert_project`, then build. Two binaries reporting the same version has
      already caused real confusion here.
- [ ] **Compile every PR** via `analyze_project` before opening. There is no test
      suite; the compiler and manual MCP round-trips are the whole safety net.
- [ ] **Deploy = build → copy → `codesign --force --sign -` → restart client.**
      Skipping the re-sign gives `Killed: 9` with no output.
- [ ] **Do not push `windows-support` again** until we decide PR #6's fate.
- [ ] Reply to Øjvind before opening PR 1, confirming the split and flagging the
      two items where we think his review needs a second look (the `Input` CPU
      spin, which our code partly guards, and `Build Automation`).

## 6. Open decisions — need your call

- [ ] **PR #6: close, convert to draft, or leave open** as the umbrella while the
      themed PRs land? Converting to draft with a comment pointing at the split
      seems least disruptive, but it is your call.
- [ ] **Who fixes the regressions** — us, in the themed PRs before sending (the
      plan above assumes this), or land features first and fix in follow-ups?
      Fixing first is slower but matches what he asked for.
- [ ] **This file** — track it in the repo (visible on the Windows machine, but
      shows up in PR diffs unless gitignored), or gitignore it like
      `docs/USING-XMCP.pdf`?
