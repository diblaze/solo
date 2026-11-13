# skill-loading Specification

## Purpose
How a skill names the scripts it runs, which of its calls run without a permission prompt, what repository state it shows as it loads, and how its description reads in the skill listing.

## Requirements

### Requirement: Skill scripts run by exact path
The system SHALL name every script a skill runs, its own or another skill's, by a path the skill loader expands to the script's absolute location, so nothing is inferred from a base directory.

#### Scenario: Script path is exact
- **GIVEN** a skill step that runs one of the plugin's scripts
- **WHEN** the skill loads, from an installed plugin or from a checkout
- **THEN** the step's command starts with the expanded skill directory and names the script, and no step tells the model to resolve a path relative to a base directory

### Requirement: Only read-only calls are pre-approved
The system SHALL run a skill's read-only script calls and its load-time reads without a permission prompt, and SHALL keep the prompt for every script that writes local state, writes to the forge, or runs a caller-supplied command.

#### Scenario: Read-only script runs without a prompt
- **GIVEN** default permission settings
- **WHEN** a skill validates a change, reads an issue, lists issues or milestones, or checks the directory map, using the command its step names
- **THEN** the call runs without a permission prompt

#### Scenario: State-changing script still asks
- **GIVEN** default permission settings
- **WHEN** a skill creates a change, sets a change's status, creates the tracking issue, writes an issue or milestone, checks every commit with a supplied command, folds specs, opens a PR or merges one
- **THEN** Claude Code asks before the call runs, including an issue write whose command starts like a pre-approved issue list, and no skill pre-approves anything beyond its listed read-only calls, in any frontmatter form

### Requirement: Branch state shown at load
The system SHALL show the repository's branch and working-tree state when execute or pr-ready loads, without a tool call, and SHALL still load those skills when the session directory is not a work tree.

#### Scenario: Branch state shown at start
- **GIVEN** a git repository as the session directory
- **WHEN** execute or pr-ready is invoked
- **THEN** the skill text already holds the output of `git status --short --branch` and the call ran without a prompt

#### Scenario: Invoked outside a repository
- **GIVEN** a session directory that is not a work tree (outside any repository, or the root of a bare-repository worktree layout)
- **WHEN** execute or pr-ready is invoked
- **THEN** the skill loads with git's error in place of the branch state, and its first step tells Claude to move into a work tree

### Requirement: Descriptions list as written
The system SHALL give every skill and agent a description that leads with its use case, speaks in third person, and writes placeholders in square brackets.

#### Scenario: Placeholder shown as written
- **GIVEN** a description that names a change folder
- **WHEN** the skill listing renders it
- **THEN** the placeholder reads `[slug]`, not `&lt;slug&gt;`

#### Scenario: Description in third person
- **GIVEN** any skill or agent description
- **WHEN** it is injected into the system prompt
- **THEN** it contains no "you" or "your"

#### Scenario: Use case leads the description
- **GIVEN** a gate skill's description
- **WHEN** the listing truncates it
- **THEN** it starts with what the skill does, and its gate number comes after
