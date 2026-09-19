---
name: docs
description: Write or update documentation for a feature or system from codebase evidence — README, feature doc, API surface. Use when someone else (or future you) needs to use or change the thing. Does not record why a decision was made — use solo:adr. Does not write ops procedures — use homelab:runbook. Does not audit code against a spec — use solo:gap-analysis.
argument-hint: <feature, path, or doc to update>
---

# Docs

Document what the code does, verified by reading it. Every non-obvious claim carries `path:line`.

## 1. Read before writing
Trace the real flow: entry point → core logic → data model → config → tests. Big surface → one `solo:explorer` dispatch per area, in parallel. Do not document intent you cannot see in code; if the code and an existing doc disagree, the code wins and the contradiction goes in the report.

## 2. Updating an existing doc
Diff-minded: keep every fact still true. Before deleting a line, verify in the code that it is actually obsolete — cite the `path:line` that makes it so. Unverified removals are data loss.

## 3. Shape
Answer first, detail after. Per section:
- **What it is** — one paragraph, no preamble.
- **How to use it** — the actual commands and calls, copy-pasteable, real values not `<placeholder>` where a real value exists.
- **How it works** — only the parts a reader must know to change it safely: the invariant, the ordering, the gotcha. Not a code walkthrough.
- **Config** — every knob: name, default, effect, `path:line` where it is read.
- **Limits** — what it does not do, known ceilings, anything marked `ponytail:` in the code.

## 4. Voice
Short sentences, active, present tense. No "simply", "just", "robust", "seamless". No feature tour, no marketing. A code block beats a paragraph describing the code block. If the explanation is longer than the thing it explains, cut the explanation.

## 5. Verify
Run every command you wrote down. Broken command in a doc is a bug. Could not run it → `Unverified: <command>, because <why>`.

## Done
Report: files written, what changed, commands actually executed, contradictions found between old docs and code.
