# Design
## Context
- E1 `AGENTS.md:6` — "Tests: `bash skills/plan/scripts/scripts.test.sh`, … stubs on `PATH` for `openspec`, `npx` and `gh`, and `unset GIT_DIR …`"; `AGENTS.md:7` — "scripts use `set -euo pipefail`, `rg` (never grep) and quoted paths; shared checks live in `skills/plan/scripts/common.sh`" — style and test rules.
- E2 `skills/plan/scripts/common.sh:19` — "`write() { if [ -n "${dry:-}" ]; then printf '%q ' "$@"; echo; else "$@" >/dev/null; fi; }`"; `:21-27` — "`ensure_label <feat|bug|chore>: create the type:<kind> label when the repository lacks it.`"; `:3-7` — needs `rg`, `cd "$root"` — the dry-run, label and repo-root helpers to reuse.
- E3 `skills/plan/scripts/create-issue.sh:36` — "`args=(gh issue create --title "$title" --body-file "$body" --label "type:$kind" --assignee @me)`"; `:42-43` — URL parsed into `owner/repo#n` — tracking-issue creation stays there; the URL parse is the pattern to copy.
- E4 `skills/plan/scripts/read-issue.sh:7` — "`[[ "$arg" =~ ^#?[1-9][0-9]*$ || …`" then exit 2 before `gh`; `:14` — `gh issue view … parent,blockedBy,subIssues` — validation pattern; reading an issue is already covered.
- E5 `skills/plan/scripts/scripts.test.sh:30-42` — "gh: logs each call, answers from STUB_* env, keeps the last --body-file at $GH_LOG.body." — stub pattern for the new harness.
- E6 `lefthook.yml:9,18` and `.github/workflows/ci.yml:35-40` list each suite; `.github/workflows/ci.yml:33` — "`sudo apt-get install -y -qq ripgrep`" — where a new suite and a test tool get wired.
- E7 `gh issue create --help` (2.100.0) — "`--blocked-by numbers   Mark the new issue as blocked by these issue numbers or URLs`", "`-m, --milestone name   Add the issue to a milestone by name`", "`--type name   Set the issue type by name`".
- E8 `gh issue edit --help` — "`--add-blocked-by number`", "`--remove-blocked-by number`", "`-m, --milestone name`", "`--remove-milestone`", "`--add-label name`", "`--remove-label name`", "`--add-assignee login`", "`--remove-assignee login`" — every edit is one `gh issue edit`; no REST dependency API needed.
- E9 `gh issue close --help` — "`-r, --reason string   Reason for closing: {completed|not planned|duplicate}`", "`--duplicate-of string`"; `gh issue reopen --help` — only "`-c, --comment string`".
- E10 `gh milestone --help` — "`unknown command "milestone" for "gh"`"; `gh api --help:6` — "Placeholder values `{owner}`, `{repo}`, and `{branch}` in the endpoint", `:73` "`--paginate`" — milestones go through `gh api repos/{owner}/{repo}/milestones`.
- E11 Read-only run on this repo: `gh issue list --state all --search '-is:blocked' --json number --jq length` → `6`; adding `--label type:feat` → `4` — `--search` and `--label` filters combine.
- E12 `skills/standard/SKILL.md:35` — "Labels `type:bug|feat|chore` (issue types are org-only). Deps via `--blocked-by`. Ready queue: `gh issue list --search '-is:blocked is:open'`." — labels, not native types; the ready query.
- E13 `skills/AGENTS.md:7-24` Key files table, one row per skill; `skills/AGENTS.md:28` — "Skills run CLI steps through scripts …, never retyped commands".
- E14 `README.md:7` — "**15 skills**: … and 10 helpers (…, map)"; `README.md:32-48` Skill reference; `README.md:91-103` Scripts table; `README.md:105` Tests line.
- E15 `.claude-plugin/plugin.json:3` — "`"version": "2.1.1"`"; commit `97aac81` (add map skill) bumped 2.0.1 to 2.1.0 and edited `plugin.json`, `marketplace.json`, `README.md`; `.claude-plugin/marketplace.json:10` lists every skill.
- E16 `skills/map/scripts/check-map.sh:77-79` — only an existing nested `AGENTS.md` needs a root Map row; `skills/map/scripts/` has none — a two-file scripts folder needs none.
- E17 `openspec/specs/workflow-guards/spec.md:9` — "before it pushes, force-pushes, opens or edits a pull request, merges, or changes repository settings" — issue writes are outside the consent guard today.
- E18 `openspec/specs/issue-tracking/spec.md:4` — Purpose: "Reading a GitHub issue … and creating, labelling and recording the tracking issue" — the capability this extends.
- E19 `skills/plan/SKILL.md:3`, `skills/review/SKILL.md:3` — description says what it does, then "Does not … — use solo:…".
- E20 Run on this user-owned repository: GraphQL `repository.issueTypes` returns `Task`, `Bug`, `Feature`; `gh issue edit 12 --type Feature` exits 0 and the issue reads `issueType: Feature`; `gh issue list --type Feature --search '-is:blocked is:open'` returns it; `gh issue list --json` has `issueType` — issue types are not org-only, contrary to E12.

