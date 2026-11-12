# issue-tracking Specification

## Purpose
Reading a GitHub issue with each author marked collaborator or outsider, creating, typing and recording the tracking issue when a change is approved, and the upkeep of any issue: create, issue type, fields, dependencies, comments, close and reopen, listing, and milestones.

## Requirements

### Requirement: Issue authors are marked by standing
The system SHALL print the issue's URL, title, body, author, comments, labels, parent, blocked-by and sub-issues, followed by one line per distinct author of the issue and its comments naming that author `collaborator` when the repository confirms them as a collaborator and `outsider` otherwise, including when the lookup fails.

#### Scenario: Collaborator and outsider marked
- **GIVEN** an issue written by `alice`, a collaborator, with one comment by `alice` and one by `mallory`, whose collaborator lookup fails
- **WHEN** the issue is read
- **THEN** the issue JSON is printed, then exactly the lines `collaborator alice` and `outsider mallory`

#### Scenario: Issue on another host read
- **GIVEN** an issue at `https://forge.example.test/o/r/issues/7` written by `alice`, a collaborator
- **WHEN** the issue is read by that URL
- **THEN** the issue JSON is printed, then exactly the line `collaborator alice`, looked up in `o/r`

#### Scenario: Bad issue argument refused
- **GIVEN** any repository
- **WHEN** the issue `1; touch INJECTED` is read
- **THEN** it exits 2, the forge is not called and no file named `INJECTED` exists

### Requirement: Approved change gets a tracking issue
The system SHALL, when a change is approved and its proposal says `Issue: none`, create an issue titled with the first What Changes line, with a body that copies the proposal's `## Why` and `## What Changes` sections and ends with `Change: openspec/changes/<slug>/`, the forge's issue type and the approver as assignee, then record it as `Issue: owner/repo#n` with `Status: approved`. A proposal that already names an issue SHALL be approved without creating another.

#### Scenario: Issue created on approval
- **GIVEN** a draft change `add-x` with `Issue: none`, Why text `Need x.` and What Changes lines `- Add x` and `- Document x`
- **WHEN** it is approved and the forge returns issue `https://github.com/o/r/issues/5`
- **THEN** one issue is created with title `Add x`, a body holding `## Why`, `Need x.`, `## What Changes`, `- Add x`, `- Document x` and ending with `Change: openspec/changes/add-x/`, issue type `Feature` and assignee `@me`, and the proposal reads `Status: approved` and `Issue: o/r#5`

#### Scenario: Change already tracked
- **GIVEN** a draft change whose proposal says `Issue: o/r#3`
- **WHEN** it is approved
- **THEN** no issue is created and the proposal reads `Status: approved` and `Issue: o/r#3`

#### Scenario: No What Changes line refused
- **GIVEN** a draft change with `Issue: none` and no list item under What Changes
- **WHEN** it is approved
- **THEN** it exits non-zero naming What Changes, no issue is created and the proposal still says `Status: draft`

### Requirement: Approval follows the change status
The system SHALL approve only a change whose `Status:` is `draft` or `approved`, refusing any other unchanged and without any forge call, and SHALL leave an already approved change that names its issue unchanged.

#### Scenario: Approved change re-run
- **GIVEN** a change whose proposal says `Status: approved` and `Issue: o/r#3`
- **WHEN** it is approved again
- **THEN** it exits 0, the forge is not called and the proposal is unchanged

#### Scenario: Finished change refused
- **GIVEN** a change whose proposal says `Status: done` and `Issue: o/r#3`
- **WHEN** it is approved
- **THEN** it exits non-zero naming the status, the forge is not called and the proposal still says `Status: done`

### Requirement: Issue creation dry run
The system SHALL accept `--dry-run` on approval, print each forge write and the status update it would make, and SHALL NOT call any forge write or change the proposal.

#### Scenario: Approval dry run
- **GIVEN** a draft change `add-x` with `Issue: none`
- **WHEN** it is approved with `--dry-run`
- **THEN** it exits 0, prints a `gh issue create … --type Feature --assignee @me` line, no issue is created and the proposal is unchanged

