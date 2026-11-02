# pr-merge Specification

## Purpose
Merging an open pull request by rebase only: squash switched off, stacked child pull requests moved to the merged base after the merge and before the branch is deleted, the local base brought up to date, and a dry run that shows every write.

## Requirements

### Requirement: Pull requests merge by rebase only
The system SHALL merge with rebase and then delete the head branch, never squash or merge commit, and SHALL switch squash merging off in the repository before the merge when it is allowed. Once the merge succeeded, a failed branch delete SHALL be reported as a warning and SHALL NOT fail the run.

#### Scenario: Rebase merge deletes the branch
- **GIVEN** open pull request 5 from `feat/x` into `main` and a repository that allows rebase and not squash
- **WHEN** it is merged
- **THEN** exactly one merge call is made, with `--rebase`, the head branch `feat/x` is deleted after it, and no repository setting is changed

#### Scenario: Branch delete failure warns
- **GIVEN** open pull request 5 from `feat/x` whose merge succeeds and whose branch delete fails
- **WHEN** it is merged
- **THEN** it exits 0 after one merge call and warns that deleting `feat/x` failed

#### Scenario: Squash merging switched off first
- **GIVEN** open pull request 5 and a repository that allows squash merging
- **WHEN** it is merged
- **THEN** squash merging is disabled before the merge call

### Requirement: Stacked pull requests are retargeted first
The system SHALL, after the merge succeeded and before the head branch is deleted, move every open pull request whose base is the head branch onto the merged pull request's base, and SHALL print for each the command that rebases it past the merged head commit. A failed merge SHALL leave every child pull request untouched.

#### Scenario: Child PR retargeted
- **GIVEN** open pull request 5 from `feat/x` into `main` at head commit `abc123`, and open pull request 6 based on `feat/x`
- **WHEN** pull request 5 is merged
- **THEN** pull request 6 gets base `main` after the merge call and before the branch delete, and the output names pull request 6 and `git rebase --onto origin/main abc123`

#### Scenario: Failed merge leaves children untouched
- **GIVEN** open pull request 5 from `feat/x` whose merge call fails, and open pull request 6 based on `feat/x`
- **WHEN** it is merged
- **THEN** it exits non-zero, pull request 6 is not retargeted, no rebase step is printed and `feat/x` is not deleted

### Requirement: Merge refuses before any write
The system SHALL refuse, without any forge write, a pull request number that is not a positive integer, a pull request that is not open, a draft pull request, a pull request that conflicts with its base or whose merge state is blocked, dirty, behind or unknown, and a repository that does not allow rebase merging.

#### Scenario: Bad PR number refused
- **GIVEN** any repository
- **WHEN** the pull request `5; touch INJECTED` is merged
- **THEN** it exits 2, the forge is not called and no file named `INJECTED` exists

#### Scenario: PR not open refused
- **GIVEN** pull request 5 is closed
- **WHEN** it is merged
- **THEN** it exits non-zero naming its state and no forge write is made

#### Scenario: Unmergeable PR refused
- **GIVEN** open pull request 5 that is a draft, conflicts with its base, or has merge state blocked, dirty, behind or unknown, in a repository that allows squash merging, with open child pull request 6
- **WHEN** it is merged
- **THEN** it exits non-zero naming the reason, squash merging is not switched off, pull request 6 is not retargeted and no merge call is made

#### Scenario: Rebase merging disabled refused
- **GIVEN** open pull request 5 and a repository that does not allow rebase merging
- **WHEN** it is merged
- **THEN** it exits non-zero naming rebase merging and no forge write is made

### Requirement: Local base follows the merge
The system SHALL, after the merge, fetch the base branch and fast-forward it when it is the checked-out branch. Once the remote merge succeeded, a failed fetch or fast-forward SHALL be reported as a warning and SHALL NOT fail the run.

#### Scenario: Local base fast-forwarded
- **GIVEN** `main` checked out locally and behind the remote once pull request 5 merges
- **WHEN** pull request 5 is merged
- **THEN** local `main` points at the remote `main` commit

#### Scenario: Local update failure after merge warns
- **GIVEN** `main` checked out locally with a commit the remote lacks, so it cannot fast-forward once pull request 5 merges
- **WHEN** pull request 5 is merged
- **THEN** it exits 0 after one merge call, warns that local `main` was not fast-forwarded, and local `main` is unchanged

### Requirement: Merge dry run previews without remote changes
The system SHALL accept `--dry-run`, run every refusal check, print each settings change, merge, retarget and branch delete it would make, in that order, and SHALL NOT call any forge write or change local branches.

#### Scenario: Merge dry run
- **GIVEN** open pull request 5, a repository that allows squash, and open child pull request 6
- **WHEN** it is merged with `--dry-run`
- **THEN** it exits 0, prints the squash switch-off, `gh pr merge 5 --repo o/r --rebase`, the retarget of pull request 6 and the delete of `feat/x` in that order, and no forge write is made
