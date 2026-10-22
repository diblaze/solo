## Purpose
The directory map: a root index plus per-directory agent instruction files, written from codebase evidence. It covers which directories get a file, where a file is never written, what a re-run keeps, and how map writes pass approval, branching and the pre-PR gate.

## ADDED Requirements

### Requirement: Map links resolve
The system SHALL give the root `AGENTS.md` a Map table with one row per mapped directory. Each row links that directory's file. Each nested file SHALL name its nearest mapped ancestor's file as its parent. A map check SHALL fail when any relative link or parent reference in an `AGENTS.md` does not resolve.

#### Scenario: Valid map passes
- **GIVEN** a repository whose root `AGENTS.md` links `src/AGENTS.md`, whose `src/AGENTS.md` names `../AGENTS.md` as parent, and which has a `src/agents/AGENTS.md` outside any plugin
- **WHEN** the map is checked
- **THEN** the check exits 0

#### Scenario: Broken link refused
- **GIVEN** an `AGENTS.md` that links a path that does not exist
- **WHEN** the map is checked
- **THEN** the check exits non-zero and names the file and the link

### Requirement: Only directories that carry weight are mapped
The system SHALL consider only tracked files. It SHALL offer a map file only for a directory with at least 3 tracked files directly in it, or with at least 2 subdirectories that hold tracked files. Hidden, vendored, generated, fixture and spec-tool directories SHALL get no file.

#### Scenario: Small and hidden directories skipped
- **GIVEN** a repository with a directory holding 1 tracked file, a hidden directory, a vendored directory and an ignored build directory
- **WHEN** the candidate directory list is shown
- **THEN** none of them is offered a map file, and each tracked one is listed as skipped with its reason

### Requirement: Plugin definition folders are never mapped
The system SHALL NOT write an `AGENTS.md` into an `agents/`, `commands/` or `output-styles/` folder of a plugin or of a `.claude/` directory. The tool loads every markdown file in those folders as a definition.

#### Scenario: Plugin definition folder not offered
- **GIVEN** a repository that is a Claude Code plugin with 4 files in `agents/`
- **WHEN** the candidate directory list is shown
- **THEN** `agents/` is not offered and is listed as skipped because its markdown files must carry frontmatter

#### Scenario: Plugin definition folder refused
- **GIVEN** a plugin repository with an `AGENTS.md` in `agents/` or in `commands/`
- **WHEN** the map is checked
- **THEN** the check exits non-zero and names that file

### Requirement: Coding standard survives the map
The system SHALL keep the root `## Coding standard` section byte for byte when it writes the map. A map check SHALL fail when the section differs from the base revision.

#### Scenario: Coding standard kept on write
- **GIVEN** a root `AGENTS.md` with a `## Coding standard` section
- **WHEN** the map is written
- **THEN** the section is unchanged and the Map section sits outside it

#### Scenario: Coding standard edited refused
- **GIVEN** a committed root `AGENTS.md` with a `## Coding standard` section and a working copy that changes one of its lines
- **WHEN** the map is checked against the committed revision
- **THEN** the check exits non-zero and names the Coding standard section

### Requirement: Re-run keeps hand-written content
The system SHALL key table rows by path on a re-run. It SHALL add rows for new paths and drop rows for paths that are gone. It SHALL keep every other line, unless the code proves the line false.

#### Scenario: Unchanged tree re-run leaves no diff
- **GIVEN** a committed map and no file changes since
- **WHEN** the map is refreshed
- **THEN** no file changes

#### Scenario: Hand-written line kept
- **GIVEN** a map file with a line a person added under For AI agents
- **WHEN** the map is refreshed after a file was added to that directory
- **THEN** the line is still there and the new file has a row

#### Scenario: Directory no longer qualifies
- **GIVEN** a mapped directory that now holds fewer than 3 tracked files
- **WHEN** the map is refreshed
- **THEN** its file and its Map row are offered for removal, with the file's hand-written lines shown, and they are removed only on yes

### Requirement: Map writes pass the gates
The system SHALL show the candidate directory list and wait for the user's yes before it writes any file. It SHALL never write on the main branch. It SHALL stage only the map files it wrote or removed, in one commit that the pre-PR gate takes next.

#### Scenario: Directory list approved first
- **GIVEN** a repository with directories to map
- **WHEN** the map runs
- **THEN** the mapped, skipped and orphaned directories are shown and nothing is written before the user says yes

#### Scenario: Main branch not written
- **GIVEN** the current branch is `main`
- **WHEN** the map is approved
- **THEN** a new branch is created before the first file is written

#### Scenario: Only map files staged
- **GIVEN** an untracked, non-ignored file outside the map
- **WHEN** the map is committed
- **THEN** that file is not staged

### Requirement: Unloaded maps are reported
The system SHALL say in its report that nested map files are loaded only when the AGENTS.md option `instructionFiles` is `claude-md-and-agents-md`. It SHALL do this when the repository has a `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md`. It SHALL NOT edit any `CLAUDE.md` or setting.

#### Scenario: Repo with CLAUDE.md warned
- **GIVEN** a repository with a root `CLAUDE.md`
- **WHEN** the map is written
- **THEN** the report names the `instructionFiles` option and asks whether to delete the `CLAUDE.md` so the nested files load; nothing is deleted or changed without a yes