### Requirement: Issue created with one type
The system SHALL create an issue from a title, a body file and exactly one type of `feat`, `bug` or `chore`, set as the forge's issue type `Feature`, `Bug` or `Task` and not as a label, assigned to `@me` unless another login is given, optionally in a named milestone and blocked by named issues, and SHALL print the new issue as `owner/repo#n`.

#### Scenario: Issue created with type and milestone
- **GIVEN** a repository and a body file `b.md`
- **WHEN** an issue is created with title `Crash`, body file `b.md`, type `bug`, milestone `v1` and blocked-by `3`, and the forge returns `https://github.com/o/r/issues/9`
- **THEN** one issue is created with title `Crash`, body file `b.md`, issue type `Bug`, assignee `@me`, milestone `v1` and blocked-by `3`, no label is read or written, and the output is exactly `o/r#9`

### Requirement: Issue type changed
The system SHALL, when an issue's type is changed, set the forge's issue type in one edit and leave the issue's labels untouched.

#### Scenario: Issue type changed
- **GIVEN** issue 4 of type `Bug`
- **WHEN** its type is set to `feat`
- **THEN** one edit sets issue type `Feature` and no label is read or written

### Requirement: Issue fields edited
The system SHALL change an issue's title, body (from a file), milestone (set or removed), and assignees (added or removed) in one edit, and SHALL refuse an edit that names no change.

#### Scenario: Title, milestone and assignee edited
- **GIVEN** issue 4
- **WHEN** it is edited with title `New`, milestone `v2` and assignee `alice`
- **THEN** one edit sets title `New`, milestone `v2` and adds assignee `alice`

#### Scenario: Milestone removed
- **GIVEN** issue 4 in a milestone
- **WHEN** it is edited with no milestone
- **THEN** one edit removes the milestone

#### Scenario: Empty edit refused
- **GIVEN** issue 4
- **WHEN** it is edited with no field
- **THEN** it exits 2 and the forge is not called

### Requirement: Issue dependencies edited
The system SHALL add and remove an issue's blocked-by issues by number.

#### Scenario: Blocked-by added and removed
- **GIVEN** issue 4 blocked by issue 2
- **WHEN** it is edited to be blocked by 3 and no longer by 2
- **THEN** one edit adds blocked-by `3` and removes blocked-by `2`

### Requirement: Issue comment from a file
The system SHALL post a comment on an issue whose text comes from a file.

#### Scenario: Comment posted from a file
- **GIVEN** issue 4 and a file `c.md`
- **WHEN** a comment is posted with body file `c.md`
- **THEN** one comment on issue 4 is created from `c.md`

### Requirement: Issue closed with a reason and reopened
The system SHALL close an issue as `completed` (the default), `not planned`, or a duplicate of a named issue, SHALL reopen a closed issue, and SHALL refuse any other close reason.

#### Scenario: Issue closed as not planned
- **GIVEN** open issue 4
- **WHEN** it is closed with reason `not-planned`
- **THEN** issue 4 is closed with reason `not planned`

#### Scenario: Issue closed as duplicate
- **GIVEN** open issues 4 and 2
- **WHEN** issue 4 is closed as a duplicate of 2
- **THEN** issue 4 is closed marked as duplicate of `2`

#### Scenario: Issue reopened
- **GIVEN** closed issue 4
- **WHEN** it is reopened
- **THEN** issue 4 is reopened

#### Scenario: Unknown close reason refused
- **GIVEN** open issue 4
- **WHEN** it is closed with reason `wontfix`
- **THEN** it exits 2 and the forge is not called

### Requirement: Issues listed compactly
The system SHALL list open issues, at most 100 unless another limit is given, only unblocked ones when asked for ready work, filtered by type and milestone when given, printing one line per issue: `#n`, its issue type (or `-`), its milestone (or `-`) and its title, separated by tabs.

