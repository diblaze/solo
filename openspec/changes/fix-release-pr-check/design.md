# Design
## Context
E1 `.github/workflows/release.yml:17-21` — `permissions:` … `actions: write` — job permissions; `actions: write` exists only for the dispatch.
E2 `.github/workflows/release.yml:23` — `- id: rp` — step id; `rg -n 'steps\.rp'` finds it only in E3 (and the archived plan), so the id goes too.
E3 `.github/workflows/release.yml:32-39` — `- name: run ci on the release PR` … `gh workflow run ci.yml --repo "$GITHUB_REPOSITORY" --ref "$branch"` — the dispatch step.
E4 `.github/workflows/ci.yml:6-8` — `pull_request:` / `branches: [main]` / `workflow_dispatch:` — the trigger only E3 uses; `rg -n workflow_dispatch -g '!openspec/changes/archive/**'` finds it only here and in E6.
E5 `tests/guards.test.sh:363-380` — `case="Release PR gets the required check"` … `[ "$jp" = "actions: write contents: write issues: write pull-requests: write " ]` — guard pins the dispatch.
E6 `tests/guards.test.sh:380` — `rg -q '^  workflow_dispatch:' "$P/.github/workflows/ci.yml" || fail "ci.yml lacks workflow_dispatch"`.
E7 `tests/guards.test.sh:377-379` — `# Expressions only inside an env: map: one in run: is a script injection.` — stays.
E8 `openspec/specs/release-flow/spec.md:42-48` — `### Requirement: Release PR runs the required check` / `The system SHALL run the required \`check\` job on the release PR head every time the release workflow opens or updates it.` — the contract this change modifies.
E9 `README.md:176` — `- Merge the release PR like any other, with \`/solo:pr-ready\` step 6.` — omits the approve step.
E10 live 2026-11-20 — PR #34 head `d482523cb27b…`, author `app/github-actions`; run 44727166242 `workflow_dispatch` success; run 44727159826 `pull_request` held at `action_required` with 0 jobs. With only the dispatched success the PR stayed `BLOCKED`, statusCheckRollup null. After `gh api -X POST repos/diblaze/solo/actions/runs/44727159826/approve` it passed and the PR went CLEAN. Merged; tag `solo--v2.9.1` and release created. Checked with gh: run 44727159826 now `pull_request`/success; ruleset 25596193 requires `[{"context":"check","integration_id":15368}]`.
E11 `lefthook.yml:9,18` — pre-commit and pre-push both run `bash tests/guards.test.sh`.

## Goals / Non-Goals
**Goals:**
- Delete E3, E2 and the `actions: write` line of E1, and the `workflow_dispatch:` trigger of E4. Re-point the guards E5/E6. Document the approve step.
**Non-Goals:**
- PAT or GitHub App token so release PRs start CI without approval. Reopen when approving every release becomes a burden (user chose "approve per release").
- Finding why the dispatched `check` did not satisfy the ruleset (E10, cause unknown). Reopen if a dispatch-based design comes back.
- Automating the approve call in a script. Reopen when releases happen often enough that the manual step gets forgotten.

## Decisions
- Approve the parked `pull_request` run by hand. This was the user's choice and it is proven on #34 (E10). Dispatch lost: its check did not count (E10).
- Drop `id: rp` together with the step. Nothing else reads its outputs (E2).
- Drop the `fromJSON` guard in E5 too. It protected the removed `PR_JSON` env. Keep the env-only expression guard (E7), which still covers `GH_TOKEN`-style env later.

## Risks / Trade-offs
- A release PR left unapproved never merges and no release ships. The README step and the BLOCKED state make it visible.

## Open Questions
