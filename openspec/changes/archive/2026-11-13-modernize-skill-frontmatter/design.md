# Design
## Context
- E1 S1 https://code.claude.com/docs/en/skills — `${CLAUDE_SKILL_DIR}` "Directory containing SKILL.md"; `${CLAUDE_PLUGIN_ROOT}` "Plugin installation directory", plugin skills only; both expand in "Skill content + bash rules in allowed-tools"; example `allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/render.sh *)` with body `Run ${CLAUDE_SKILL_DIR}/scripts/render.sh <csv-file>` — "Both occurrences expand identically, allowing the allowed-tools rule to match the exact command". Fetched 2026-11-12, recorded in the audit input, not re-fetched here.
- E2 S1 dynamic injection — a line starting with !`cmd` runs before the skill is sent; "Non-zero exit code aborts entire skill invocation"; unmatched permission rule outside auto mode aborts; "To pre-approve unmatched commands, list them in allowed-tools"; runs in the session shell directory.
- E3 S1 — "< and > in the description and when_to_use fields" render as `&lt;`/`&gt;`; "use square brackets or argument-hint"; listing truncates, "put the key use case first". S2 — "Always write in third person".
- E4 `skills/ship/SKILL.md:14` — "`../plan/scripts/create-issue.sh <slug>` (path relative to this skill's base directory)".
- E5 `skills/execute/SKILL.md:12` — "`../plan/scripts/validate-change.sh <slug>`"; `:33` — "`../plan/scripts/verify-commits.sh <base> -- bash -c '<install deps> && <check>'` (path relative to this skill's base directory)"; `:34` — "`../plan/scripts/set-status.sh <slug> done` (path relative to this skill's base directory)".
- E6 `skills/investigate/SKILL.md:33` — "`../plan/scripts/read-issue.sh n` (path relative to this skill's base directory)".
- E7 `skills/issues/SKILL.md:9` — "Every step is `scripts/issue.sh` (under the base directory shown when the skill loads)"; `:20` — "`issue.sh list --ready [--type <t>] …` … without `--ready`, every open issue"; `:21` — "`issue.sh milestone list`".
- E8 `skills/plan/SKILL.md:9` — "a script in this skill's `scripts/` folder (under the base directory shown when the skill loads)"; `:11` `scripts/read-issue.sh <n|url>`; `:12` `scripts/new-change.sh <slug>`; `:14` — "the absolute validate command (`<base directory>/scripts/validate-change.sh <slug>`)"; `:15` `scripts/validate-change.sh <slug>`; `:16` `scripts/create-issue.sh <slug>`.
- E9 `skills/map/SKILL.md:10` — "Repo root = `$ARGUMENTS` or cwd. Re-check `git status --short --branch`."; `:29` `scripts/check-map.sh`; `:32` — "Run `scripts/check-map.sh` (in this skill's base directory)".
- E10 `skills/pr-ready/SKILL.md:9` — "Must be on a non-`main` branch with commits ahead of base."; `:19` `../plan/scripts/verify-commits.sh` "(path relative to this skill's base directory …)"; `:22` `scripts/fold.sh <slug>` "(in this skill's base directory)"; `:33` `scripts/open-pr.sh … --dry-run` "(in this skill's base directory)"; `:37` `scripts/merge-pr.sh <n> --dry-run` "(in this skill's base directory)".
- E11 `skills/execute/SKILL.md:10` — "Re-check cwd + `git status --short --branch` — right repo, right branch, clean tree or known state."
- E12 `skills/review/SKILL.md:9` — "Base = `$ARGUMENTS` or `main`. `git diff --stat <base>...HEAD`" — its first read depends on the argument.
- E13 `skills/plan/scripts/verify-commits.sh:2` — "Usage: verify-commits.sh <base> -- <check…>"; `:24` — "`if ! (cd "$wt" && "$@"); then`" — runs any command it is given.
- E14 `skills/issues/scripts/issue.sh:8` — "usage: issue.sh <operation> [--dry-run]"; `:120-135` `list)` only calls `gh issue list`, unknown option → `die`; `:139-140` `milestone list` "takes no argument"; `:136-168` `milestone create|close` write.
- E15 `skills/map/scripts/check-map.sh:2` — "Usage: check-map.sh [base-ref]   (default HEAD)"; `skills/plan/scripts/validate-change.sh:6` — "`slug="${1:?usage: validate-change.sh <slug>}"`"; `:13` runs `openspec.sh validate` only.
- E16 `tests/guards.test.sh:16` — "`! rg -q '^allowed-tools:' "$pr" || fail "pr-ready pre-approves tools"`"; `:93` — "`! rg -q '^allowed-tools:' <<<"$m" || fail "map pre-approves tools"`" — both fail once pr-ready and map get `allowed-tools`.
- E17 `tests/guards.test.sh:6` — "`fail() { echo "FAIL: $case: $*" >&2; exit 1; }`"; `:11` `has()` — the helpers new cases reuse.
- E18 `openspec/specs/workflow-guards/spec.md:4` — Purpose: "Guards the gated workflow applies to actions that leave the machine and to input it does not control"; `:9` — "no remote-writing command is pre-approved".
- E19 `openspec/specs/directory-map/spec.md:81-84` — "Directory list approved first … nothing is written before the user says yes".
- E20 `skills/plan/SKILL.md:3` — "Gate 1 of plan → execute → review. … (openspec/changes/<slug>/ …"; `skills/execute/SKILL.md:3` — "Gate 2 of plan → execute → review. … (openspec/changes/<slug>/)"; `skills/review/SKILL.md:3` — "Gate 3 of plan → execute → review."; `agents/planner.md:3` — "openspec/changes/<slug>/".
- E21 `skills/ship/SKILL.md:3` — "Fable only on your yes", "a change you would otherwise babysit"; `skills/docs/SKILL.md:3` — "(or future you)".
- E22 `skills/AGENTS.md:5` — "a `scripts/` folder that the skill runs by path from its base directory"; `:29` — "Skills run CLI steps through scripts (their own or `plan/scripts/`) … (`skills/plan/SKILL.md:9`, `skills/execute/SKILL.md:34`)".
- E23 `SECURITY.md:46` — "Bash rules match command prefixes. They are guardrails, not a boundary".
- E24 `.claude-plugin/plugin.json:3` — "`"version": "2.2.0"`"; history: every `feat` bumps minor (`97aac81` 2.0.1→2.1.0, `173ea1f` 2.1.1→2.2.0), `fix`/`docs` bump patch (`7f9f061` 2.0.0→2.0.1, `94be4dd` 2.1.0→2.1.1).
- E25 `.github/workflows/ci.yml:48` — "`npx -y @anthropic-ai/claude-code@2.1.306 plugin validate --strict .`".

