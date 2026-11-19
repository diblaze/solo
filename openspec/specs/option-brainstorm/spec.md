# option-brainstorm Specification

## Purpose
The options landscape produced when the approach to a change is still open: how many options, what each carries, how it is grounded in the repository, how it ends, and what it never writes.

## Requirements

### Requirement: Landscape of distinct options
The system SHALL present three to five materially different approaches, each with what it does, what it costs, where it breaks first and when it is the right call, and one of them SHALL be doing nothing or the smallest thing that clears the immediate need.

#### Scenario: Landscape of distinct options
- **GIVEN** an open question about how to approach a change
- **WHEN** a brainstorm runs
- **THEN** it shows three to five options, each with cost, first failure and the condition that makes it right, one of them the do-nothing option

### Requirement: Options grounded in the repository
The system SHALL read the repository before generating options, cite `path:line` for existing code an option leans on, and mark what it could not inspect as unverified on the option it weakens.

#### Scenario: Existing helper cited
- **GIVEN** a repository that already holds a helper covering part of the need
- **WHEN** a brainstorm runs
- **THEN** the option that reuses it cites the helper as `path:line`

### Requirement: Landscape ends on a pick
The system SHALL end with one recommended option and a one-sentence reason, followed by the open questions whose answers would change the recommendation.

#### Scenario: Landscape ends on a pick
- **GIVEN** a finished options landscape
- **WHEN** it is shown
- **THEN** it ends with a recommendation naming one option and the open questions with the pick each answer implies

### Requirement: Brainstorm writes nothing
The system SHALL write no code and no files during a brainstorm and SHALL leave planning the chosen option to the planning gate.

#### Scenario: No file written
- **GIVEN** a brainstorm in a repository
- **WHEN** the landscape is shown
- **THEN** no file in the repository was created or changed, and the next step named is the planning gate

### Requirement: Brainstorm chosen for open approach questions
The system SHALL route an open "what are our options" request to the brainstorm, not to planning or research, and SHALL keep a zero-call guard between the brainstorm and each of those two neighbours.

#### Scenario: Open options question goes to brainstorm
- **GIVEN** a request to lay out ways to approach a change with no approach chosen
- **WHEN** the skill is chosen
- **THEN** the brainstorm fires, and the plan and research skills fire zero times
