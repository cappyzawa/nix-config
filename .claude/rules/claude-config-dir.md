---
globs:
  - "config/claude/**"
  - ".gitignore"
---

# config/claude/ directory conventions

`config/claude/` is symlinked to `~/.claude/` via Home Manager (`skillsDir`, `rulesDir`, etc.).
This means externally installed files (e.g. Claude Code plugin install) also appear in this directory.

## Git tracking policy

Only files managed by this repository should be committed.
Externally installed skills are excluded via `.gitignore` whitelist:

```gitignore
config/claude/skills/*
!config/claude/skills/<repo-managed-skill>/
```

When adding a new repo-managed skill, add a corresponding `!` entry to `.gitignore`.

## File structure

| Type    | Path                                       | Entry point  |
|---------|--------------------------------------------|--------------|
| Skills  | `config/claude/skills/<name>/`             | `SKILL.md`   |
| Rules   | `config/claude/rules/<name>.md`            | -            |
| Agents  | `config/claude/agents/<name>/`             | `AGENT.md`   |
| Hooks   | `config/claude/hooks/`                     | -            |

- Skill/agent directory names become the `/slash-command` name
- Use lowercase with hyphens for directory and file names

## Adding new files

1. Create the file under `config/claude/`
2. `git add` the new file/directory before running `make check` (flake cannot reference untracked paths)
3. If it's a skill, add a whitelist entry (`!config/claude/skills/<name>/`) to `.gitignore`