## Goals / Non-Goals
**Goals:**
- Exact script paths in every SKILL.md (E4–E10), read-only calls pre-approved (E1), branch state injected in execute, map, pr-ready (E2, E9–E11), descriptions fixed (E3, E20, E21), each guarded.

**Non-Goals:**
- Injection in review (E12): its first read needs `$ARGUMENTS`, and substituting argument text into an injected shell line runs that text. Reopen when Claude Code offers argument-safe injection.
- Pre-approving `--dry-run` calls of `open-pr.sh`, `merge-pr.sh`, `create-issue.sh`, `issue.sh` writes: a `* --dry-run` pattern is safe only if every script honours a last-position flag, and the constraint keeps outward scripts out of `allowed-tools`. Reopen when dry-run prompts become friction.
- Pre-approving `claude plugin validate` in map: not a load-time read. Reopen on request.
- Rewriting imperative descriptions ("Write…", "Compare…") into third-person verbs: only "you"/"your" is second person. Reopen when the eval suite shows mis-triggering.
- Evals and hooks: changes `add-plugin-eval-suite`, `add-skill-guard-hooks`.

## Decisions
- Shared scripts use `${CLAUDE_SKILL_DIR}/../plan/scripts/…`, not `${CLAUDE_PLUGIN_ROOT}/skills/plan/scripts/…` — E1 documents `CLAUDE_PLUGIN_ROOT` for plugin skills only, so skills loaded from a checkout as plain skills would get an empty prefix; `CLAUDE_SKILL_DIR` exists in both layouts and the plugin cache keeps sibling skills together. One variable everywhere. The `..` stays inside an expanded absolute path, so the guard bans only a path that does not start with `${CLAUDE_SKILL_DIR}/`.
- Read-only set: `validate-change.sh *`, `read-issue.sh *` (plan, investigate, execute), `issue.sh list`, `issue.sh list *`, `issue.sh milestone list` (issues), `check-map.sh` (map) (E14, E15). `issue.sh list *` cannot approve a write: the op word is fixed at `list` and `list)` dies on unknown options (E14). Patterns are written exactly as the body's command so they match (E1).
- Not pre-approved: `create-issue.sh`, `new-change.sh`, `set-status.sh`, `fold.sh`, `open-pr.sh`, `merge-pr.sh`, `issue.sh` writes, and `verify-commits.sh` — the audit calls it read-only, but it runs whatever follows `--` (E13), so `verify-commits.sh *` would pre-approve `bash -c` anything.
- `allowed-tools` as a YAML list, one `Bash(…)` per line — patterns contain spaces; the guard reads the frontmatter block.
- Injection: one line `` !`git status --short --branch || true` `` plus `Bash(git status --short --branch)` in execute and pr-ready (E2, E10, E11). `|| true` because a non-zero exit aborts the skill (E2), and both are reached from a directory that is not a work tree: the root of a bare-repository worktree layout makes `git status` exit 128. Measured on 2.1.323 from a non-repo directory: with `|| true` the skill loaded and showed `fatal: not a git repository …`; without it the invocation aborted (0 turns). Step text tells Claude a `fatal:` line means move into the worktree first. Not in map: its repo root comes from `$ARGUMENTS`, and the injection runs in the session directory before the skill reads it (E2, E9). Lost: map keeps one `git status` tool call.
- Pre-approval is an exact allowlist per skill (read-only scripts plus each injected command), checked against every SKILL.md in any frontmatter form, instead of a denylist of outward script names: a denylist misses `git push`, `gh pr create` or a bare `Bash`.
- New capability `skill-loading`, not `workflow-guards` — E18 scopes that spec to consent and untrusted input; paths, injection and listing text are neither. Its remote-write rule already holds and stays unchanged; the hooks change can extend `skill-loading`.
- E16 lines change from "no `allowed-tools`" to "no outward script in `allowed-tools`", keeping their scenarios ("Push and PR open ask first", E19 "Directory list approved first") true without a spec delta.
- Version 2.3.0 — this lands `feat` commits (pre-approval, injection); history bumps minor for `feat` (E24).

