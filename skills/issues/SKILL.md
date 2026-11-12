---
name: issues
description: Create, edit, comment on, close, reopen and list GitHub issues and manage milestones through one script, with GitHub issue types and blocked-by dependencies. Use for any issue upkeep outside a change — a new work item, a retype, a milestone, the ready queue. Does not create a change's tracking issue — solo:plan does on approval. Does not read an issue — use plan's `scripts/read-issue.sh`.
argument-hint: [what to do, e.g. "create a bug for …", "#12 to milestone v1", "ready"]
---

# Issues

Every step is `scripts/issue.sh` (under the base directory shown when the skill loads); run it, never a retyped `gh` command. It checks input before `gh` runs (exit 2 names what is wrong), works from anywhere inside the repo and needs gh 2.100 or newer. `--dry-run` as the last argument of any write prints the `gh` calls instead of making them.

| Want | Run |
| --- | --- |
| new issue | `issue.sh create --title <t> --body-file <f> --type feat\|bug\|chore [--milestone <title>] [--assignee <login>] [--blocked-by <n>]…` — prints `owner/repo#n`; assignee defaults to `@me` |
| change fields | `issue.sh edit <n> [--title <t>] [--body-file <f>] [--milestone <title> \| --remove-milestone] [--add-assignee <login>] [--remove-assignee <login>]` |
| retype | `issue.sh edit <n> --type feat\|bug\|chore` |
| dependencies | `issue.sh edit <n> --add-blocked-by <m> --remove-blocked-by <k>` |
| comment | `issue.sh comment <n> --body-file <f>` |
| close | `issue.sh close <n> [--reason completed\|not-planned \| --duplicate-of <m>]` |
| reopen | `issue.sh reopen <n>` |
| ready queue | `issue.sh list --ready [--type <t>] [--milestone <title>] [--limit <n>]` — open and unblocked; without `--ready`, every open issue. Lines: `#n`, type, milestone, title, tab-separated |
| milestones | `issue.sh milestone list`, `issue.sh milestone create <title> [--due YYYY-MM-DD]`, `issue.sh milestone close <title>` |

1. Type: `feat` adds a capability, `bug` is something broken, `chore` is everything else. The script sets them as GitHub's issue types `Feature`, `Bug` and `Task`, never as labels; `list` prints those names. One type per issue. The request does not say which and the text does not settle it → ask.
2. Title and body text always come from the user's words or from evidence you cite. Write a body or comment to a file in the scratch directory and pass `--body-file`; never inline it in the command. One problem per issue: two asks → two issues, linked with `--add-blocked-by` when one waits on the other.
3. A milestone must exist before an issue joins it: `milestone list`, then `milestone create` only when the user named a new one.
4. Run the write the user asked for. A write you inferred (closing an issue as done or duplicate, retyping, editing several issues at once) → show it with `--dry-run` first and run it on a yes.
5. The repo is public or may become so: no personal names, domains, hostnames, private IPs or home-directory paths in a title, body or comment.
6. Report the issue as `owner/repo#n` and what changed, one line each.
