---
name: gap-analysis
description: Compare what exists against what was specified — plan, spec, ticket, API contract, upstream docs — and list what is missing, partial, contradictory, or undocumented-extra. Use before calling work done, or when inheriting a half-built feature. Does not find bugs in code that matches the spec — use solo:investigate or review. Does not research options — use solo:research.
argument-hint: <spec path or description> [vs <code path>]
---

# Gap analysis

Two artifacts: the **reference** (what should be) and the **subject** (what is). Name both explicitly before starting — if the reference is only implied ("finish this feature"), reconstruct it from the plan file, ticket, or API docs and state what you used.

## 1. Extract requirements
Walk the reference and number every testable requirement `R1..Rn`, one behavior each. Quote the source line. A requirement nobody could check is not a requirement — flag it as `R? ambiguous` instead of guessing.

## 2. Verify each against the code
Per `R#`, one verdict with `path:line` evidence:
- **met** — cite the code that implements it
- **partial** — cite what exists, name precisely what is missing
- **missing** — cite where it would live; "searched X, nothing" counts
- **contradicted** — code does something the reference forbids
- **extra** — code does something the reference never asked for (candidate for deletion, not a feature)

No verdict without a citation. Could not check → `Unverified: R#, because <why>`.
Broad surface → delegate one area per `solo:explorer` dispatch, in parallel.

## 3. Tests count as evidence
A requirement with no test is at best partial. Note which `R#` have a check that would fail if the behavior regressed.

## 4. Report
Table `R# | verdict | evidence`, then:
- blockers first (missing + contradicted), ordered by what breaks worst
- the smallest set of changes that closes them, shortest diff, each tied to an `R#`
- extras with a one-line keep-or-cut recommendation

Closing the gaps is a change → route through `/solo:plan`, not this skill.
