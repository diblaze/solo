# Design
## Context
- E1 `skills/execute/SKILL.md:10` — "On `main`/`master` → branch first: `git switch -c <type>/<slug>`. Always" — the rule, prose only.
- E2 `skills/execute/SKILL.md:33` — "The change folder itself rides in the first commit."; `:23` — "`git add -u && git add -- <the group's allowed paths that exist> <test files you wrote for this group> openspec/changes/<slug>/`" — every execute commit stages the change folder, so a staged approved folder marks an execute commit.
- E3 `skills/plan/scripts/create-issue.sh:49` — "`"$here/set-status.sh" "$slug" approved "$issue"`"; `skills/plan/scripts/set-status.sh:15` — "`draft|approved|done`" — approval writes `Status: approved` into the working tree before execute branches.
- E4 Read-only look at another repository of the user's that commits straight to main: its working tree holds several change folders with `Status: approved`, some tracked and some untracked. A plain "approved change exists and HEAD is main" condition would block its ordinary commits. Keying on the folder being committed does not.
- E5 `skills/execute/SKILL.md:31` — "`rg -n 'TODO|FIXME|NotImplemented|\.only\(|xit\(|xdescribe\(' <diff files>`" — the placeholder scan; this repo's own skill text and fixtures contain the pattern.
- E6 `skills/pr-ready/SKILL.md:67` — "Never run its steps by hand." for `open-pr.sh`; `skills/pr-ready/scripts/open-pr.sh:56` — "`write gh pr create --base "$base" …`" — gh runs inside the script, not as a tool call.
- E7 `skills/pr-ready/SKILL.md:70` — "Never squash-merge"; `skills/pr-ready/scripts/merge-pr.sh:92` — "`[ "$squash" != true ] || write gh repo edit --enable-squash-merge=false`"; `tests/guards.test.sh:27` — "pr-ready types gh pr merge instead of running merge-pr.sh" — squash is already switched off on the forge and guarded in text.
- E8 `skills/plan/scripts/common.sh:5-6` — "`[ -n "${GIT_WORK_TREE:-}" ] || unset GIT_DIR`" / "`root="$(git rev-parse --show-toplevel)"`" — exits non-zero outside git, so the guard must not source it; copy the `GIT_DIR` line.
- E9 `skills/issues/scripts/issue.test.sh:4-10` — "`set -euo pipefail`", "`unset GIT_DIR GIT_WORK_TREE …`", "`tmp="$(mktemp -d)"`", "`export GIT_CEILING_DIRECTORIES="$tmp"`" — harness pattern to copy.
- E10 `lefthook.yml:9` and `:18` tests jobs, `.github/workflows/ci.yml:35-41` tests step (installs `jq` at `:33`), `AGENTS.md:6` Tests line, `README.md:88-107` Scripts table and Tests line — where a suite is wired.
- E11 `.claude-plugin/plugin.json:3` — "`"version": "2.3.0"`" on the `modernize-skill-frontmatter` base, and `add-plugin-eval-suite` takes 2.4.0 — minor bump for new user-visible behavior.
- E12 `openspec/specs/workflow-guards/spec.md:47-48` — "Execution stages only planned paths" — the capability already holds execute's guards; no existing requirement covers commits, so both requirements are ADDED.
- E13 S6 https://code.claude.com/docs/en/hooks#hooks-in-skills-and-agents — "keeps running them for the rest of the session, on turns after the skill's own turn as well" — the hook outlives execute, so it must be inert elsewhere.
- E14 S6 #common-fields — `if`: "Permission rule syntax … such as `"Bash(git *)"`"; #bash-if-matching — "`npm test && git push` | yes | each subcommand is checked"; "the `if` filter is best-effort, use the permission system rather than a hook to enforce a hard allow or deny" — filter on `Bash(git commit *)`, re-check inside the script.
- E15 S6 #common-fields — `once`: "removes the hook after its first successful run. A run that fails, blocks with exit code 2, or times out leaves the hook in place".
- E16 S6 #reference-scripts-by-path — placeholders for hook commands are "`${CLAUDE_PROJECT_DIR}`", "`${CLAUDE_PLUGIN_ROOT}`", "`${CLAUDE_PLUGIN_DATA}`"; #exec-form-and-shell-form — "both export them as the environment variables `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_ROOT`, and `CLAUDE_PLUGIN_DATA`"; "In shell form, wrap each placeholder in double quotes."
- E17 S1 https://code.claude.com/docs/en/skills#available-string-substitutions — "Claude Code substitutes `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` in two places: the skill's markdown content, and Bash rules in the `allowed-tools` frontmatter" — `${CLAUDE_SKILL_DIR}` is not documented for hook commands.
- E18 S6 #exit-code-2 — "Exit with code 2 to block the action … The message that comes with the block is your hook's stderr"; #block-the-action-when-a-hook-fails — "Without `onFailure` set, the same missing script is a non-blocking error".
- E19 S6 #common-input-fields — PreToolUse stdin carries "`"cwd"`", "`"tool_name": "Bash"`", "`"tool_input": { "command": … }`"; "`cwd` follows Claude".
- E20 S4 (sub-agents) — plugin subagents ignore `hooks`; the hook goes on the execute skill.

