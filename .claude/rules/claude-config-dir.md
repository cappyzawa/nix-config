---
paths:
  - "config/claude/**"
  - ".claude/**"
  - ".gitignore"
---

# config/claude/ vs .claude/

Two `claude` directories with the same name but different roles. Do not merge them.
Global instructions are the exception: `config/claude/CLAUDE.md` is a symlink to the cross-agent canonical `config/agents/AGENTS.md`.

| | `config/claude/` | `.claude/` (repo root) |
|---|---|---|
| Role | **Distribution source** deployed to `~/.claude/` | **This repo's own project-local config** |
| Scope | All of the user's projects (global) | Only when working on nix-config |
| Deployed? | Yes — `setupClaude` copies/symlinks/generates it (e.g. `~/.claude/skills -> config/claude/skills`) | No — stays inside this repo |
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
| Shared skills | `config/agents/skills/<name>/` with symlinks from both agent directories | `SKILL.md` |
| Claude-only skills | `config/claude/skills/<name>/` | `SKILL.md` |
| Shared rules | `config/agents/rules/<name>.md` | Inlined into the Claude wrapper at activation |
| Claude rule wrappers | `config/claude/rules/<name>.md` | `paths:` plus `@~/.agents/rules/<name>.md` |
| Agents  | `hosts/<host>/claude-agents/<name>.md` (host-specific); `config/claude/agents/<name>.md` for global ones, currently none | frontmatter `name:` / `description:` |

- Skill/agent directory names become the `/slash-command` name
- Use lowercase with hyphens for directory and file names

## Language rules

Coding conventions live once in `config/agents/rules/<lang>.md`. The Claude wrapper in `config/claude/rules/<lang>.md` only adds `paths:` and names the shared body with `@~/.agents/rules/<lang>.md`, which `setupClaude` expands into the deployed rule. Codex has no path-scoped rules, so the shared `AGENTS.md` tells it to read `~/.agents/rules/<lang>.md` before touching that language.

Rules carry conventions and knowledge, not workflow. There are no language subagents: the main session implements and verifies itself, per the shared `AGENTS.md`.

## Adding new files

1. Put agent-neutral rule bodies and compatible skills under `config/agents/`; put Claude-only files under `config/claude/`
2. `git add` the new file/directory before running `make check` (flake cannot reference untracked paths)
3. For a shared skill, add symlinks from both `config/claude/skills/<name>` and `config/codex/skills/<name>` to its canonical directory
4. If it appears under `config/claude/skills`, add a matching whitelist entry to `.gitignore`
