## Coding standard
- Stack: Claude Code plugin — markdown skills (`skills/*/SKILL.md`), agents (`agents/*.md`) and bash scripts (`skills/*/scripts/*.sh`). Manifests in `.claude-plugin/`.
- Package manager: none. Tools: `bash`, `git`, `gh`, `rg`, `shellcheck`, `gitleaks`, `lefthook`.
- Check: `lefthook run pre-push --all-files` — must be green before a PR. CI: `.github/workflows/ci.yml` runs the same plus actionlint and `claude plugin validate --strict`.
- Lint: `shellcheck -S warning` on every `*.sh`; `gitleaks` with `.gitleaks.toml` (default rules plus private IPs and home paths).
- Tests: `bash skills/plan/scripts/scripts.test.sh`, `bash skills/pr-ready/scripts/open-pr.test.sh`, `bash tests/guards.test.sh`, `bash skills/map/scripts/check-map.test.sh`. Throwaway git repos in `mktemp -d`, stubs on `PATH` for `openspec`, `npx` and `gh`, and `unset GIT_DIR …` at the top of any harness that makes its own repo.
- Style: scripts use `set -euo pipefail`, `rg` (never grep) and quoted paths; shared checks live in `skills/plan/scripts/common.sh`.
- Language: code, commits and docs English.
- Tracking: GitHub Issues. Labels `type:bug|feat|chore`. The last slice commit carries `Refs owner/repo#n`; the spec-fold commit carries `Closes owner/repo#n`.
- Don't: commit personal names, domains, hostnames, private IPs or home-directory paths — in files, commit messages, issues or PRs.
