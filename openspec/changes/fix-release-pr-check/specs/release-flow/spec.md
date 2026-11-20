## MODIFIED Requirements
### Requirement: Release PR runs the required check
The system SHALL run the required `check` job on the release PR head once a maintainer approves the workflow run that GitHub holds for that PR, and SHALL start no other CI run for it.

#### Scenario: Release PR gets the required check
- **GIVEN** the release workflow just opened or updated the release PR and its CI run waits for approval
- **WHEN** a maintainer approves that run and its checks are listed
- **THEN** a `check` run exists for the PR head commit and the PR can merge once it passes

#### Scenario: Unapproved release PR stays blocked
- **GIVEN** the release workflow just opened or updated the release PR
- **WHEN** nobody approves the waiting CI run
- **THEN** the release workflow has started no CI run of its own and the PR cannot merge
