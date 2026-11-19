## Purpose
Releasing the plugin: one version string derived from conventional commits, a release PR that carries the bump and changelog, and on its merge a tag in the Claude Code plugin format plus a GitHub release.

## ADDED Requirements

### Requirement: Version has one source
The system SHALL fail the repository check when the plugin manifest version differs from the release manifest version.

#### Scenario: Hand bump fails the check
- **GIVEN** the plugin manifest says `2.10.0` and the release manifest says `2.9.0`
- **WHEN** the repository check runs
- **THEN** it fails and names both versions

#### Scenario: Matching versions pass
- **GIVEN** both manifests say `2.9.0`
- **WHEN** the repository check runs
- **THEN** the version check passes

### Requirement: Bump follows the conventional commits
The system SHALL, on every push to `main`, open or update one release PR whose version is the last release bumped minor for a `feat` commit, patch for a `fix`, `perf`, `revert` or `deps` commit and major for a breaking commit, and SHALL open none when only `docs`, `chore`, `ci`, `test`, `refactor`, `style` or `build` commits landed since the last release.

#### Scenario: Feature commit proposes a minor release
- **GIVEN** last release `2.9.0` and a merged `feat(x): y` commit
- **WHEN** the release workflow runs on `main`
- **THEN** a release PR proposes `2.10.0` and changes the plugin manifest version, the release manifest and the changelog

#### Scenario: Docs-only commits propose no release
- **GIVEN** last release `2.9.0` and only `docs`, `chore` or `ci` commits since
- **WHEN** the release workflow runs on `main`
- **THEN** no release PR is open

### Requirement: Release PR merge publishes the release
The system SHALL, when the release PR merges, create tag `solo--v<version>` on the merge commit and a GitHub release of that tag whose notes are the version's changelog section.

#### Scenario: Release PR merge tags and publishes
- **GIVEN** an open release PR for `2.10.0`
- **WHEN** it is rebase-merged
- **THEN** tag `solo--v2.10.0` points at a commit whose plugin manifest says `2.10.0` and a GitHub release `solo--v2.10.0` exists

### Requirement: Release PR runs the required check
The system SHALL run the required `check` job on the release PR head every time the release workflow opens or updates it.

#### Scenario: Release PR gets the required check
- **GIVEN** the release workflow just opened or updated the release PR
- **WHEN** its checks are listed
- **THEN** a `check` run exists for the PR head commit

### Requirement: First release is 2.9.0
The system SHALL have release `solo--v2.9.0` on the last `main` commit before this change, and SHALL compute the first proposed release only from commits after it.

#### Scenario: Bootstrap release exists
- **GIVEN** this change is merged
- **WHEN** the releases are listed
- **THEN** `solo--v2.9.0` exists and its commit's plugin manifest says `2.9.0`
