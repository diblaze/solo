# Tasks
## 1. shellcheck-clean scripts
- [x] 1.1 Confirm red: `git ls-files -z '*.sh' | xargs -0 shellcheck -S warning` exits 1 with SC2148, SC2164, SC1010 (E1–E3)
- [x] 1.2 Add `# shellcheck shell=bash` as line 1 and change `cd "$root"` to `cd "$root" || exit` in `skills/plan/scripts/common.sh` (E1, E2); verify: 1.1 exits 0 for this file
- [x] 1.3 Quote the six bare `done` arguments as `"done"` in `skills/plan/scripts/scripts.test.sh` (E3); verify: 1.1 exits 0 and `bash skills/plan/scripts/scripts.test.sh` prints `ok`

## 2. Local hooks and privacy rules
- [x] 2.1 Confirm red: `printf 'ip 192.168.%s\n' 7.9 | gitleaks stdin -c .gitleaks.toml --no-banner` (sample built at runtime so no literal is committed) fails because the file is missing; after 2.2 it exits 1 with rule `private-ipv4`, and a home-directory path sample exits 1 with `home-path` (E15)
- [x] 2.2 Add `.gitleaks.toml`: `[extend] useDefault = true` plus rules `private-ipv4` and `home-path` exactly as in design.md (E14, E15); verify: `gitleaks git --redact --no-banner` exits 0 over full history and `gitleaks dir .gitleaks.toml --no-banner` exits 0
- [x] 2.3 Add `lefthook.yml` with the pre-commit and pre-push jobs from design.md (E5, E8, E16); verify: `lefthook run pre-commit --all-files` and `lefthook run pre-push --all-files` exit 0
- [x] 2.4 Add `AGENTS.md` with one `## Coding standard` section (≤ 20 lines, template E21): bash plugin, no package manager, Check `lefthook run pre-push`, CI `.github/workflows/ci.yml`, `shellcheck -S warning`, test harness style, `set -euo pipefail` + `rg`, Don't commit names/domains/hosts/IPs/home paths; verify: every command in it runs
- [x] 2.5 Add `## Contributing` before `## License` in `README.md` (E20): install lefthook (`go install github.com/evilmartians/lefthook/v2@v2.2.2`), gitleaks v8.30.1, shellcheck, rg, then `lefthook install`; what each hook runs; CI runs the same plus actionlint and manifest validation; verify: `bash tests/guards.test.sh` prints `ok`

## 3. CI and Dependabot
- [x] 3.1 Add `.github/workflows/ci.yml` per design.md: job `check` on `ubuntu-24.04`, checkout pinned to `3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1` (E11), `apt-get install -y ripgrep` (E6), actionlint image `rhysd/actionlint:1.7.12@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667` (E13), `git ls-files -z '*.sh' | xargs -0 shellcheck -S warning`, the three suites (E7), gitleaks image `ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f` `git /repo --redact --no-banner` (E12), `npx -y @anthropic-ai/claude-code@2.1.306 plugin validate --strict` on `.` and `.claude-plugin/plugin.json` (E17); `permissions: contents: read`, concurrency cancel; verify: `actionlint .github/workflows/ci.yml` exits 0
- [x] 3.2 Add `.github/dependabot.yml`: `github-actions`, `directory: /`, weekly, `commit-message.prefix: chore(deps)`; verify: `uv run --with pyyaml python -c "import yaml; yaml.safe_load(open('.github/dependabot.yml'))"` exits 0

## 4. Check
- [x] 4.1 `actionlint .github/workflows/*.yml && git ls-files -z '*.sh' | xargs -0 shellcheck -S warning && bash skills/plan/scripts/scripts.test.sh && bash skills/pr-ready/scripts/open-pr.test.sh && bash tests/guards.test.sh && lefthook run pre-commit --all-files && gitleaks git --redact --no-banner`
