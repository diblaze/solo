---
name: brainstorm
description: Lays out three to five materially different approaches to a change in this codebase before any plan or code exists, each with what it costs and where it breaks first, then a recommendation and the open questions that would change it. Use for "brainstorm", "what are our options", "how should we approach this", "ideas for", or an open "should we X or Y" with no decision made. Does not write the plan — use solo:plan once an option is chosen. Does not weigh external sources — use solo:research. Does not find a bug's cause — use solo:investigate. Writes no code and no files.
argument-hint: <problem or decision>
---

# Brainstorm

Generate options. Do not pick one and elaborate it: that is planning, and it happens after the user chooses.

## Contract
- Between three and five options, each a materially different approach. Two options that differ only in naming or file layout are one option.
- Every option carries what it does, what it costs (files touched, new dependencies, operational surface), where it breaks first, and what would have to be true for it to be the right call.
- One option is always "do nothing / do the smallest thing that clears the immediate need". It is a real option, not a courtesy entry.
- End with a recommendation and a one-sentence reason, then the open questions: what you could not resolve from the codebase or the request, and which answer changes the pick.
- No code. A signature or three lines of pseudocode where prose cannot carry the shape, nothing more.
- No files written. The landscape is chat output; the chosen option goes to `/solo:plan`.

## Ground it first
Read before you generate: an option that ignores what the repo already has is noise. Look for an existing helper, pattern or dependency that covers part of the need, the conventions of the surrounding code, and what the repo's `AGENTS.md` says about the area. Cite `path:line` with the snippet when an option leans on something that exists.

Wide surface → one `solo:explorer` dispatch per angle, in parallel, not one per file.

## Evidence
Code is authoritative on current behavior and stands on one citation. An option that rests on an external fact (a library's limits, a vendor's behavior) names it as an open question for `/solo:research`; the landscape does not weigh sources. Could not look → say so on the option it weakens, as its last line: `Unverified: <what>, because <why>`.

## YAGNI
An option's scope needs evidence it is needed now: the user's stated need, a consumer or code path that breaks without it, or a measured problem. "Might need later", "for flexibility", "when we scale" do not count. An option that only works with the speculative part removed is presented reduced, with a note of what was cut; never as two options.

## Output
Render a section only when it has content.

```markdown
## Options

### 1. {name}
{What it does, two or three sentences.}
- **Cost:** {files, dependencies, operational surface}
- **Breaks first:** {the failure that shows up soonest}
- **Right when:** {the condition that makes this the answer}

### 2. …

## Recommendation
{Option N, one sentence of why.}

## Open questions
- {question}: {which option each answer implies}
```
