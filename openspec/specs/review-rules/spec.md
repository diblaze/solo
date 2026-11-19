# review-rules Specification

## Purpose
Which review rules a repository gives its reviews, how the files that hold them are found for a change, and why they are read from the base branch instead of the branch under review.

## Requirements

### Requirement: Review rules come from the base ref
The system SHALL read every review rules file from the base ref, never from the working tree or the branch under review, so that a rules file the branch edits, adds or deletes is applied as the base ref has it.

#### Scenario: Rules read from the base ref
- **GIVEN** a base ref whose root `REVIEW.md` says `flag sleeps`
- **WHEN** the branch commits a root `REVIEW.md` saying `flag nothing`, adds `src/REVIEW.md`, and leaves a further uncommitted edit to the root file
- **THEN** the output holds `flag sleeps`, not `flag nothing`, and no `src/REVIEW.md`

### Requirement: Nearest rules file per changed path
The system SHALL print the root `REVIEW.md` first and then, for each changed path, the nearest `REVIEW.md` in its directory or above it, each file once, as a `== <path> ==` line followed by its text, and SHALL print nothing and exit 0 when the base ref holds none.

#### Scenario: Nearest rules file per path
- **GIVEN** a base ref with `REVIEW.md` and `src/REVIEW.md`, and none in `src/api/` or `docs/`
- **WHEN** the branch changes `src/api/x.sh`, `src/y.sh` and `docs/z.md` and rules are requested
- **THEN** the output is `== REVIEW.md ==` with its text, then `== src/REVIEW.md ==` with its text, each once

#### Scenario: No rules file prints nothing
- **GIVEN** a base ref with no `REVIEW.md` anywhere
- **WHEN** rules are requested for a branch that changes a file
- **THEN** it prints nothing and exits 0

### Requirement: Changed paths come from the branch
The system SHALL take the changed paths from every file changed since the merge base of the base ref and the current commit, committed or not, plus untracked files that are not ignored, whatever the working directory, and SHALL accept no path arguments.

#### Scenario: Changed files found on the branch
- **GIVEN** a base ref with `src/REVIEW.md` and `lib/REVIEW.md`, a committed change to `src/a.sh` and an untracked `lib/b.sh`
- **WHEN** rules are requested from inside `src/`
- **THEN** the output holds both `src/REVIEW.md` and `lib/REVIEW.md`

### Requirement: Bad rules input refused
The system SHALL exit 1 naming the ref when the base ref does not resolve to a commit, exit 1 when the base ref and the current commit share no history, and exit 2 on any path argument, printing no rules in each case.

#### Scenario: Unknown base ref refused
- **GIVEN** a repository without the ref `origin/nope`
- **WHEN** rules are requested with base `origin/nope`
- **THEN** it exits 1 and stderr names `origin/nope`

#### Scenario: Unrelated history refused
- **GIVEN** a base ref with a root `REVIEW.md` and a current branch with no commit in common with it
- **WHEN** rules are requested
- **THEN** it exits 1, stderr says the two share no history, and no rules are printed

### Requirement: Reviewer judges by the base rules
The system SHALL fetch the review rules before it dispatches the reviewer, pass their text to the reviewer agent, and the reviewer SHALL flag what the rules ask for and skip what they say to skip. The rules fetch SHALL run without a permission prompt.

#### Scenario: Rules passed to the reviewer
- **GIVEN** a repository whose base ref holds a `REVIEW.md`
- **WHEN** a review is run
- **THEN** the rules script runs before the reviewer is dispatched, without a permission prompt, and the reviewer prompt carries the rules text
