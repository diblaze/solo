---
name: ship
description: Whole pipeline in one command — solo:plan (Fable planner) → pause for approval → solo:execute (implement, check, slop, review, commit) → solo:pr-ready. Use for a change you would otherwise babysit through each gate. Stops on open questions, a failing check, or an unresolved CRIT. Does not skip approval — that pause is the point.
argument-hint: <what to build or change> | #<issue>
---

# Ship

Same gates, one invocation. Nothing here is a shortcut past a gate; it removes the typing between them.

1. `$ARGUMENTS` may be `#n` — plan reads the issue. Bug symptom rather than a change request → `/solo:investigate` first; its plan feeds step 2.
2. `/solo:plan $ARGUMENTS`. The planner runs on Fable, once. Show path + 3-line summary + `## Open questions`.
3. **Pause.** AskUserQuestion: approve / revise / drop. Open questions that change `## Changes` must be answered here; do not guess them. Revise → one SendMessage to the planner with the specific defect, then re-ask. Drop → stop, plan stays `draft`.
4. On approve set `Status: approved`, then `/solo:execute <plan>`. That already branches, implements, runs the check, slop pass, `/solo:review`, and commits.
5. Stop conditions inside execute — surface, do not push through:
   - check fails after the fix attempt → show output, ask
   - reviewer CRIT you cannot resolve → show it, ask
   - execute needs to change `## Changes` → say what and why, ask
6. `/solo:pr-ready <base>`. Print the PR URL.

Report at the end: plan path, the commit list (one feature slice each), check output, PR URL, anything left `Unverified:`. Total wall of text ≤ 15 lines; details are in the plan file and the PR.
