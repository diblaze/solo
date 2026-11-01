## Purpose
Merging an open pull request by rebase only: squash switched off, stacked child pull requests moved to the merged base before the branch is deleted, the local base brought up to date, and a dry run that shows every write.

## ADDED Requirements

### Requirement: Pull requests merge by rebase only
The system SHALL merge with rebase and delete the head branch, never squash or merge commit, and SHALL switch squash merging off in the repository before the merge when it is allowed.

#### Scenario: Rebase merge deletes the branch
- **GIVEN** open pull request 5 from `feat/x` into `main` and a repository that allows rebase and not squash
- **WHEN** it is merged
- **THEN** exactly one merge call is made, with `--rebase --delete-branch`, and no repository setting is changed

#### Scenario: Squash merging switched off first
- **GIVEN** open pull request 5 and a repository that allows squash merging
- **WHEN** it is merged
- **THEN** squash merging is disabled before the merge call

### Requirement: Stacked pull requests are retargeted first
The system SHALL, before merging, move every open pull request whose base is the head branch being merged onto the merged pull request's base, and SHALL print for each the command that rebases it past the merged head commit.

#### Scenario: Child PR retargeted
- **GIVEN** open pull request 5 from `feat/x` into `main` at head commit `abc123`, and open pull request 6 based on `feat/x`
- **WHEN** pull request 5 is merged
- **THEN** pull request 6 gets base `main` before the merge call, and the output names pull request 6 and `git rebase --onto origin/main abc123`

### Requirement: Merge refuses before any write
The system SHALL refuse, without any forge write, a pull request number that is not a positive integer, a pull request that is not open, and a repository that does not allow rebase merging.

#### Scenario: Bad PR number refused
- **GIVEN** any repository
- **WHEN** the pull request `5; touch INJECTED` is merged
- **THEN** it exits 2, the forge is not called and no file named `INJECTED` exists

#### Scenario: PR not open refused
- **GIVEN** pull request 5 is closed
- **WHEN** it is merged
- **THEN** it exits non-zero naming its state and no forge write is made

#### Scenario: Rebase merging disabled refused
- **GIVEN** open pull request 5 and a repository that does not allow rebase merging
- **WHEN** it is merged
- **THEN** it exits non-zero naming rebase merging and no forge write is made

### Requirement: Local base follows the merge
The system SHALL, after the merge, fetch the base branch and fast-forward it when it is the checked-out branch.

#### Scenario: Local base fast-forwarded
- **GIVEN** `main` checked out locally and behind the remote once pull request 5 merges
- **WHEN** pull request 5 is merged
- **THEN** local `main` points at the remote `main` commit

### Requirement: Merge dry run previews without remote changes
The system SHALL accept `--dry-run`, run every refusal check, print each settings change, retarget and merge it would make, and SHALL NOT call any forge write or change local branches.

#### Scenario: Merge dry run
- **GIVEN** open pull request 5, a repository that allows squash, and open child pull request 6
- **WHEN** it is merged with `--dry-run`
- **THEN** it exits 0, prints the squash switch-off, the retarget of pull request 6 and `gh pr merge 5 --rebase --delete-branch`, and no forge write is made
