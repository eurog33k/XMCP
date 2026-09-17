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
