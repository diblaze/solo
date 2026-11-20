## MODIFIED Requirements

### Requirement: Bump follows the conventional commits
The system SHALL, on every push to `main`, open or update one release PR whose version is the last release bumped minor for a `feat` commit, patch for a `fix`, `perf` or `revert` commit and major for a breaking commit, and SHALL open none when only commits of other types, such as `docs`, `chore`, `ci`, `test`, `refactor`, `style`, `build` or `deps`, landed since the last release.

#### Scenario: Feature commit proposes a minor release
- **GIVEN** last release `2.9.0` and a merged `feat(x): y` commit
- **WHEN** the release workflow runs on `main`
- **THEN** a release PR proposes `2.10.0` and changes the plugin manifest version, the release manifest and the changelog

#### Scenario: Docs-only commits propose no release
- **GIVEN** last release `2.9.0` and only `docs`, `chore` or `ci` commits since
- **WHEN** the release workflow runs on `main`
- **THEN** no release PR is open
