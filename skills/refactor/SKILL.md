---
name: refactor
description: Behavior-preserving restructuring of existing code — extract, inline, collapse, delete. Use when the shape blocks a change, or after a feature lands and the seams are visible. Does not add behavior — use solo:plan then execute. Does not clean up slop in code that just landed — use solo:slop. Does not review a diff — use solo:review. Does not fix a bug — use solo:investigate.
argument-hint: <path or symbol to restructure>
---

# Refactor

Behavior stays identical. If behavior changes, it is not a refactor — stop and go through `/solo:plan`.

## 1. Safety net first
No test covering the target → write the characterization test before touching anything: call the current code, assert what it actually does today (even if that is wrong). Run it green. No net, no refactor.

## 2. Name the smell, cite it
One line per target, `path:line` each. Legitimate targets only:
- duplicated logic with a real shared owner
- a function doing two jobs with an `if` flag deciding which
- a caller chain passing a value through three layers that ignore it
- dead code, unused exports, single-implementation interfaces, config for a constant
- a guard repeated in every caller instead of once in the shared function

Not targets: naming you dislike, formatting, "could be more elegant", file length alone.

## 3. One move at a time
Each step: one mechanical transform → run the tests → next. Never two transforms between green bars. Deletion counts as a move and is the best one.
Prefer removing an abstraction over adding one. If the refactor grows a new layer, justify it in one line or drop it.
A mechanical move big enough to qualify under `/solo:execute` step 4 (a rename across many files, say) may go to `solo:implementer` with that recipe; outside a change, the prompt carries the named move, the allowed paths and the test command. You still run the tests yourself between moves.

## 4. Verify
Re-run the characterization tests plus the repo's own check. `git diff --stat` — a refactor that grew the line count needs a reason in the report.
`rg` every caller of each signature you touched; a refactor that leaves a sibling caller broken is a bug, not a cleanup.

## Done
Report: smells removed with `path:line`, lines added/removed, the check that ran, anything deliberately left alone and why.
