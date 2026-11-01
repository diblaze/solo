## ADDED Requirements

### Requirement: Fold needs a clean tree
The system SHALL refuse to fold, before archiving or committing, when a tracked file has staged or unstaged changes or an untracked, non-ignored file exists under `openspec/`; untracked files elsewhere SHALL NOT block the fold and SHALL NOT enter the fold commit.

#### Scenario: Fold refuses a tracked change
- **GIVEN** a done change and an uncommitted edit to a tracked file
- **WHEN** it is folded
- **THEN** it exits non-zero naming the tree, and nothing is archived or committed

#### Scenario: Fold refuses an untracked spec file
- **GIVEN** a done change and an untracked file inside its change folder
- **WHEN** it is folded
- **THEN** it exits non-zero naming the untracked file, and nothing is archived or committed

#### Scenario: Fold ignores an unrelated untracked file
- **GIVEN** a done change and an untracked file outside `openspec/`
- **WHEN** it is folded
- **THEN** the fold commit is made and does not contain that file
