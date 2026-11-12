# Design
## Context
S5 = https://code.claude.com/docs/en/plugin-evals, fetched 2026-11-12.
- E1 S5 § Write a case manually — "`type: tool_used` / `tool: Skill` / `input_match: '"skill"\s*:\s*"(?:[\w-]+:)?your-skill-name"'`" — "passes when Claude invoked that skill at least once … including by its namespaced `plugin-name:skill-name` form" — the "fired" grader, copied per skill.
- E2 S5 § Grader types — `tool_used` "`tool`, `input_match`, `min`, `max` … To assert a tool was never called, set both `min: 0` and `max: 0`"; § Score against the no-plugin baseline — "`arm: both` … what you want for a "must not invoke the skill" check with `min: 0` and `max: 0`" — the neighbour grader.
- E3 S5 § Choose and weight graders — "`regex`, `tool_used`, `tool_order`, and `file_exists` … cost nothing, while `llm` and `baseline` call a judge model" — only `tool_used` is needed; zero `llm` graders.
- E4 S5 § prompt.md frontmatter — "`max_turns` | `10` | Turn cap … Hitting it is recorded as a run error"; "`timeout_seconds` | `300`"; "`allowed_tools` | `[]` | … Read-only tools are granted when listed here"; "An unknown key is an error" — the case limits.
- E5 S5 § Grant tools — "Built-in tools that need a grant you didn't give, such as `Bash`, `Write`, `Edit`, `WebFetch`, and `WebSearch`, are removed from the session"; `claude plugin eval --help` (2.1.323) — "`--disallow-tools <tools...>`  Built-in tools to keep from Claude in every case, even if granted (e.g. Agent TaskStop)" — isolation: no shell means no push, PR or issue; `Agent` off stops `/solo:plan` dispatching the Opus planner.
- E6 S5 § How runs are isolated — "Each run gets a temporary home directory, working directory, and Claude Code configuration … Nothing personal or project-level loads"; "Each run starts in an empty working directory" (§ Write a case manually) — prompts carry no real repo, user or host.
- E7 S5 § Score against the no-plugin baseline — "Every `tool_used` grader whose `tool` is `Skill`" is excluded from the score in two-arm runs; "under `--ablation none` nothing is excluded" — a trigger suite's Δ is meaningless (without the plugin no skill fires), so the runner uses one arm.
- E8 S5 § How a case is scored — "roughly cases × runs agent runs with the plugin and the same number again for the no-plugin baseline, plus three short judge calls per `llm` or `baseline` grader per run"; § Command options — "`--runs <n>` | Each case's `runs`, else 3"; "`--max-cost-usd` … Checked before each run starts" — the cost formula.
- E9 S5 § Run evals in CI — "`claude plugin eval . --trust-plugin --json results.json --threshold 0.8 --model claude-sonnet-5 --judge-model claude-haiku-4-5 --no-publish --max-cost-usd 20`"; needs "credentials in the environment such as `ANTHROPIC_API_KEY`"; "give quick every-change suites only graders that don't call a judge, use `--ablation none`" — the CI option left open.
- E10 S5 § Write and refine cases — "`results/` # written by each run; add to .gitignore"; `.gitignore:1-5` has no `evals/` line.
- E11 Run of `claude plugin validate --strict .` on a temp copy of this plugin with `evals/bad/prompt.md` holding `bogus_key: 1` and a grader `type: nonsense` — "✔ Validation passed", exit 0 — validate does not load evals, so the free check goes in `tests/guards.test.sh`.
- E12 `tests/guards.test.sh:6` — "`fail() { echo "FAIL: $case: $*" >&2; exit 1; }`"; `:11` — "`has() { rg -q -- "$2" <<<"$1" || fail "missing /$2/"; }`"; `:15` — "`case="Push and PR open ask first"`" — case names equal scenario names; it already runs in lefthook (`lefthook.yml:9,18`) and CI (`.github/workflows/ci.yml:39`).
- E13 `lefthook.yml:8` — "`glob: ["*.sh", "skills/*/SKILL.md", "agents/*.md"]`" — editing only a case would skip the guards at pre-commit.
- E14 `skills/ship/SKILL.md:12` — "`/solo:plan $ARGUMENTS`"; `skills/execute/SKILL.md:30,32` — "`/solo:slop`", "`/solo:review <base>`"; `skills/pr-ready/SKILL.md:12,15` — same; `skills/investigate/SKILL.md:33`, `skills/research/SKILL.md:30`, `skills/gap-analysis/SKILL.md:34`, `skills/refactor/SKILL.md:9` — hand to `/solo:plan` — a skill a case's skill chains into cannot be its "must not" neighbour.
- E15 F5 of the 2026-11-12 skill-standards audit — "Overlapping scopes most likely to mis-trigger: slop vs refactor vs review; investigate vs research vs gap-analysis; plan vs ship; docs vs adr vs map; issues vs plan (tracking issue)" — the 11 boundary pairs.
- E16 `AGENTS.md:6` Tests line, `:12-20` Map table; `README.md:88` Scripts table, `:107` Tests line, `:162` CI line — the docs to touch.
- E17 `.claude-plugin/plugin.json:3` — "`"version": "2.2.0"`"; `173ea1f feat(issues)` bumped the minor for a new capability; `modernize-skill-frontmatter` takes 2.3.0 first — 2.4.0.
- E18 `AGENTS.md:5,7,10` — shellcheck, `set -euo pipefail`, `rg`, no names/domains/home paths.

## Goals / Non-Goals
**Goals:**
- 16 cases, one per skill (the minimum: each case names one expected skill), every E15 pair guarded, all graders free.
- A run cannot write, push, open a PR, create an issue, publish a report or dispatch a subagent.
- Runnable unchanged before and after the description rewrite in `modernize-skill-frontmatter`.

**Non-Goals:**
- Outcome graders (`llm`, `regex` on the reply) — reopen when a skill's output, not its trigger, needs regression cover.
- Negative cases ("no skill should fire") — reopen when a skill fires on unrelated requests in normal use.
- Two-arm Δ runs — reopen if a case gains a scored outcome grader (E7).
- Running the suite in CI or lefthook — Open Questions.
- A wrapper that parses `aggregate-result.json` — reopen when results are charted over time.

## Decisions
- Case = `evals/<skill>/` with `prompt.md` (`allowed_tools: [Skill]`, `max_turns: 3`, `timeout_seconds: 120`, `tags: [boundary]` only where it has a neighbour grader, so `--tag boundary` picks the pair cases) and `graders/fires.md` (E1); neighbour graders are `graders/not-<skill>.md` with `min: 0`, `max: 0`, `arm: both` (E2). `case.yaml` is not needed (no scaffold, E6). Lost: `Read/Glob/Grep` in `allowed_tools` — the workspace is empty, they only burn turns.
- Neighbours (E15), excluding skills the case's skill chains into (E14), so `ship` has none. A skill that chains into the case's skill is a neighbour the other way round: if the prompt routes to it, its chained call would satisfy `fires.md`. So slop and review also refuse pr-ready and execute, and execute and pr-ready refuse ship (E14):

  | case | prompt gist (generic, no repo/user/host) | must not fire |
  | --- | --- | --- |
  | slop | module works but bloated: dead helpers, pass-through wrappers, tests asserting nothing; clean it | refactor, review |
  | refactor | before adding a payment method, pull tax logic out of a long checkout handler, no behavior change | slop, review |
  | review | look over my branch diff before it merges, fix what you find | slop, refactor |
  | investigate | nightly export writes empty CSV files since Tuesday; find out why | research, gap-analysis |
  | research | SQLite or Postgres for a small self-hosted app? compare and recommend | investigate, gap-analysis |
  | gap-analysis | inherited a half-built feature with its spec; list what is missing or partial | investigate, research |
  | plan | add rate limiting to the login endpoint; I want to read the plan before code | ship, issues |
  | ship | take CSV export on the reports page all the way to an open PR, pause only for plan approval | — |
  | docs | write a README section on configuring and running the export CLI | adr, map |
  | adr | we argued and chose webhooks over polling; record the decision and what we rejected | docs, map |
  | map | inherited repo; write the per-directory AGENTS.md map | docs, adr |
  | issues | file a feature issue for dark mode and put it in milestone v2 | plan |
  | execute | change `add-csv-export` is approved; implement it | — |
  | pr-ready | branch is done; get it ready and open the PR | — |
  | tdd | build the invoice-total parser test-first, red before green | — |
  | standard | set up this new repo's coding standard: package manager, check command, lint | — |
- `max_turns: 3` — turn 1 picks the skill, the skill body then finds no shell (E5) and replies; low cap bounds cost (E4). Lost: the default 10.
- Runner `evals/run.sh`: `exec claude plugin eval "$root" --ablation none --no-publish --max-cost-usd "${SOLO_EVAL_MAX_USD:-5}" "$@" --disallow-tools Bash Write Edit NotebookEdit WebFetch WebSearch Agent` — target first, disallow last so operator flags cannot follow it and nothing granted survives (E5, E7, E9). No `--trust-plugin`: the operator answers the first-run prompt. Lost: a documented one-liner — too long to retype the same way every time.
- Static checks in `tests/guards.test.sh` (E11, E12), not a new test file — already wired into lefthook and CI. Lefthook pre-commit glob gains `evals/**` (E13).
- Version 2.4.0 (E17), after `modernize-skill-frontmatter` takes 2.3.0: a new maintainer capability shipped in the plugin, no skill behavior change, nothing breaking.

## Risks / Trade-offs
- Hitting `max_turns` is a run error (E4); if it zeroes free graders, every case fails — raise to 5 on the first measured run.
- `evals/run.sh` sits in the eval dir root; only dirs with `prompt.md`/`case.yaml` are cases, so it should not load as one — move to `tests/` if the loader complains.
- Trigger rates shift with the model; comparisons before and after the description change must pin `--model` on both runs.

## Open Questions
- Run the suite in CI? Per run, agent runs = cases × runs × arms + 3 × (`llm`/`baseline` graders) × runs (E8); here 16 × 3 × 1 + 0 = 48 runs per suite, list-price cost unknown until one `bash evals/run.sh --runs 1` reports its COST. CI would add an `ANTHROPIC_API_KEY` secret, `--trust-plugin`, a pinned `--model` and a `--threshold` (E9). Yes → a separate manual `workflow_dispatch` job (never on push); no → stays local only.
