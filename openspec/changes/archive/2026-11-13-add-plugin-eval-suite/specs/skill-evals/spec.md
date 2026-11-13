## Purpose
Measures whether each workflow skill is chosen on natural phrasing, and not its overlapping neighbour, without letting a measured run change anything outside it or letting any automated check spend model usage.

## ADDED Requirements
### Requirement: Every skill has a trigger case
The system SHALL refuse, in its free static checks, any skill that has no eval case asserting that skill fires.

#### Scenario: Skill without a trigger case refused
- **GIVEN** a skill folder with no eval case whose "skill fired" grader names it
- **WHEN** the static guard checks run
- **THEN** they fail and name the skill

### Requirement: Trigger cases stop at the skill choice
The system SHALL refuse any trigger case that grants a tool other than the skill tool, allows more than 3 turns, or allows more than 120 seconds.

#### Scenario: Case outside the trigger limits refused
- **GIVEN** an eval case that grants a shell or file-write tool, or sets a turn cap above 3 or a timeout above 120 seconds
- **WHEN** the static guard checks run
- **THEN** they fail and name the case

### Requirement: Overlapping neighbours are guarded
The system SHALL give every known overlapping skill pair at least one case where one skill must fire and the other must fire zero times, scored in both baseline arms, and SHALL give every case whose skill another skill invokes a zero-call grader for that invoking skill.

#### Scenario: Boundary pair without a guard refused
- **GIVEN** an overlapping skill pair with no case carrying a zero-call grader for one of them
- **WHEN** the static guard checks run
- **THEN** they fail and name the pair

#### Scenario: Chaining skill without a guard refused
- **GIVEN** a case whose skill another skill invokes as a step, with no zero-call grader for the invoking skill
- **WHEN** the static guard checks run
- **THEN** they fail and name both skills

#### Scenario: Neighbour grader that can pass on a call refused
- **GIVEN** a neighbour grader without a minimum and maximum of zero calls, or not scored in both arms
- **WHEN** the static guard checks run
- **THEN** they fail and name the grader

### Requirement: Suite runs cannot reach outside the run
The system SHALL run the suite with one arm, the report kept local, a cost ceiling, and shell, file-write, web and subagent tools withheld even when the operator grants them.

#### Scenario: Runner keeps write tools off
- **GIVEN** the documented suite runner
- **WHEN** the static guard checks read it
- **THEN** they fail unless it runs one arm, keeps the report local, sets a cost ceiling and withholds shell, file-write, web and subagent tools after any operator flags

### Requirement: Automated checks spend no model usage
The system SHALL keep the eval suite out of every commit hook, push hook and CI job.

#### Scenario: Model-calling eval in hooks or CI refused
- **GIVEN** a hook or CI step that runs the eval suite
- **WHEN** the static guard checks run
- **THEN** they fail and name the file
