# Design
## Context
- E1 `skills/review/SKILL.md:9` — "Base = `$ARGUMENTS` or `main`." and `:10` "Dispatch the reviewer agent … with: base branch, the change path … and any focus the user gave." — where the rules step and the extra dispatch input go.
- E2 `skills/review/SKILL.md:1-5` — no `allowed-tools` today.
- E3 `tests/guards.test.sh` READONLY map — "The only calls any skill may pre-approve: its read-only scripts, plus each command it injects at load." — a new pre-approved call needs an entry here.
- E4 `agents/reviewer.md:13` — "`git diff <base>...HEAD` (base given in prompt; default `main`)." — the reviewer reads only what the prompt gives it.
- E5 `skills/map/scripts/check-map.test.sh:4-10` — `unset GIT_DIR …`, `mktemp -d`, `GIT_CEILING_DIRECTORIES` — harness pattern to copy.
- E6 `lefthook.yml:9,18`, `.github/workflows/ci.yml` tests step, `AGENTS.md:6`, `README.md:109` — where each test suite is listed; `README.md:92-107` Scripts table.
- E7 `git show <ref>:<path>` reads a blob from a commit without touching the tree; `git diff -z --name-only <merge-base>` lists committed and uncommitted changes from the root; `git ls-files -z --others --exclude-standard --full-name` lists untracked files root-relative.

## Goals / Non-Goals
**Goals:**
- One read-only script call gives the reviewer the base branch's rules for the files in the diff.

**Non-Goals:**
- Path arguments or paths on stdin — reopen when a caller needs rules for files outside the branch diff.
- A rules file format or schema — the reviewer reads plain text.
- `CLAUDE.md` or `AGENTS.md` from the base ref — they already reach the session as instructions.

## Decisions
- Default base `origin/main`. The skill fetches `origin/<base>` first and passes that ref to both the diff and the script, so a stale or local base branch the session can commit to does not decide the rules; an `origin/` prefix in its argument (pr-ready passes `origin/main`) is stripped first. No `origin` remote → the local `<base>`.
- The script finds the changed paths itself (E7), so the skill calls one command with no pipe and the call can be pre-approved (E2, E3); git prints only root-relative paths, so no path check is needed.
- The merge base is computed on its own line: a failure inside the process substitution would not stop the script.
- Standalone script, not `common.sh`: it needs no `rg`, slug or issue checks, and must not `cd` (paths are root-relative already).

## Risks / Trade-offs
- A repository whose default branch is not `main` gets an unknown-ref exit 1 until the base is passed; the skill passes it from `$ARGUMENTS`.

## Open Questions
