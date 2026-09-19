---
name: plan
description: Gate 1 of plan → execute → review. Dispatches the Fable `solo:planner` agent to write docs/plans/<slug>.md grounded in codebase evidence, then stops for approval. Use for any change touching more than one file or any behavior change. Does not edit code — use solo:execute after approval. Does not diagnose a bug — use solo:investigate first, it feeds a plan.
argument-hint: <what to build or change>
---

# Plan

1. Gather what the planner needs and can't ask for: the request verbatim, repo root, relevant paths you already know, constraints the user stated, prior `docs/plans/` file if this continues one. Big unknown surface → run `solo:explorer` first and pass its `E#` list along (cheaper than Fable grepping).
2. Dispatch `solo:planner` once with all of it. Do not plan inline — the point is one expensive pass in a throwaway context.
3. Read the returned plan file. Sanity check only: sections present, every Change cites an E#, Check is runnable. Don't re-plan; if something is wrong, send the planner one follow-up via SendMessage with the specific defect.
4. Gate: show path + the planner's 3-line summary + `## Open questions`. AskUserQuestion: approve / revise / drop. On approve set `Status: approved`. Nothing else edits until then.
