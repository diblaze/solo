---
name: adr
description: Write an architecture decision record into docs/adr/ — the decision, what was rejected and why, and what would reverse it. Use when a choice is hard to undo (dependency, schema, protocol, hosting, auth) or was argued about. Does not plan the implementation — use solo:plan. Does not document how the system works — use solo:docs.
argument-hint: <decision>
---

# ADR

One decision per file. If it is easy to reverse and nobody will ask "why is it like this" in six months, skip the ADR and put a line in the commit message.

## File
`docs/adr/NNNN-<kebab-slug>.md`, NNNN = next number, zero-padded to 4. Never renumber, never rewrite an accepted one — supersede it with a new file and set the old one's status.

## Shape
```markdown
# NNNN. <decision in one line, active voice>

- Status: proposed | accepted | superseded by [NNNN](NNNN-slug.md)
- Date: YYYY-MM-DD

## Context
What forced a choice. Constraints that are real: money, existing stack, ops burden, who maintains it. Cite `path:line` or a link for anything already in the repo.

## Decision
What we do, stated so someone can tell whether the code follows it.

## Alternatives rejected
One block each: what it was, why not — the actual reason, not "too complex".

## Consequences
What gets easier, what gets worse, what we now have to maintain. Include the unpleasant half; an ADR with only upsides is marketing.

## Reversal
The signal that would make us revisit, and roughly what undoing costs.
```

## Rules
- Past decisions are immutable history. Superseding is a new file plus a status edit on the old one, never an edit of the body.
- No decision without a rejected alternative. If nothing was rejected, there was no decision.
- Evidence over assertion: benchmark, cost figure, `path:line`, or a dated link. Unmeasured claim → prefix `Unverified:`.
- Keep it under a page. The ADR that nobody reads records nothing.
