---
name: plan
description: Gate 1 of plan → execute → review. Dispatches the Fable `solo:planner` agent to write an OpenSpec change (openspec/changes/<slug>/ — proposal, delta specs, design, tasks) grounded in codebase evidence, then stops for approval. Use for any change touching more than one file or any behavior change. Does not edit code — use solo:execute after approval. Does not diagnose a bug — use solo:investigate first, it feeds a plan.
argument-hint: <what to build or change> | #<issue> | <issue url>
---

# Plan

Every CLI step is a script in this skill's `scripts/` folder (under the base directory shown when the skill loads); run those, never retype their commands. They use the global `openspec` binary when installed, else `npx -y @fission-ai/openspec@1`; exit 127 = neither available → stop and say so. Run them from the repo root.

0. Issue first. `$ARGUMENTS` is `#n` or an issue URL → `gh issue view n --json url,title,body,labels,parent,blockedBy,subIssues`; that is the request. Otherwise the request is the prose, and an issue gets created at approval (step 4).
1. Pick the slug (kebab-case, verb first: `add-`, `fix-`, `remove-`) and run `scripts/new-change.sh <slug>`. It initialises `openspec/` when the repo has none (rides in the change's first commit), creates the change and prints its path.
2. Gather what the planner needs and can't ask for: the request verbatim (or the issue JSON), repo root, relevant paths you already know, constraints the user stated, an existing `openspec/changes/<slug>/` if this continues one. Big unknown surface → run `solo:explorer` first and pass its `E#` list along (cheaper than Fable grepping).
3. Dispatch `solo:planner` once with all of it, plus the change path and the absolute validate command (`<base directory>/scripts/validate-change.sh <slug>`). Do not plan inline — the point is one expensive pass in a throwaway context.
4. Sanity check only: `scripts/validate-change.sh <slug>` exits 0 (strict OpenSpec validation, Status/Issue present, every scenario named by a task); every task cites an E# or a scenario; the last task group is a runnable check. Don't re-plan; if something is wrong, send the planner one follow-up via SendMessage with the specific defect.
5. Gate: show the change path + the planner's 3-line summary + the requirement names per capability + `## Open Questions`. AskUserQuestion: approve / revise / drop. On approve: no issue yet → `gh issue create --title "<first What Changes line>" --body "Change: openspec/changes/<slug>/" --label type:<bug|feat|chore>` then `scripts/set-status.sh <slug> approved <owner/repo#n>`. Drop → delete the change folder. Nothing else edits until then.
