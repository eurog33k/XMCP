# Handover log — macOS <-> Windows

Append-only. Newest entry at the top. Both sides write here; neither edits the
other's entries. Commit to `scratch/pr-workflow` and push — that is the channel.

Protocol:

```
git fetch origin && git checkout scratch/pr-workflow -- .   # get the latest
# ... do the work, edit PR-TEST-CHECKLIST.md and append here ...
git add -f HANDOVER.md PR-TEST-CHECKLIST.md
git commit -m "windows: gate A results for <commit>"
git push origin HEAD:scratch/pr-workflow
```

Always name the **commit under test**. "It works" against an unknown revision is
worth nothing.

---

## 2026-09-17 — Windows side — PR 1 verified, commit `e2053cf`

Fresh clone at `C:\XMCP-src`, Xojo 2026r2.1, target `Windows 64 bit`.
**Every check passes.** Gate A: A1-A6 and A8 ✅, A7 n/a (no codesign), A9 n/a
(see below). PR 1 checks 1.1-1.8 all ✅.

The results that could only come from here:

- **1.3** resolves to exactly **one** candidate, `C:\Users\dirkc\AppData\Local\Temp\XojoIDE`.
  `C:\tmp`, `C:\var\tmp` and `%USERPROFILE%` are all correctly rejected, so the
  four-rung chain costs nothing on this machine. That answers the open question from
  the previous entry: no need to trim it.
- **1.4** both halves. `XOJO_IPCPATH=XojoTest2` set for IDE *and* probe connected;
  clearing it made that same IDE unreachable. The negative half is what makes it a
  real result.
- **1.5** an invalid value (`C:\some\path`) was ignored and it fell back to
  `XojoIDE` and connected - the documented charset rule honoured.
- **A3/A4** the `#If TargetWindows` branches compiled for the first time, clean, and
  produced a genuine 7,168,512-byte PE. **The Universal corruption is macOS-only.**

Three things to decide, none blocking:

1. **Failure takes ~11.5s** with no IDE listening (5 attempts x 1.5s + 4 x 1s pauses).
   One candidate here, but the cost is candidates x timeout x retries - four would be
   ~34s. Trim the chain, or retry a connect timeout less aggressively than a missing
   socket file? I lean toward raising it with Ojvind rather than pre-empting him.
2. **Windows produces no `usage-guide.md`** - upstream's copy steps exist only in the
   Mac OS X build step list. Pre-existing, but the MCP resource is silently absent
   unless copied by hand.
3. `--help` prints a POSIX `/path/to/XMCP` example on Windows. Cosmetic, and our
   `windows-support` branch already fixes it; out of PR 1's scope.

Two corrections to this checklist itself:

- **A9 is not per-platform.** `git diff` shows LF-normalised repo content, so the
  Windows read is byte-identical to the macOS one. The CRLF argument holds for A1,
  which reads the working tree, but not for A9. Marked n/a.
- **A2 is not comparable between machines.** macOS reported no warnings; Windows
  reported two, both in upstream code and both signature-mandated. Per-install
  analyzer settings differ. A2 means "no new warnings against this machine's
  baseline".

Also worth recording: the installed `C:\XMCP\XMCP.exe` is build 1.3.0.66 with 25
tools and lacks `lint_project_file` and `analyze_project` - it could not perform its
own verification. The branch build was added as a second MCP server (`xmcp-pr1`,
30 tools) instead of replacing it, which kept `describe_item`, `set_declaration` and
`delete_project_item` available and tested the new binary as a real server.

## 2026-09-17 — macOS side — PR 1 ready for Windows verification

**Commit under test: `e2053cf`** on `theme/windows-platform` (4 commits off
`upstream/main`). Fetch that exact SHA; earlier commits have a different
connect-failure behaviour.

macOS Gate A: A1-A6, A8, A9 pass. A7 not applicable (single-architecture build
carries an embedded signature sealing only the executable, not a bundle folder).

What Windows needs to answer, in `WINDOWS-GATE-A-PROMPT.md`. The ones that matter
most, because they are the reason this PR exists and cannot be checked here:

- **1.3** which path the socket actually resolves to (expected under `%LOCALAPPDATA%\Temp`)
- **1.5** `XOJO_IPCPATH` with an invalid value is ignored, not used
- **1.6** wrong candidates rule out in ~1.5s each, not the full build timeout
- **A4** the Universal corruption is macOS-only; confirm Windows builds a real PE

Known traps, so you do not rediscover them:

- Do **not** deploy this build over the installed XMCP. It is cut from
  `upstream/main` and has 31 tools against your 34 - you would lose
  `describe_item`, `set_declaration` and `delete_project_item`. Use
  `probe-handshake.py` against the built binary instead.
- Do **not** pipe into the binary by hand to test the handshake. It does not exit
  on stdin EOF and will hang. Use the probe.
- The working tree is CRLF on Windows (`.gitattributes` has `* text=auto`), so the
  lint and diff checks are genuinely worth re-running there.
- This clone may lack the `upstream` remote; step 0 of the prompt adds it.

Open question for the Windows side, if you have an opinion: `Platform` probes four
candidate folders (from Xojo's shipped example client) where the documentation
describes two. Harmless, but if `%USERPROFILE%` turns out to be writable and slow
to rule out, say so and we will trim the chain.
