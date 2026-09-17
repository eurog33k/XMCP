Paste this into the Claude Code session on the Windows machine, from the XMCP folder.

---

We're validating PR 1 of the XMCP upstream split before opening it. Branch
`theme/windows-platform` on remote `origin` (eurog33k/XMCP). Please:

0. This clone may not have the `upstream` remote — several steps below compare
   against `upstream/main`. Check and add it if missing:

   ```
   git remote -v
   git remote add upstream https://github.com/o3jvind/XMCP.git
   git fetch upstream
   ```

1. `git fetch origin && git switch theme/windows-platform`, confirm HEAD matches
   `origin/theme/windows-platform` and the tree is clean. Run every command from
   the repo root, not from `src\`.

2. Run `lint_project_file` on each file returned by:
   `git diff --name-only upstream/main HEAD | grep -E "\.xojo_(code|window)$"`
   Report each result. Note the working tree is CRLF here (`.gitattributes` has
   `* text=auto`), so this is not a repeat of the macOS run.

3. Run `analyze_project` at full project scope. Report errors AND warnings.

4. Run `build_project` with **no** `build_type` argument. Report which target it
   chose and the output path.

5. Check the built file is actually an executable, not text — on macOS a
   `CopyFilesBuildStep` replaces the binary with a copied .md on the Universal
   target (Xojo bug, already filed). Confirm Windows is unaffected:
   `file "<path>\XMCP.exe"` or check the size is millions of bytes, not thousands.

6. Start the built `XMCP.exe` and confirm it handshakes: pipe one
   `{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"probe","version":"1"}}}`
   line into it and look for a `serverInfo` line back. Keep the whole build folder
   together — the .exe needs its DLLs and `XMCP Libs` as siblings.

Then the Windows-specific ones, which are the whole point of this PR:

7. With the IDE open, confirm XMCP connects and which path it resolved. It should
   be under `%LOCALAPPDATA%\Temp`. Report the actual path.

8. Close the Xojo IDE and make a tool call. The error must name **every** path it
   tried, and must not hang.

9. Launch a second IDE with `XOJO_IPCPATH=XojoTest2` set, and set the same variable
   for the XMCP server entry. Confirm each session reaches its own IDE. Note the
   variable must be set for the process launching XMCP, not just the IDE.

10. Set `XOJO_IPCPATH=C:\some\path` (invalid — Xojo only accepts A-Za-z0-9_).
    Confirm it is ignored and falls back to `XojoIDE` rather than being used.

11. Timing: with the IDE closed, time a `build_project` call. Wrong candidates
    should be ruled out in about 1.5s each, not the full build timeout.

12. Confirm `get_system_log` is NOT registered on Windows, and that `--help`
    reports one fewer tool than macOS does.

13. Confirm `get_debug_log` reads `%TEMP%\xmcp_debug.log`, and returns a message
    rather than crashing when the file is absent.

Report results per numbered item, and say explicitly which ones you could not
complete and why. Do not fix anything — this is a verification pass.

---

## Reporting back

Results go to the `scratch/pr-workflow` branch, not into chat:

1. Fill in the **win** column of `PR-TEST-CHECKLIST.md` (✅ / ❌ / ⬚).
2. Append an entry to the top of `HANDOVER.md` naming the commit you tested,
   what passed, what failed, and anything surprising.
3. Commit and push:

   ```
   git add -f HANDOVER.md PR-TEST-CHECKLIST.md
   git commit -m "windows: gate A results for e2053cf"
   git push origin HEAD:scratch/pr-workflow
   ```

Do not push to `theme/windows-platform` — that is the PR branch and the macOS side
owns it. If something needs fixing, describe it in `HANDOVER.md` and leave it.