#### Scenario: Ready issues of one type listed
- **GIVEN** open unblocked issue 4 `Add x` of type `Feature` in milestone `v1`, and issue 5 `Fix y` with no type and no milestone
- **WHEN** ready issues of type `feat` in milestone `v1` are listed
- **THEN** the forge is searched for `-is:blocked is:open` with issue type `Feature` and milestone `v1`, and the lines for the returned issues read `#4	Feature	v1	Add x` and `#5	-	-	Fix y`

#### Scenario: Issue list limit raised
- **GIVEN** a repository with more than 100 open issues
- **WHEN** issues are listed with limit `300`
- **THEN** the forge is asked for at most `300` issues

### Requirement: Milestones managed
The system SHALL create a milestone from a title and an optional `YYYY-MM-DD` due date, list open milestones one line each with title, due date (or `-`) and open and closed issue counts, and close a milestone by its exact title, refusing a title that matches no open milestone and a due date not in `YYYY-MM-DD` form.

#### Scenario: Milestone created with due date
- **GIVEN** a repository
- **WHEN** milestone `v1` is created due `2026-12-01`
- **THEN** one milestone `v1` is created with due date `2026-12-01T12:00:00Z`

#### Scenario: Bad due date refused
- **GIVEN** any repository
- **WHEN** milestone `v1` is created due `next week`
- **THEN** it exits 2 and the forge is not called

#### Scenario: Milestone create dry run
- **GIVEN** a repository
- **WHEN** milestone `v1` is created with `--dry-run`
- **THEN** it exits 0, prints a `gh api` line that would create `v1`, and no write reaches the forge

#### Scenario: Milestones listed
- **GIVEN** open milestones `v1` due `2026-12-01T00:00:00Z` with 2 open and 1 closed issue, and `v2` with no due date and no issues
- **WHEN** milestones are listed
- **THEN** the lines read `v1	2026-12-01	2 open, 1 closed` and `v2	-	0 open, 0 closed`

#### Scenario: Milestone closed by title
- **GIVEN** open milestones `v1` (number 7) and `v10` (number 8)
- **WHEN** milestone `v1` is closed
- **THEN** milestone 7 is set to closed and milestone 8 is not changed

#### Scenario: Unknown milestone close refused
- **GIVEN** no open milestone titled `v9`
- **WHEN** milestone `v9` is closed
- **THEN** it exits 1 naming `v9` and no milestone is changed

### Requirement: Issue input refused before the forge
The system SHALL exit 2 without calling the forge for an unknown operation or option, an issue number that is not a positive integer, a type other than `feat`, `bug` or `chore`, a body file that does not exist, a login that is not `@me` or a plain account name, an empty option value, and an edit that both sets and removes the milestone.

#### Scenario: Bad issue input refused
- **GIVEN** any repository
- **WHEN** an issue is edited as `1; touch INJECTED`, created with type `feature`, created with a missing body file, assigned to `a b` or `-x`, edited with an empty title, edited with milestone `v1` and no milestone at once, or an operation `delete` is asked for
- **THEN** each exits 2, the forge is not called and no file named `INJECTED` exists

### Requirement: Issue write dry run
The system SHALL accept `--dry-run` as the last argument of every write, print each forge write it would make, and SHALL NOT make any forge write; reads it needs to decide the writes still run.

#### Scenario: Issue write dry run
- **GIVEN** a repository and issue 4 of type `Bug`
- **WHEN** an issue of type `feat` is created, issue 4's type is set to `feat`, and issue 4 is closed, each with `--dry-run`
- **THEN** each exits 0 and prints its `gh issue create`, `gh issue edit` and `gh issue close` write lines, and no write reaches the forge

### Requirement: Tracking issue type follows the slug
The system SHALL give the tracking issue the forge's issue type `Bug` for a slug starting `fix-`, `Feature` for one starting `add-`, and `Task` otherwise, and SHALL NOT read or write a label for it.

#### Scenario: Type follows the slug prefix
- **GIVEN** draft changes `fix-y` and `tidy-z`, both with `Issue: none`
- **WHEN** each is approved
- **THEN** `fix-y`'s issue has issue type `Bug`, `tidy-z`'s has `Task`, and no label is read or written
