---
name: ship
description: Whole pipeline in one command — solo:plan (Opus planner, Fable only on your yes) → pause for approval → solo:execute (implement, check, slop, review, commit) → solo:pr-ready. Use for a change you would otherwise babysit through each gate. Stops on open questions, a failing check, or an unresolved CRIT. Does not skip approval — that pause is the point.
argument-hint: <what to build or change> | #<issue>
---

# Ship

Same gates, one invocation. Nothing here is a shortcut past a gate; it removes the typing between them.

1. `$ARGUMENTS` may be `#n` — plan reads the issue. Bug symptom rather than a change request → `/solo:investigate` first; its plan feeds step 2.
2. `/solo:plan $ARGUMENTS`. The planner runs once, on Opus unless you approve Fable when plan asks. Show the change path + 3-line summary + requirement names + `## Open Questions`.
3. **Pause.** AskUserQuestion: approve / revise / drop. Open questions that change specs or tasks must be answered here; do not guess them. Revise → one SendMessage to the planner with the specific defect, then re-ask. Drop → stop, delete the change folder.
4. On approve set `Status: approved`, then `/solo:execute <slug>`. That already branches, implements, runs the check, slop pass, `/solo:review`, and commits.
5. Stop conditions inside execute — surface, do not push through:
   - check fails after the fix attempt → show output, ask
   - reviewer CRIT you cannot resolve → show it, ask
   - execute needs to change a requirement → say what and why, ask
6. `/solo:pr-ready <base>` — folds the delta specs into `openspec/specs/`, archives the change, opens the PR. Print the PR URL.

Report at the end: archived change path, the commit list (one feature slice each), check output, PR URL, anything left `Unverified:`. Total wall of text ≤ 15 lines; details are in the archived change and the PR.
