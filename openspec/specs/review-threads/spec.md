# review-threads Specification

## Purpose
Answering the review threads on a pull request: how threads are listed with the ids needed to act on them, how a reply and a resolve reach the forge, which input is refused first, and the gate that keeps triage, fixes, replies and resolves in the user's hands.

## Requirements

### Requirement: Review threads listed
The system SHALL list the review threads of the current branch's pull request, or of a named one, read from the pull request's base repository, printing a header with the total and unresolved counts and, per thread, its thread id, resolved and outdated state, path, line, the first comment's id and each comment as `author: body`; only unresolved threads unless all are asked for.

#### Scenario: Unresolved threads listed
- **GIVEN** pull request 7 of `o/r` with one unresolved and one resolved thread
- **WHEN** its threads are listed
- **THEN** the forge is queried for owner `o`, repository `r` and number 7, the header reads 2 total and 1 unresolved, and only the unresolved thread is printed with its id, path, line, first comment id and comment

#### Scenario: All threads listed
- **GIVEN** the same pull request
- **WHEN** all its threads are listed
- **THEN** both threads are printed

### Requirement: Reply posted from a file
The system SHALL post a reply to the thread whose first comment has the given id, with the text of a given file, on the current branch's pull request or a named one.

#### Scenario: Reply posted from a file
- **GIVEN** pull request 7 of `o/r` and a file `b.md`
- **WHEN** a reply to comment 123 is posted with body file `b.md`
- **THEN** one reply to comment 123 of pull request 7 in `o/r` is created from `b.md`

### Requirement: Threads resolved by id
The system SHALL resolve each named review thread with its own forge call and print one `<id> resolved` line per thread.

#### Scenario: Threads resolved
- **GIVEN** unresolved threads `PRRT_a` and `PRRT_b`
- **WHEN** both are resolved
- **THEN** two resolve calls are made, one per thread, and the output is `PRRT_a resolved` then `PRRT_b resolved`

### Requirement: Thread input refused before the forge
The system SHALL exit 2 without calling the forge for an unknown operation or option, a pull request or comment number that is not a positive integer, a thread id that is not a review thread id, a reply without a body file or with one that does not exist, and a resolve with no thread.

#### Scenario: Bad thread input refused
- **GIVEN** a repository
- **WHEN** a reply names comment `abc`, a reply has no body file, a reply names a missing body file, a resolve names `123` or `PRRT_x; touch INJECTED`, a list names pull request `0`, or the operation is unknown
- **THEN** each exits 2, the forge is not called, and no `INJECTED` file exists

### Requirement: Branch without a pull request refused
The system SHALL exit non-zero, before any write, when the current branch has no pull request and none is named.

#### Scenario: Branch without a pull request refused
- **GIVEN** a branch with no pull request
- **WHEN** its threads are listed or a reply is posted
- **THEN** it exits non-zero and makes no write

### Requirement: Thread write dry run
The system SHALL accept `--dry-run` as the last argument of a reply or resolve, print each forge write it would make and, for a reply, the text of its body file, and SHALL NOT make any forge write; the pull request lookup still runs.

#### Scenario: Thread write dry run
- **GIVEN** pull request 7 of `o/r`
- **WHEN** a reply and a resolve run with `--dry-run`
- **THEN** stdout shows the reply and resolve calls and the reply's body text, and the forge log holds only the pull request lookup

### Requirement: Verdicts shown before any fix
The system SHALL read the code each unresolved thread points at, give each a verdict (true bug, valid improvement, false positive or judgment call), show every verdict with a recommendation and wait for the user's choice before it changes any file.

#### Scenario: Verdicts shown before any fix
- **GIVEN** a pull request with unresolved review threads
- **WHEN** the comments skill runs
- **THEN** it shows one verdict per thread and asks which to address before editing anything

### Requirement: Fixes fold into their commits
The system SHALL fold each approved fix into the commit that introduced the code it changes, never as a separate review commit, and SHALL push only through the pre-PR gate, on the user's yes.

#### Scenario: Fix folded into its commit
- **GIVEN** an approved fix to code from an earlier branch commit
- **WHEN** the fix is committed
- **THEN** it is a fixup squashed into that commit, and the push goes through the pre-PR gate's dry run and yes

### Requirement: Replies and resolves on a yes
The system SHALL show every reply and resolve with `--dry-run` and post them only on the user's yes, SHALL reply to every addressed thread, declined ones included, and SHALL resolve only threads it fixed or declined with a reason.

#### Scenario: Replies and resolves shown first
- **GIVEN** fixed and declined threads
- **WHEN** replies and resolves are due
- **THEN** their dry run is shown, they are posted only on a yes, and a thread left open is never resolved

### Requirement: Comments chosen for incoming review threads
The system SHALL route a request to answer and resolve review comments on a pull request to the comments skill, not to a fresh review or the pre-PR gate.

#### Scenario: Review thread request goes to comments
- **GIVEN** a request to go through a pull request's review comments, fix the valid ones, reply and resolve
- **WHEN** the skill is chosen
- **THEN** the comments skill fires, and review and pr-ready fire zero times
