# prose-pass Specification

## Purpose
How prose written for people is rewritten or reviewed so it reads as a person wrote it, which text it never touches, and which workflow steps pass their prose through it before writing or posting.

## Requirements

### Requirement: Rewrite keeps every fact
The system SHALL rewrite prose to remove the catalogued writing patterns while keeping every supported claim, and SHALL NOT add a fact, name, number, date, quote or citation that the source or the user did not give.

#### Scenario: Rewrite keeps every fact
- **GIVEN** a paragraph with a staged contrast and an inflated claim
- **WHEN** it is rewritten
- **THEN** the rewrite states the same facts plainly and adds none

### Requirement: Final text holds no dash
The system SHALL leave no em dash, en dash or double hyphen used as a dash in the final text, outside code, commands, paths and URLs.

#### Scenario: Dashes removed
- **GIVEN** prose joining clauses with em dashes
- **WHEN** it is rewritten
- **THEN** the final text holds no em or en dash outside code

### Requirement: Agent-facing text left alone
The system SHALL NOT change code, code comments, agent instruction files or skill files, or commit messages.

#### Scenario: Agent-facing text left alone
- **GIVEN** a request to clean up an `AGENTS.md` or a code comment
- **WHEN** the prose pass runs
- **THEN** that text is left unchanged and the pass says which skill owns it

### Requirement: Review mode changes nothing
The system SHALL, when asked to review or flag text, change nothing and list each tell strongest first with the quoted phrase, its pattern number and a suggested fix, also when the text is a named file.

#### Scenario: Review lists tells without editing
- **GIVEN** a named file with several tells
- **WHEN** a review of it is requested
- **THEN** the file is unchanged and each tell is listed with its phrase, pattern number and fix

### Requirement: Embedded mode keeps the caller's format
The system SHALL, when another workflow step passes it text, return only the final text with that step's structure, headings, tables, length limits and prefixes kept, editing only the prose inside them.

#### Scenario: Caller format kept
- **GIVEN** a PR body with headings and a `Closes owner/repo#n` line
- **WHEN** the PR step passes it through the prose pass
- **THEN** the headings and the `Closes` line come back unchanged

### Requirement: Workflow prose passes the writer
The system SHALL pass the prose of a written doc, of an architecture decision record and of a pull request body through the prose pass in embedded mode before it writes the file or opens the pull request.

#### Scenario: Docs and ADR prose pass the writer
- **GIVEN** a doc or an ADR about to be written
- **WHEN** its text is final
- **THEN** its prose went through the prose pass before the file is written

#### Scenario: PR body passes the writer
- **GIVEN** a PR body about to be shown in the dry run
- **WHEN** the PR step writes the body file
- **THEN** the body's prose went through the prose pass first

### Requirement: Writer chosen for prose cleanup
The system SHALL route a request to make prose read like a person wrote it to the prose pass, not to the skills that call it.

#### Scenario: Prose cleanup goes to writer
- **GIVEN** a request to rewrite an AI-sounding README paragraph without changing its facts
- **WHEN** the skill is chosen
- **THEN** the writer fires, and docs, adr and pr-ready fire zero times
