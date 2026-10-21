# Design
## Context
- E1 `skills/plan/scripts/common.sh:1` — `# Sourced by every change script: needs rg, …` — no shebang or directive: shellcheck SC2148 (error).
- E2 `skills/plan/scripts/common.sh:6` — `cd "$root"` — SC2164 (warning).
- E3 `skills/plan/scripts/scripts.test.sh:108,114,123,129,135,144` — `fails 1 "$S/set-status.sh" w done`, `mk w done 'Issue: none'` … — SC1010 (warning) ×6, bare `done` as an argument.
- E4 `skills/plan/scripts/new-change.sh:7` `. "$here/common.sh"` (SC1091, also in openspec.sh:5, set-status.sh:10, validate-change.sh:8, fold.sh:8, open-pr.sh:23); `scripts.test.sh:179` and `tests/guards.test.sh:26` `A && B || fail` (SC2015); `tests/guards.test.sh:50` `'else \`solo:reviewer\`'` (SC2016) — info only, all intentional. shellcheck 0.10.0 `-S warning` on the scratch copy with E1–E3 fixed exits 0.
- E5 `skills/plan/scripts/scripts.test.sh:6`, `skills/pr-ready/scripts/open-pr.test.sh:5` — `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE …` — suites are safe to run inside a git hook.
- E6 `skills/plan/scripts/common.sh:2` — `command -v rg … || { echo "…ripgrep (rg) is required"; exit 127; }` — CI must install rg.
- E7 `skills/plan/scripts/scripts.test.sh:2` — `Offline tests …: stub openspec/npx on PATH`; `open-pr.test.sh:2` — `a stub \`gh\` on PATH` — suites need no network, Node or token.
- E8 `tests/guards.test.sh:13,29,34,37,44,53` — reads `skills/{pr-ready,plan,investigate,review,execute}/SKILL.md`, `agents/planner.md` — skill or agent text edits can break the suites, so they trigger the tests too.
- E9 local run: all three suites print `…: ok`, exit 0.
- E10 actions/runner-images `images/ubuntu/Ubuntu2404-Readme.md:311` — `| shellcheck | 0.9.0-1 |`; no ripgrep listed; same file announces `ubuntu-latest` moving to 26.04 in November 2026.
- E11 `gh api repos/actions/checkout/git/ref/tags/v7.0.1` — `{"sha":"3d3c42e5aac5ba805825da76410c181273ba90b1","type":"commit"}` (lightweight tag, no deref).
- E12 `docker buildx imagetools inspect ghcr.io/gitleaks/gitleaks:v8.30.1` — `Digest: sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f`; gitleaks `Dockerfile@v8.30.1` — `RUN git config --global --add safe.directory '*'` (no dubious-ownership failure on the runner's checkout).
- E13 `docker buildx imagetools inspect rhysd/actionlint:1.7.12` — `Digest: sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667`.
- E14 `gitleaks git --help` (v8.21.2) — `--pre-commit scan using git diff`, `--staged`, `-c … 3. (target path)/.gitleaks.toml` — one config file serves hook and CI.
- E15 gitleaks v8.21.2 over full history: `19 commits scanned … no leaks found`; with the two generic rules below also `no leaks found`; a sample commit with a private IP and a home path: `leaks found: 2`; the config scanned as a file: `no leaks found`.
- E16 lefthook `docs/configuration/glob.md@v2.2.2` — `From lefthook version 1.10.10 you can also provide a list of globs`; `If you've specified glob but don't have a files template … If no files left, the command will be skipped`; `go.mod` — `module github.com/evilmartians/lefthook/v2`.
- E17 `claude plugin validate --help` — `--strict Treat warnings as errors (exit 1). Use in CI`; with an empty `HOME` and no login, `claude plugin validate --strict .` and `… .claude-plugin/plugin.json` both print `✔ Validation passed` (local 2.1.303; npm latest `@anthropic-ai/claude-code` 2.1.306).
- E18 `gh api repos/diblaze/solo/rulesets/25594134` — `"rules":[{"type":"deletion"},{"type":"non_fast_forward"}],"bypass_actors":[]`; owner type `User`.
- E19 `skills/pr-ready/scripts/fold.sh:26` — `if rg -q '^skip_specs:\s*true' "$dir/.openspec.yaml"; then args+=(--skip-specs); fi` — a tooling-only change folds without spec deltas.
- E20 `README.md:99` — `Tests: \`bash skills/plan/scripts/scripts.test.sh\`, …`; `README.md:148` — `## License`; `README.md:122` — `You need \`git\`, \`gh\` (signed in), \`rg\` …`.
- E21 `skills/standard/SKILL.md:24-38` — `## Coding standard` template, `≤ 20 lines`; repo has no `AGENTS.md`.
- E22 `.claude-plugin/plugin.json:3` — `"version": "2.0.0"`.

## Goals / Non-Goals
**Goals:**
- Same checks locally (lefthook) and in CI, green on day one.
- No private string ships in the repo, including in the privacy check itself.

**Non-Goals:**
- Any personal-name or domain check, local or in CI — dropped by the owner 2026-10-22.
- Scanning PR and issue text — reopen when open-pr bodies leak private strings; would belong in `open-pr.sh`.
- Email patterns — gitleaks scans patches, not commit metadata, and the history uses a noreply address; reopen if author metadata needs checking.
- Bumping docker-image digests automatically (Dependabot github-actions ignores `docker run` lines) — reopen when Renovate or Dependabot covers them.
- Plugin version bump for the tooling itself; 2.0.1 covers only the `standard` skill change below (E22).

## Decisions
- Fix E1–E3 in the source (directive line, `cd "$root" || exit`, quote `"done"`) and run shellcheck at `-S warning` everywhere; E4 infos are deliberate idioms. Lost: `.shellcheckrc` with disables (more lines, same effect). E1–E4.
- `skip_specs: true`, no `specs/`: nothing an installer, user or API client observes changes. E19.
- Privacy split: CI and hooks share `.gitleaks.toml` (`[extend] useDefault = true` plus rules `private-ipv4` = `\b(?:10\.\d{1,3}|172\.(?:1[6-9]|2\d|3[01])|192\.168|100\.(?:6[4-9]|[7-9]\d|1[01]\d|12[0-7]))\.\d{1,3}\.\d{1,3}\b` and `home-path` = `/((?:home|Users)/[A-Za-z][\w.-]*)/` with `secretGroup = 1`, because the default global allowlist skips any secret that starts with `/home/` or `/Users/` — found in execute: the slash-led form never fired with `useDefault`). No name or domain denylist: the owner dropped it on 2026-10-22 (review showed lefthook skips pre-push jobs when a push changes no files, so a message-only push slipped past it); keeping personal details out of public text stays a manual rule. E14, E15.
- Hooks (`lefthook.yml`, `jobs:` lists): pre-commit `shellcheck -S warning {staged_files}` glob `*.sh`; tests glob `["*.sh", "skills/*/SKILL.md", "agents/*.md"]` running the three suites; `gitleaks git --pre-commit --staged --redact --no-banner`. Pre-push: shellcheck on all `git ls-files '*.sh'`, the suites, `gitleaks git --redact --no-banner`. E5, E8, E16.
- CI: one job `check` on `ubuntu-24.04` (not `-latest`, E10); `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1` with `fetch-depth: 0`, `persist-credentials: false`; `apt-get install ripgrep` (E6, E10); actionlint and gitleaks via `docker run` on the digests in E12/E13 with `# vX.Y.Z` comments — no gitleaks-action (wants `pull-requests: write`, scans only the pushed range). Runner's shellcheck 0.9.0 is accepted. Workflow `permissions: contents: read`; `concurrency: {group: ci-${{ github.ref }}, cancel-in-progress: true}`.
- Manifest validation in CI: `npx -y @anthropic-ai/claude-code@2.1.306 plugin validate --strict` on `.` and `.claude-plugin/plugin.json` — works without login (E17); a broken manifest breaks every installer.
- Dependabot: `github-actions`, `directory: /`, weekly, `commit-message.prefix: chore(deps)` (conventional commits).
- `AGENTS.md` with only `## Coding standard` per E21; Check is `lefthook run pre-push`. README gets `## Contributing` before `## License` (E20).
- Required check: post-merge, on the owner's yes, a new ruleset (leave "protect main" untouched so a bypass never covers force-push/deletion, E18):
  `gh api -X POST repos/diblaze/solo/rulesets --input -` with `{"name":"ci required","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},"rules":[{"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":false,"required_status_checks":[{"context":"check","integration_id":15368}]}}],"bypass_actors":[{"actor_id":5,"actor_type":"RepositoryRole","bypass_mode":"pull_request"}]}` — admin bypass keeps the owner able to merge when CI itself is broken.

## Risks / Trade-offs
- Docker digests and the npx version go stale silently (Non-Goal above).
- Runner shellcheck 0.9.0 vs local 0.10.0 may disagree on a future warning.
- `npx @anthropic-ai/claude-code` in CI unverified on the runner (E17 is local only); first CI run proves it.
- Names, domains and hosts are not checked by any tool; only private IPs and home paths are.
- Required status checks block direct pushes to `main` for anyone without bypass.

## Open Questions
- none. Resolved 2026-10-21 by the owner: bypass `pull_request` for the repository admin role only (on this personal repo that is the owner alone), so only the owner can merge a PR past red CI and nobody can push past it; the personal-name sweep stays local only (no CI secret).
