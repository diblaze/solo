---
name: slop
description: Deletion-first cleanup of AI slop in code that works but is bloated — dead code, duplicates, pass-through wrappers, wrong-layer logic, tests asserting nothing, templated UI defaults. Behavior locked by the check, one smell per pass. Use on "deslop", "clean up the slop", or as the slop pass inside solo:execute and solo:pr-ready. Does not restructure for a coming change — use solo:refactor. Does not hunt bugs — use solo:review. Does not add behavior — use solo:plan.
argument-hint: [files or dir, default = branch diff vs main]
---

# Slop

Behavior stays identical. Scope = `$ARGUMENTS`, else `git diff --name-only <base>...HEAD` (empty → working tree diff). Never widen the scope on your own; slop seen outside it goes in the report, not the diff.

## 1. Lock behavior
Find the check that covers the scope (plan's `## Check`, else the repo test command) and run it green before the first edit. Nothing covers it → write the narrowest characterization test first, or state the manual verification in one line. Behavior too unclear to lock → stop, say so.

## 2. List the smells, cite them
One line each, `path:line`, grouped by class. No edit before the list exists.
- **Dead** — unused code/imports/exports, unreachable branches, stale flags, debug leftovers, commented-out code
- **Duplicate** — copy-paste branches, a helper re-implementing one that already lives in the repo or stdlib
- **Needless abstraction** — pass-through wrappers, single-impl interfaces, single-use helper layers, config for constants, options nobody passes
- **Wrong layer** — logic in the layer that doesn't own it, guard repeated per caller instead of once in the shared function, hidden side effects
- **Noise** — comments restating code, docstrings on the obvious, narration of the edit ("now we…", "updated to…"), defensive checks for states that cannot happen, swallowed errors
- **Weak tests** — assert nothing, assert the mock, duplicate another test, bare `skip`/`.only`
- **UI defaults** (only if the scope has UI) — shadow on every surface, default blue/purple palette or heavy gradient with no brand reason, eyebrow + title + description stuffing, emoji badges, uniform 3/4-column card grid by reflex. Prompts, not bans: a design-system or accessibility reason keeps it.

Not slop: naming taste, formatting, file length alone, anything the user explicitly asked for, trust-boundary validation, error handling that prevents data loss.

## 3. One class per pass, safest first
Dead → Duplicate → Needless abstraction → Wrong layer → Noise → Weak tests → UI. Re-run the check after each pass. Red → fix or back that pass out, never push through.
Deletion beats consolidation beats rewriting. No new deps, no new abstractions, no features. A pass that grows the line count needs a one-line reason.
`rg` every caller of each signature you touched.

## 4. Gates
The check, plus the repo's lint/typecheck for touched files. Inside `/solo:execute` or `/solo:pr-ready`: return to the calling step; fixes fold into the commit that introduced the code.

## Done
Report: smells removed by class with `path:line`, lines added/removed (`git diff --stat`), the check that ran, slop left alone and why.
