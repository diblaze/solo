# pr-open Specification

## Purpose
Opening a pull request from a prepared branch: the PR carries a type label derived from its commits and is assigned to the person opening it, the repo gets the label when it lacks one, re-running updates the existing PR instead of duplicating it, and the body is checked for the issue it must close.

## Requirements

### Requirement: PR type label follows the commit subjects
The system SHALL label the pull request `type:feat` when any commit subject ahead of the base starts with `feat` (optionally scoped or marked breaking), else `type:bug` when any starts with `fix`, else `type:chore`.

#### Scenario: Feature commit present
- **GIVEN** a branch ahead of base whose subjects are `docs(spec): fold x`, `fix(a): b` and `feat(a)!: c`
- **WHEN** the pull request is opened
- **THEN** it carries exactly the label `type:feat`

#### Scenario: Fix without feature
- **GIVEN** a branch whose subjects are `fix(a): b` and `docs: c`
- **WHEN** the pull request is opened
- **THEN** it carries exactly the label `type:bug`

#### Scenario: Neither feature nor fix
- **GIVEN** a branch whose subjects are `docs(spec): fold x` and `chore: y`
- **WHEN** the pull request is opened
- **THEN** it carries exactly the label `type:chore`

### Requirement: PR is assigned to its opener
The system SHALL assign the pull request to the authenticated user and print the PR URL.

#### Scenario: New PR assigned
- **GIVEN** a branch with commits ahead of base and no open pull request
- **WHEN** the pull request is opened with a title and body
- **THEN** the branch is pushed with upstream tracking, the PR is created against the given base with that title, body, type label and the opener as assignee, and its URL is printed

### Requirement: Missing type label is created first
The system SHALL create the derived `type:*` label with a fixed colour and description when the repository lacks it, and SHALL leave an existing label untouched.

#### Scenario: Label absent in repository
- **GIVEN** the repository has no `type:feat` label
- **WHEN** a feature branch is opened as a pull request
- **THEN** `type:feat` is created before the PR is labelled

#### Scenario: Label already present
- **GIVEN** the repository has a `type:chore` label with its own colour
- **WHEN** a chore branch is opened as a pull request
- **THEN** no label is created or modified

### Requirement: Re-run updates the open PR
The system SHALL, when the branch already has an open pull request, push with lease protection and set that PR's base, title, body, type label (removing any other `type:*` label) and assignee instead of creating another.

#### Scenario: Existing open PR
- **GIVEN** the branch already has open pull request 7
- **WHEN** the pull request is opened again
- **THEN** the push uses force-with-lease, PR 7 gets the given base, title and body, gains the type label and loses any other `type:*` label, gains the opener as assignee, no new PR is created, and PR 7's URL is printed

### Requirement: Body closes the archived change's issue
The system SHALL refuse to open the pull request when the branch adds an archived change whose `Issue:` line names an issue `owner/repo#n` and the body lacks `Closes owner/repo#n`, or whose `Issue:` line is neither `owner/repo#n` nor `none`.

#### Scenario: Body missing Closes
- **GIVEN** the branch adds `openspec/changes/archive/*/proposal.md` with `Issue: owner/repo#12` and the body has no `Closes owner/repo#12`
- **WHEN** the pull request is opened
- **THEN** nothing is pushed or created and the error names `Closes owner/repo#12`

#### Scenario: Body carries Closes
- **GIVEN** the same archived change and a body containing `Closes owner/repo#12`
- **WHEN** the pull request is opened
- **THEN** the PR is created

#### Scenario: Closes of another issue does not count
- **GIVEN** the branch adds an archived change with `Issue: owner/repo#1` and the body only has `Closes owner/repo#12`
- **WHEN** the pull request is opened
- **THEN** nothing is pushed or created and the error names `Closes owner/repo#1`

#### Scenario: Run from a subdirectory
- **GIVEN** the same archived change with `Issue: owner/repo#12`, a body without it, and the script started from a subdirectory
- **WHEN** the pull request is opened
- **THEN** the check still runs and nothing is created

#### Scenario: Malformed Issue line refused
- **GIVEN** the branch adds an archived change with `Issue: #12`
- **WHEN** the pull request is opened with any body
- **THEN** nothing is pushed or created and the error names the `Issue:` line

#### Scenario: Archived change without issue
- **GIVEN** the branch adds an archived change with `Issue: none`
- **WHEN** the pull request is opened with any body
- **THEN** the PR is created

### Requirement: Preconditions are checked before any remote action
The system SHALL refuse, without pushing or calling the forge, when the current branch is the base, when no commits are ahead of the base, when the working tree is not clean, or when title or body file is missing.

#### Scenario: On the base branch
- **GIVEN** the current branch is the base
- **WHEN** opening is attempted
- **THEN** it exits non-zero naming the branch and nothing is pushed

#### Scenario: No commits ahead
- **GIVEN** a branch at the same commit as base
- **WHEN** opening is attempted
- **THEN** it exits non-zero and nothing is pushed

#### Scenario: Dirty working tree
- **GIVEN** a branch ahead of base with an uncommitted change
- **WHEN** opening is attempted
- **THEN** it exits non-zero naming the dirty tree and nothing is pushed

#### Scenario: Missing title or body
- **GIVEN** a valid branch
- **WHEN** opening is attempted without `--title` or without `--body-file`
- **THEN** it exits non-zero with a usage line and nothing is pushed

### Requirement: Dry run previews without remote changes
The script SHALL accept `--dry-run`, run every precondition and body check, print each `git push` and `gh` write command it would run (label create, pr create or pr edit) with its resolved label, and SHALL NOT push or call any `gh` write command.

#### Scenario: Dry run on a new branch
- **GIVEN** a clean feature branch with a `feat:` commit ahead of `main` and no open PR
- **WHEN** `open-pr.sh main --title t --body-file b --dry-run` runs
- **THEN** it exits 0, prints a `gh pr create … --label type:feat --assignee @me` line, the branch is not on the remote, and no `gh` write command was called
