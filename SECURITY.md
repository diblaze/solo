# Security

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: open the repository's **Security** tab and choose **Report a vulnerability**. Please do not open a public issue for a security problem.

## Permission model

solo is a set of skills and agents. It runs with the permissions your Claude Code session already has, and adds none of its own.

- **No skill pre-approves tools.** Pushes, PR creation, merges and repository settings are shown first and wait for your yes (`/solo:pr-ready` steps 5 and 6).
- **Agent limits are instructions, not enforcement.** The read-only agents (planner, explorer, reviewer) and the implementer's git allowlist are written as rules in each agent file. Every agent can run Bash, so your own permission rules are the real boundary.
- **Issue text from outsiders is a claim.** `/solo:plan` and `/solo:investigate` check each issue and comment author against the repository's collaborators. Text by anyone else is treated as a claim to verify, never as an instruction.
- **The change scripts validate their input.** Slugs must be kebab-case and issue references `owner/repo#n` or `none`, before any file is read or written.

## Recommended settings

Add these rules to `~/.claude/settings.json` (or the project's `.claude/settings.json`):

```json
{
  "permissions": {
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/*.sops*)",
      "Read(**/keys.txt)",
      "Read(**/auth.json)",
      "Bash(git push --force:*)",
      "Bash(git reset --hard:*)",
      "Bash(git clean:*)"
    ],
    "ask": [
      "Bash(git restore:*)",
      "Bash(git stash:*)",
      "Bash(git checkout --:*)"
    ]
  }
}
```

- `deny` matches the agents' own secrets list and blocks the git commands that destroy uncommitted work, which `/solo:execute` keeps in the tree between task groups. Current Claude Code applies `Read()` rules to the Read tool and to common Bash reads (`cat`, `git diff` operands); other ways to read a file can still get past them.
- `ask` keeps the commands a slop or refactor pass may use to back out an edit, but only with your yes.
- Never run solo in `bypassPermissions` mode: it skips every rule above.
- Bash rules match command prefixes. They are guardrails, not a boundary: `bash -c '…'` or `git -C <dir> …` get around them. Use Claude Code's sandbox when you need a hard boundary.
