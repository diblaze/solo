## Purpose
Reading a GitHub issue with each author marked collaborator or outsider, and creating, labelling and recording the tracking issue when a change is approved.

## ADDED Requirements

### Requirement: Issue authors are marked by standing
The system SHALL print the issue's URL, title, body, author, comments, labels, parent, blocked-by and sub-issues, followed by one line per distinct author of the issue and its comments naming that author `collaborator` when the repository confirms them as a collaborator and `outsider` otherwise, including when the lookup fails.

#### Scenario: Collaborator and outsider marked
- **GIVEN** an issue written by `alice`, a collaborator, with one comment by `alice` and one by `mallory`, whose collaborator lookup fails
- **WHEN** the issue is read
- **THEN** the issue JSON is printed, then exactly the lines `collaborator alice` and `outsider mallory`

#### Scenario: Bad issue argument refused
- **GIVEN** any repository
- **WHEN** the issue `1; touch INJECTED` is read
- **THEN** it exits 2, the forge is not called and no file named `INJECTED` exists

### Requirement: Approved change gets a tracking issue
The system SHALL, when a change is approved and its proposal says `Issue: none`, create an issue titled with the first What Changes line, with a body that copies the proposal's `## Why` and `## What Changes` sections and ends with `Change: openspec/changes/<slug>/`, the type label and the approver as assignee, then record it as `Issue: owner/repo#n` with `Status: approved`. A proposal that already names an issue SHALL be approved without creating another.

#### Scenario: Issue created on approval
- **GIVEN** a draft change `add-x` with `Issue: none`, Why text `Need x.` and What Changes lines `- Add x` and `- Document x`
- **WHEN** it is approved and the forge returns issue `https://github.com/o/r/issues/5`
- **THEN** one issue is created with title `Add x`, a body holding `## Why`, `Need x.`, `## What Changes`, `- Add x`, `- Document x` and ending with `Change: openspec/changes/add-x/`, label `type:feat` and assignee `@me`, and the proposal reads `Status: approved` and `Issue: o/r#5`

#### Scenario: Change already tracked
- **GIVEN** a draft change whose proposal says `Issue: o/r#3`
- **WHEN** it is approved
- **THEN** no issue is created and the proposal reads `Status: approved` and `Issue: o/r#3`

#### Scenario: No What Changes line refused
- **GIVEN** a draft change with `Issue: none` and no list item under What Changes
- **WHEN** it is approved
- **THEN** it exits non-zero naming What Changes, no issue is created and the proposal still says `Status: draft`

### Requirement: Issue type label follows the slug
The system SHALL label the tracking issue `type:bug` for a slug starting `fix-`, `type:feat` for one starting `add-`, and `type:chore` otherwise, and SHALL create that label first when the repository lacks it.

#### Scenario: Type label follows the slug prefix
- **GIVEN** draft changes `fix-y` and `tidy-z`, both with `Issue: none`, and both labels present
- **WHEN** each is approved
- **THEN** `fix-y`'s issue carries `type:bug`, `tidy-z`'s carries `type:chore`, and no label is created

#### Scenario: Issue label absent in repository
- **GIVEN** the repository has no `type:feat` label and a draft change `add-x` with `Issue: none`
- **WHEN** it is approved
- **THEN** `type:feat` is created before the issue

### Requirement: Issue creation dry run
The system SHALL accept `--dry-run` on approval, print each forge write and the status update it would make, and SHALL NOT call any forge write or change the proposal.

#### Scenario: Approval dry run
- **GIVEN** a draft change `add-x` with `Issue: none`
- **WHEN** it is approved with `--dry-run`
- **THEN** it exits 0, prints a `gh issue create … --label type:feat --assignee @me` line, no issue is created and the proposal is unchanged
