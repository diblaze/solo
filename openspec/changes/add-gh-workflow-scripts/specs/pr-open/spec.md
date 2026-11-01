## MODIFIED Requirements

### Requirement: Preconditions are checked before any remote action
The system SHALL refuse, without pushing or calling the forge, when the current branch is the base, when no commits are ahead of the base, when a tracked file has staged or unstaged changes, or when title or body file is missing. Untracked files SHALL NOT block opening.

#### Scenario: On the base branch
- **GIVEN** the current branch is the base
- **WHEN** opening is attempted
- **THEN** it exits non-zero naming the branch and nothing is pushed

#### Scenario: No commits ahead
- **GIVEN** a branch at the same commit as base
- **WHEN** opening is attempted
- **THEN** it exits non-zero and nothing is pushed

#### Scenario: Dirty working tree
- **GIVEN** a branch ahead of base with an uncommitted change to a tracked file, staged or not
- **WHEN** opening is attempted
- **THEN** it exits non-zero naming the dirty tree and nothing is pushed

#### Scenario: Untracked file allowed
- **GIVEN** a clean branch ahead of base plus an untracked, non-ignored file
- **WHEN** opening is attempted
- **THEN** the PR is created and the untracked file is not pushed

#### Scenario: Missing title or body
- **GIVEN** a valid branch
- **WHEN** opening is attempted without `--title` or without `--body-file`
- **THEN** it exits non-zero with a usage line and nothing is pushed
