---
name: investigate
description: Evidence-first root-cause hunt for a code bug or failing behavior. Produces E# evidence, root cause, a counter-check, and a fix plan — does not apply the fix (hand to plan/execute). Does not debug containers or the homelab stack — use homelab:debug. Does not review quality — use solo:review.
argument-hint: <symptom> | #<issue>
---

# Investigate

Symptom is a claim. Trace it; don't guess.

## 1. Evidence
Gather `E1..En`. Each = `path:line` + verbatim snippet or log line + relevance. Angles, all of them:
- error path (where the symptom surfaces → up the call chain)
- data flow (where the value was last correct)
- recent change (`git log -p --since` on touched files; read the diff, not just blame)
- test coverage (what test would have caught it; "none exists" is evidence)
Big sweep → delegate to `solo:explorer`, one angle per dispatch, run in parallel. Record negatives: "searched X for Y, nothing".

## 2. Root cause
One to three sentences, citing E#. Symptom-as-cause check: if the chain from symptom to cause is one hop, keep tracing.

## 3. Counter-check (mandatory)
Before proposing the fix, try to disprove yourself:
- alternative path producing the same symptom?
- cited lines still current (`git log -1 -- path`)?
- callers of whatever the fix touches (`rg`) — would any break?
- happy path only, or error path too?
Record as `V1..Vn`. If a V changes the root cause, update §2 and say so.

## 4. Fix plan
Shortest diff at the point all callers route through. List files + which E# justifies each. One runnable check that fails today and passes after.

`$ARGUMENTS` is `#n` → `gh issue view n --json title,body,comments` is the symptom report; the change carries `Issue: <owner/repo#n>`. Hand the E#/V# list and the fix plan to `/solo:plan`, which writes the OpenSpec change (`openspec/changes/fix-<slug>/`, Status: draft) — the broken behavior becomes a scenario the fix must pass; summary in chat: root cause, fix, strongest evidence, remaining risk. Any input you could not inspect → `Unverified: <what>, because <why>` on the finding it weakens.
