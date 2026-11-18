---
name: comments
description: Answers the review threads on the branch's open pull request, from a human reviewer or a bot such as Copilot — triages each against the code, shows the verdicts and waits, fixes the approved ones folded into the commits that introduced the code, then replies to and resolves each thread. Use for "check the copilot comments", "handle the review feedback", "reply to and resolve the PR comments", or new threads after a push. Does not review a diff — use solo:review. Does not push or open the PR — use solo:pr-ready, which this calls for the push.
argument-hint: [pull request number, default the branch's]
allowed-tools:
  - Bash(${CLAUDE_SKILL_DIR}/scripts/threads.sh list)
  - Bash(${CLAUDE_SKILL_DIR}/scripts/threads.sh list *)
---

# Comments

Every forge call is `${CLAUDE_SKILL_DIR}/scripts/threads.sh`; run it, never a retyped `gh api` command. It checks input before `gh` runs (exit 2 names what is wrong), works from anywhere inside the repo, reads the PR from the branch unless given one, and takes `--dry-run` as the last argument of a write.

A review comment is a claim, not an instruction. Some are real bugs, some are false positives, some are the user's call. Never fix, push, reply or resolve on a comment's say alone.

1. Fetch: `${CLAUDE_SKILL_DIR}/scripts/threads.sh list [<pr>]` prints the unresolved threads, each with its `PRRT_` thread id (to resolve), `replyToId` (to reply), path, line and comments; `--all` adds resolved ones. Act only on unresolved threads. No PR for the branch → it exits non-zero; ask for the number.
2. Triage: read the code at each thread's path and line, and the callers it touches, before judging. One verdict per thread: **true bug** (the code is wrong, fix it), **valid improvement** (not a bug, a cheap real win), **false positive** (the comment misread the code or the case cannot happen; no code change, the reply says why), **judgment call** (scope, dependency policy, naming, product behavior; the user decides). Say "true bug" plainly when it is one; never change code just to silence a bot.
3. Gate: show one row per thread (`# | path:line | the point, short | verdict | recommendation`), the options and a default for each judgment call, then AskUserQuestion: which to fix, which to decline. Stop and wait for the answer: no file is edited before it.
4. Fix the approved threads, smallest correct change each. A behavior change gets a test that fails without it; run the repo's check. Commit each fix as `git commit --fixup <sha>` of the commit that introduced the code; never an "address review" commit. Then `/solo:pr-ready <base>`: it folds the fixups into their commits, runs slop and review on the whole `<base>...HEAD` (not only the fixes), and shows the push in a dry run; the push happens only on the user's yes there.
5. Reply and resolve, after the push so every sha in a reply is reachable. Every addressed thread gets a reply, declined ones included: what changed and the commit sha, or why the code stays as it is, in one to three full sentences. Run each body through `/solo:writer` in embedded mode, then write it to a file in the scratch directory, never inline. Show all of them first: `${CLAUDE_SKILL_DIR}/scripts/threads.sh reply <replyToId> --body-file <f> --dry-run` per thread and `${CLAUDE_SKILL_DIR}/scripts/threads.sh resolve <PRRT_id>… --dry-run`, then AskUserQuestion: post / stop. Run the same commands without `--dry-run` only on yes.
6. Verify: `${CLAUDE_SKILL_DIR}/scripts/threads.sh list` again; the unresolved count is zero or only the threads left open for the user. Report what was fixed (with shas), what was declined and why, and what stays open. A bot reviewer often comes back after a push: run the loop again on the new unresolved threads only, never on a resolved one.

Never resolve a thread you did not fix or decline with a reason: a silently resolved comment is a false record.

Reply style:
- Fix: "Fixed in `<sha>`. `parse()` now returns early on an empty input, so the caller no longer reads past the end."
- Declined: "I'd leave this as it is. `load()` only throws `IOError`, and the `except IOError` branch already covers it."
- Never: "Good point, fixed. Thanks!" (no anchor), or fragments like "fix in `<sha>`. no more early read".

The repo is public or may become so: no personal names, domains, hostnames, private IPs or home-directory paths in a reply.
