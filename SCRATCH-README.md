# scratch/pr-workflow

Working files for splitting `windows-support` into themed upstream PRs.
**Never merge this branch, and never open a PR from it.** It carries no source
code — only the process documents, which are deliberately kept out of every PR
branch so they cannot land in a diff sent to o3jvind.

| File | What it is |
|---|---|
| `UPSTREAM-PR-PLAN.md` | The seven-PR split, the verified review findings, open decisions |
| `PR-TEST-CHECKLIST.md` | Gate A + per-PR tests, per platform, with how to run each |
| `WINDOWS-GATE-A-PROMPT.md` | Paste-ready brief for the Claude Code session on Windows |
| `probe-handshake.py` | Proves a built binary starts and answers (A4/A5/A6), macOS and Windows |

On the machine you are testing from:

```
git fetch origin
git switch theme/windows-platform          # the code under test
git checkout scratch/pr-workflow -- .      # drop the working files alongside it
```

The second command copies these files into the working tree without changing
branches. They are listed in `.git/info/exclude` on the Mac; do the same on any
other clone so they never appear in `git status` on a PR branch.