## Goals / Non-Goals
**Goals:**
- One script call per issue or milestone operation, validated before `gh`, `--dry-run` on every write, minimal output.

**Non-Goals:**
- Custom issue type names, and repositories without issue types — reopen when one is met; `gh` reports the missing type.
- Cross-repo refs, issue URLs, `-R` — reopen when a dependency or edit must reach another repository.
- Parent/sub-issues — reopen when a plan splits into sub-issues.
- Viewing an issue — `skills/plan/scripts/read-issue.sh` does it (E4).
- Closed-issue listing, milestone edit/reopen/delete, projects, close comments (comment, then close) — reopen when asked for.

## Decisions
- One `issue.sh <op>` with subcommands, one `issue.test.sh` — shared parsing, validation and `common.sh` source once; seven scripts would repeat all three (E2, E4).
- Type = the forge's issue type, exactly one, required on create: `feat`, `bug`, `chore` map to `Feature`, `Bug`, `Task` (E20). No label is read or written, so `ensure_label` is not used. The tracking issue (`create-issue.sh`) sets the issue type the same way, from the slug prefix. PRs keep `type:*` labels (`open-pr.sh`, `ensure_label`): a PR has no issue type.
- `gh` flags for blocked-by, milestone assignment, close reason; `gh api` only for milestone create/list/close, which `gh` lacks (E7–E10). Close by title matches the exact title in bash, never inside a jq expression.
- Output: `create` prints `owner/repo#n` (parsed like E3); other writes print nothing on success; `list` lines come from gh's `--jq`. The harness runs that jq through real `jq` on canned JSON so the format is tested, not stubbed; CI installs `jq` next to `rg` (E6).
- `close --reason not-planned` maps to gh's `not planned`; `--duplicate-of <m>` sets duplicate (E9).
- Consent: the skill runs the write the user named; a write it infers (closing, bulk edits) is shown with `--dry-run` and run on a yes. The workflow-guards contract is not widened (E17).
- Version 2.1.1 to 2.2.0, a new skill like map (E15). No `skills/issues/scripts/AGENTS.md` (E16).

## Risks / Trade-offs
- gh flag names drift → pinned to gh >= 2.100 in README, as merge-pr already is.
- A due date is sent as noon UTC: GitHub keeps only the day, read in Pacific time, so midnight UTC would land on the day before. Not checked against a live milestone.
- Default list limit 100 cuts a larger backlog silently → `list --limit <n>` raises it.

## Open Questions
- Extend `issue-tracking` (its Purpose, E18, then names only reading and the tracking issue) or create a new `issue-lifecycle` capability? Default here: extend.
- Should issue writes join the workflow-guards consent rule (dry run plus a yes every time)? That would add a MODIFIED workflow-guards requirement and a guards case. Default here: no.
