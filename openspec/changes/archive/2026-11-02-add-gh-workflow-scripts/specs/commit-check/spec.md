## Purpose
Checking that each commit a branch adds over its base passes the project check on its own, in a throwaway worktree that leaves the caller's working tree, index and branch untouched.

## ADDED Requirements

### Requirement: Every commit is checked on its own
The system SHALL run the given check at each commit between the base and the current commit, oldest first, report each passing commit, and stop at the first failing commit, exiting non-zero and naming its hash. It SHALL refuse with exit 2 when no check command is given, and exit non-zero when no commits are ahead of the base.

#### Scenario: Every commit passes
- **GIVEN** a branch with three commits ahead of `main`, each passing the check
- **WHEN** the commits are checked against `main`
- **THEN** it exits 0 and reports the three commits oldest first

#### Scenario: Failing commit named
- **GIVEN** a branch with three commits ahead of `main` where only the second fails the check
- **WHEN** the commits are checked against `main`
- **THEN** it exits non-zero, names the second commit's hash, and the third commit is not checked

#### Scenario: Missing check refused
- **GIVEN** a branch with commits ahead of `main`
- **WHEN** the commits are checked against `main` with no check command
- **THEN** it exits 2 with a usage line

#### Scenario: No commits ahead refused
- **GIVEN** a branch at the same commit as `main`
- **WHEN** the commits are checked against `main`
- **THEN** it exits non-zero and the check never runs

### Requirement: Check runs outside the caller's tree
The system SHALL run the check in a temporary worktree that is removed on every exit, and SHALL leave the caller's current branch, commit, index and working files unchanged.

#### Scenario: Caller's tree untouched after a failure
- **GIVEN** a branch with an uncommitted edit and a check that writes a file into its working directory and fails on the first commit
- **WHEN** the commits are checked
- **THEN** no extra worktree is registered, the temporary directory is gone, and the caller's branch, commit and `git status` output are as before