## Goals / Non-Goals
**Goals:**
- An approved change's commit on main or master is refused by a hook, not by prose (E1, E2).
- The hook is inert in every other repository and on every other command, for the rest of the session (E4, E13).

**Non-Goals:**
- Placeholder scan as a commit hook. It would hit this repo's own skill text and test fixtures (E5) and flag legitimate "TODO" prose in other repositories. It stays in execute step 8, slop and review. Reopen when a placeholder lands in a merged PR despite those.
- Blocking `gh pr create` typed by hand. Nothing in a repository says whether it uses solo at PR time (the change is archived by then), and other repositories open PRs by hand. `open-pr.sh` is not affected anyway (E6). Reopen when a hand-opened PR skips the label, assignee or `Closes` line in a solo repo.
- Blocking `gh pr merge --squash`. `merge-pr.sh` switches squash off on the forge itself, and guards.test.sh keeps the text clean (E7). Reopen when a repository needs squash left on.
- `once: true`. An allowed commit in another repository would remove the guard before execute commits (E15). The repo-state condition already makes the hook inert elsewhere. Reopen if a skill gets a rule that only matters for its own turn.

## Decisions
- Block on "HEAD is main or master, and the commit carries an approved change folder" (staged under `openspec/changes/<slug>/`, or `openspec/changes/<slug>` named in the command text). The rejected alternative, "an approved folder exists and HEAD is main", would break the other repository (E4). The command-text check covers `git add <folder> && git commit` in one call, where the folder is not staged yet when PreToolUse fires (E2, E14).
- The repository is the hook's `cwd`, unless the command first does `cd <dir>` or runs `git -C <dir>` (quoted or bare, `~` and relative paths resolved): agents commonly prefix commands that way, so a guard keyed to `cwd` alone would miss the commits it exists for. Best effort; a path the guard cannot resolve lets the command run.
- Approved slugs come from `openspec/changes/*/proposal.md` holding `^Status: approved` in the working tree (E3). The glob does not reach the `archive/` subfolders.
- One script, `skills/execute/scripts/commit-guard.sh`, registered only on `/solo:execute`. execute makes every gated commit (E2), and ship invokes execute. It does not source `common.sh` (E8).
- Wiring: `matcher: "Bash"`, no `if` filter, shell form `bash "${CLAUDE_PLUGIN_ROOT}/skills/execute/scripts/commit-guard.sh"`. `if` is a prefix permission rule (E14), so `git -C <dir> commit`, `git -c k=v commit` and `env X=1 git commit` would never reach the script; without it the guard runs on every Bash call and exits in about 25 ms when the command is not a commit (measured, 20 runs in 0.5 s). `${CLAUDE_SKILL_DIR}` was rejected for the hook command: it is documented only for skill content and `allowed-tools` (E17). `${CLAUDE_PLUGIN_ROOT}` works both as a placeholder and as an exported variable the shell expands (E16).
- Block only a commit that carries an approved change folder **and** files outside `openspec/`. A commit of only `openspec/` files is planning (a reviewed plan committed straight to main in a repository that works that way) and passes; execute's slice commits always carry code. The folder counts when staged, named in a `git add` of the same command (or a parent of it), taken in by `git add -A|--all|.` while it has changes, or by `commit -a` while it has tracked edits. A command split into segments on `;`, `&`, `|`, `(`, `)` and newlines; the last `cd` before the commit and the commit's own `-C` pick the repository.
- Block with exit 2 and one stderr line naming the branch, the slug and `git switch -c <type>/<slug>` (E18). JSON `permissionDecision` was rejected: it adds output parsing and gives the same result.
- Fail open. With `set -euo pipefail`, a missing `jq`, `rg` or `git`, unparsable input or a non-git `cwd` leads to exit 0 or a non-blocking error, never exit 2 (E18). This is a workflow guard, not a security boundary (E14).
- Test harness like `issue.test.sh` (E9): stub JSON on stdin, throwaway repos in `mktemp -d`, assert exit codes 0 or 2.
- Version 2.5.0: new user-visible behavior (E11); `modernize-skill-frontmatter` takes 2.3.0 and `add-plugin-eval-suite` 2.4.0 before it.

## Risks / Trade-offs
- `git switch -c x && git commit` in one call is refused, because HEAD is still main when the hook runs. The stderr line says to branch first, in a separate call.
- `${CLAUDE_PLUGIN_ROOT}` in a plugin skill's frontmatter hook: measured on Claude Code 2.1.323 with a throwaway plugin skill carrying this hook block (`claude -p --plugin-dir … --allowedTools "Bash(git commit *)"`). On main with an approved folder staged the commit was refused with the guard's stderr and nothing was committed; on a feature branch the same commit went through. Re-run with the final script and no `if` filter: code plus the approved folder on main was refused (0 commits); the approved folder alone on main committed. A skill loaded from a checkout without a plugin has no `CLAUDE_PLUGIN_ROOT`; the hook then fails to start and does not block (E18).
- A repository that wants approved changes committed on main gets refused there. That matches E1, but see the Open Question.

## Open Questions
- None left. Opt-out: yes (decided 2026-11-13). A repository that commits approved changes straight to main sets `git config solo.allowMainCommits true`: local to the clone, nothing committed, read with `--type=bool` so `yes`/`on`/`1` count too.
