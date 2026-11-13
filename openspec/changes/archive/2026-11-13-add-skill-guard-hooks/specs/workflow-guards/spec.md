## ADDED Requirements

### Requirement: Approved change not committed on main
The system SHALL refuse an agent-run commit on the main or master branch when the commit carries the folder of an OpenSpec change whose Status is approved together with files outside `openspec/`, and SHALL tell the agent to switch to a new branch first.

#### Scenario: Change commit on main refused
- **GIVEN** a repository on branch main whose working tree holds a change folder with Status approved, and code changes outside `openspec/`
- **WHEN** the agent runs a commit with that folder staged, or names that folder in the same command as the commit, from that directory or through `cd <repo> &&` or `git -C <repo>`
- **THEN** the commit does not run and the agent is told to branch first

### Requirement: Commit guard leaves other work alone
The system SHALL let every command through unchanged that is not a commit of an approved change folder on main or master. This covers other repositories later in the same session, a repository that opts out through `git config solo.allowMainCommits true`, and the case where the guard cannot read its input.

#### Scenario: Commit on a branch allowed
- **GIVEN** the approved change folder staged on a branch other than main or master
- **WHEN** the agent commits
- **THEN** the commit runs

#### Scenario: Unrelated commit on main allowed
- **GIVEN** a repository on main that commits straight to main and whose working tree holds approved change folders, tracked and untracked
- **WHEN** the agent commits staged files outside every approved change folder
- **THEN** the commit runs

#### Scenario: Planning commit on main allowed
- **GIVEN** a repository on main whose approved change folder is staged with no file outside `openspec/`
- **WHEN** the agent commits
- **THEN** the commit runs

#### Scenario: Repository opted out
- **GIVEN** a repository on main with `git config solo.allowMainCommits true`, whose approved change folder and code are staged
- **WHEN** the agent commits
- **THEN** the commit runs

#### Scenario: Other commands pass
- **GIVEN** a repository on main with an approved change folder staged, or a working directory outside any git repository
- **WHEN** the agent runs a command that is not a commit
- **THEN** the command runs

#### Scenario: Guard fault lets the command run
- **GIVEN** hook input the guard cannot parse
- **WHEN** the guard runs
- **THEN** it exits without blocking and the command runs
