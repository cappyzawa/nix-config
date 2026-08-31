---
paths:
  - "AGENTS.md"
  - "CLAUDE.md"
  - "config/agents/**"
  - "config/codex/**"
  - "nix/home/default.nix"
  - "nix/modules/shared.nix"
---

# Codex configuration

## Canonical instructions

`config/agents/AGENTS.md` is the global instruction source shared by Codex and Claude Code.

- `config/codex/AGENTS.md` is a relative symlink to the canonical file.
- `config/claude/CLAUDE.md` is a relative symlink to the canonical file.
- The repository-root `AGENTS.md` contains nix-config-specific routing instructions.
- The repository-root `CLAUDE.md` is a symlink to `AGENTS.md` so both agents read the same project rules.
- Agent-specific behavior belongs in settings, hooks, skills, or custom agent definitions instead of the shared instructions.

## Home Manager deployment

`setupCodex` in `nix/home/default.nix` deploys the managed configuration to `~/.codex/`.

| Target | Source | Behavior |
|---|---|---|
| `~/.codex/config.toml` | `config/codex/config.toml`, host override, generated MCP config | Deep-merged into the existing writable file so runtime-managed projects and plugin state survive |
| `~/.codex/AGENTS.md` | `config/codex/AGENTS.md` and `hosts/<host>/claude-memory.md` | Copied into one global instruction file |
| `~/.codex/hooks.json` | `config/codex/hooks.json` | Symlinked |
| `~/.codex/agents/*.toml` | `config/codex/agents/*.toml` | Individually symlinked without deleting externally installed agents |
| `~/.agents/rules/*.md` | `config/agents/rules/*.md` | Agent-neutral language rules read directly by custom Codex agents and imported by Claude wrappers |
| `~/.codex/rules/*.rules` | `config/codex/rules/*.rules` | Individually symlinked without replacing runtime rules |
| `~/.codex/skills/<name>` | `config/codex/skills/<name>` | Compatible skills only, individually symlinked |

MCP servers continue to use `shared.claudeMcpServers` as their Nix source for compatibility, but activation renders that source into both Claude JSON and Codex TOML.

After the first deployment, and whenever `hooks.json` changes, open Codex and approve the user-level hook hash before expecting the herdr integration to run.

## Compatibility boundaries

- Codex `@file` mentions attach context from the prompt composer; unlike Claude's instruction imports, `@path` inside `AGENTS.md`, rules, or `SKILL.md` is not expanded automatically. Use nested `AGENTS.md`, skill `references/`, explicit read instructions, or symlinks for durable composition.
- Claude `paths:` rules do not load automatically in Codex. Language custom agents read `~/.agents/rules/<language>.md` directly, while Claude's thin `config/claude/rules/` wrappers add `paths:` and import the same body with `@path`.
- Claude prompt hooks and the session-specific oracle loop are not linked into Codex because their event contract and session environment differ.
- Codex uses `PermissionRequest` for herdr's blocked state because it has no `Notification(permission_prompt)` event.
- Codex preserves its existing model, trusted-project, plugin, and migration state unless a managed base or host setting explicitly overrides the same key.
- `approval_policy = "on-request"` together with `approvals_reviewer = "auto_review"` is the Codex equivalent of Claude's auto permission mode: the workspace sandbox remains active and a separate reviewer handles eligible escalation requests.
