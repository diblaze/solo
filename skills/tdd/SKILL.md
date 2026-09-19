---
name: tdd
description: Red-green-refactor loop with an enforced observed-failure gate. Use when a behavior is worth driving from tests — parsers, money/auth paths, state machines, anything with branches. Does not plan the feature — use solo:plan. Does not restructure existing code without new behavior — use solo:refactor. Does not hunt a bug — use solo:investigate.
argument-hint: <behavior to build>
---

# TDD

Only for logic with real branching. A one-liner or a wiring change does not get a loop — YAGNI applies to tests too.

## 0. Behavior list
Before any code: list the behaviors as one line each, ordered simplest first (empty/zero/null → one → many → error → boundary). Show the list. It is the todo list for the loop.

## 1. Red — observed failure gate
Write ONE test for the next behavior. Run it. Paste the actual failure output. A test you did not watch fail proves nothing: no failure output, no green step.
Failure must be the assertion failing, not an import error or typo. Fix the harness first if so.

## 2. Green
Smallest change that passes. Hardcode if that is genuinely the smallest correct step for this behavior; the next test forces generality. Run the whole file's tests, not just the new one.

## 3. Refactor
Only with the bar green. Deletion over addition. No abstraction until a third case demands it. Re-run after every edit.

Repeat 1-3 per behavior. Stop when the list is done — not when the code "feels" done.

## Stack
Read the repo's `AGENTS.md` `## Coding standard` first (written by `/solo:standard`) — it names the runner, the check command, and the skip policy. No such section → the lockfile is law (`uv.lock` → `uv run pytest -q`, `pnpm-lock.yaml` → `pnpm test`, `yarn.lock` → `yarn test`, `package-lock.json` → `npm test`, `go.mod` → `go test ./...`, `pubspec.yaml` → `flutter test`), and suggest running `/solo:standard` afterwards.
Framework idiom questions go to Context7, not memory. Test the public surface; no mocks for code you own, stubs only at the trust boundary (network, clock, filesystem).

## Done
Report: behaviors covered, the one command that runs them, and any behavior deliberately left untested with the reason. Placeholders (`test.skip`, `.only`, empty assert) are blockers, not notes.
