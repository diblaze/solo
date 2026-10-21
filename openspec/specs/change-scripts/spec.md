# change-scripts Specification

## Purpose
The workflow scripts that create, validate, re-status and fold an OpenSpec change: which inputs they accept, which directory they act on, when they refuse, which spec-tool version they run, and how the fold commit names the issue it closes.

## Requirements

### Requirement: Change slug is validated
The system SHALL refuse any change slug that is not lowercase kebab-case, with exit code 2, before reading or writing any file or invoking the spec tool.

#### Scenario: Traversal slug refused
- **GIVEN** a repository with an `openspec/` folder
- **WHEN** any change script is given the slug `../../x`
- **THEN** it exits 2 with a message naming kebab-case, and the spec tool is not invoked

#### Scenario: Flag-like slug refused
- **GIVEN** a repository with an `openspec/` folder
- **WHEN** any change script is given the slug `--help`
- **THEN** it exits 2 and the spec tool is not invoked

### Requirement: Issue reference is validated
The system SHALL accept an issue reference only in the form `owner/repo#n` or the word `none`, both as the status argument and as the proposal's `Issue:` header.

#### Scenario: Injected issue refused
- **GIVEN** a change with a proposal
- **WHEN** its status is set with the issue `o/r#1; touch INJECTED|e;s|a|b`
- **THEN** it exits 2, the proposal is unchanged and no file named `INJECTED` exists

#### Scenario: Valid issue recorded
- **GIVEN** a change with a proposal
- **WHEN** its status is set to approved with the issue `o/r#12`
- **THEN** the proposal reads `Status: approved` and `Issue: o/r#12`

#### Scenario: Malformed Issue header refused
- **GIVEN** a change whose proposal says `Issue: #12`
- **WHEN** the change is validated
- **THEN** validation fails and names the `Issue:` line

#### Scenario: Fold refuses a malformed Issue line
- **GIVEN** a done change whose proposal says `Issue: #12`, or has no `Issue:` line, and a clean tree
- **WHEN** it is folded
- **THEN** it exits non-zero, names the `Issue:` line, and nothing is archived or committed

### Requirement: Scripts act on the repository root
The system SHALL resolve every change path against the root of the current git repository, whatever the working directory, and SHALL refuse to run outside a git repository.

#### Scenario: Run from a subdirectory
- **GIVEN** a repository and a working directory one level below its root
- **WHEN** a change is created, validated and re-statused from there
- **THEN** the change exists under the root's `openspec/changes/` and no `openspec/` folder appears in the subdirectory

#### Scenario: Run under an inherited GIT_DIR
- **GIVEN** a working directory one level below the root and `GIT_DIR` exported without `GIT_WORK_TREE`, as `git rebase --exec` does in a linked worktree
- **WHEN** a change is created from there
- **THEN** the change exists under the root's `openspec/changes/` and no `openspec/` folder appears in the subdirectory

#### Scenario: Outside a git repository refused
- **GIVEN** a working directory that is not inside a git repository
- **WHEN** a change is created
- **THEN** it exits non-zero and no `openspec/` folder is created

### Requirement: Done requires a task list
The system SHALL refuse to mark a change done, or to fold it, when its `tasks.md` is missing or has an unticked box.

#### Scenario: Done without tasks.md refused
- **GIVEN** a change with a proposal and no `tasks.md`
- **WHEN** its status is set to done
- **THEN** it exits non-zero, names `tasks.md`, and the proposal still has its old status

#### Scenario: Fold without tasks.md refused
- **GIVEN** a change marked done with no `tasks.md` and a clean tree
- **WHEN** it is folded
- **THEN** it exits non-zero, names `tasks.md`, and nothing is archived or committed

### Requirement: Fold commit closes the issue by full reference
The system SHALL write `Closes owner/repo#n` into the spec-fold commit when the proposal names an issue, and no closing line when it says `none`.

#### Scenario: Fold closes owner/repo issue
- **GIVEN** a done change whose proposal says `Issue: o/r#12`
- **WHEN** it is folded
- **THEN** the fold commit message contains `Closes o/r#12`

#### Scenario: Fold without issue
- **GIVEN** a done change whose proposal says `Issue: none`
- **WHEN** it is folded
- **THEN** the fold commit message has no `Closes` line

### Requirement: Missing search tool is named
The system SHALL exit 127 with a message naming ripgrep when `rg` is not on the path, before doing anything else.

#### Scenario: rg absent
- **GIVEN** a path without `rg`
- **WHEN** any change script runs
- **THEN** it exits 127 and the message names `rg`

### Requirement: Spec tool version is pinned
The system SHALL run one exact spec-tool version: an installed CLI only when it reports that version, otherwise the package runner fetching that exact version, and exit 127 when neither is available.

#### Scenario: Matching global CLI used
- **GIVEN** an installed spec CLI reporting the pinned version
- **WHEN** a change is validated
- **THEN** the installed CLI runs and the package runner is not called

#### Scenario: Mismatched global CLI bypassed
- **GIVEN** an installed spec CLI reporting another version
- **WHEN** a change is validated
- **THEN** the package runner runs the pinned version and a note on stderr names both versions

#### Scenario: No spec tool available
- **GIVEN** a path with neither the spec CLI nor the package runner
- **WHEN** a change is validated
- **THEN** it exits 127
