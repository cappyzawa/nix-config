---
paths:
  - "config/claude/**"
  - ".claude/**"
  - ".gitignore"
---

# config/claude/ vs .claude/

Two `claude` directories with the same name but different roles. Do not merge them.

| | `config/claude/` | `.claude/` (repo root) |
|---|---|---|
| Role | **Distribution source** deployed to `~/.claude/` | **This repo's own project-local config** |
| Scope | All of the user's projects (global) | Only when working on nix-config |
| Deployed? | Yes — `setupClaude` copies/symlinks it (e.g. `~/.claude/rules -> config/claude/rules`) | No — stays inside this repo |
| `rules/` holds | Language coding conventions (`nix.md`, `rust.md`, `terraform.md`, `typescript.md`) | This repo's own docs (`architecture.md`, `build-commands.md`, `nix-patterns.md`, this file) |
| Read via | `~/.claude/CLAUDE.md` (global) | `paths:` frontmatter — each rule loads when a file it scopes is touched |

Neither is redundant: deleting `config/claude/` wipes the global `~/.claude/` setup; deleting `.claude/` drops the conventions Claude reads while editing nix-config. See `claude-code-config.md` (the `setupClaude` rules) for how `config/claude/` is deployed.

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

## Agent / Rule pairing

Language agents (`agents/<lang>.md`) are managed as a pair with a coding-convention rule (`rules/<lang>.md`):

- **Rule**: principles, style, and knowledge — content both the implementer (subagent) and the reviewer (main conversation) need. Scope it to target files via `paths:` frontmatter
- **Agent**: workflow definition only (pre-change checks, verification steps, output format) plus the `model:` override

Conventions written in the agent file reach only the subagent, so the main conversation cannot review its output against them. Workflow written in the rule file loads into review-only sessions that never implement. Keep this separation.

When adding or changing a language agent, revisit its paired rule.

## Adding new files

1. Create the file under `config/claude/`
2. `git add` the new file/directory before running `make check` (flake cannot reference untracked paths)
3. If it's a skill, add a whitelist entry (`!config/claude/skills/<name>/`) to `.gitignore`