## Risks / Trade-offs
- A Bash rule containing `${CLAUDE_SKILL_DIR}/../plan/…` may not match if Claude Code normalizes paths before matching; the call then prompts as today (no loss of safety).
- Pre-approval is prefix matching, a guardrail not a boundary (E23).
- `claude plugin validate --strict` at CI's 2.1.306 (E25) may reject frontmatter the installed 2.1.323 accepts; the check group catches it.
- After compaction the injected status is stale; execute step 2 keeps "re-check" for that case.
- `|| true` also hides a git failure inside a repository; the error text still shows in the skill, so the step that reads it sees it.

## Open Questions
- None left. Resolved by two `claude -p --permission-mode default --setting-sources ""` runs on Claude Code 2.1.323 against a throwaway plugin: a skill listing `Bash(${CLAUDE_SKILL_DIR}/../aa/scripts/hi.sh *)` ran `${CLAUDE_SKILL_DIR}/../aa/scripts/hi.sh approved` with no denial, and the same command from a skill without the entry was denied ("This command requires approval"). So `..` in a rule matches; shared paths stay `${CLAUDE_SKILL_DIR}/../plan/scripts/…`.
- Seen in the same runs: `` !`git status --short --branch` `` rendered in a skill without any `allowed-tools` entry too (Claude Code approves that read-only command on its own). The entry stays, because S1 documents an abort for unmatched injected commands and that auto-approval is not documented.
