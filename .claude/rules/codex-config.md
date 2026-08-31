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
- Claude `paths:` rules do not load automatically in Codex. Language custom agents read `~/.agents/rules/<language>.md` directly, while Claude's thin `config/claude/rules/` wrappers add `paths:` and name the same body with `@path`.
- Claude Code resolves an instruction import eagerly at session start and attaches the imported body as a global instruction, so a `@path` left in a `paths:`-scoped rule loses its scope. `setupClaude` therefore inlines the shared body when it deploys `~/.claude/rules/`, and only the deployed copy is scoped.
- Stop gating is not shared through hooks: both agents rely on their own harness goal mechanism (`/goal`), and only the herdr lifecycle hooks are deployed to each.
- Codex uses `PermissionRequest` for herdr's blocked state because it has no `Notification(permission_prompt)` event.
- Codex preserves its existing model, trusted-project, plugin, and migration state unless a managed base or host setting explicitly overrides the same key.
- Model tiers map across the two agents as Fable 5 / Opus 5 -> `gpt-5.6-sol` (frontier), Sonnet 5 -> `gpt-5.6-terra` (balanced), Haiku 4.5 -> `gpt-5.6-luna` (fast). Codex has no tier above frontier, so Fable and Opus collapse onto `sol`.
- Language role files pin `model` and `model_reasoning_effort` so an implementation agent stays on the balanced tier no matter which model the main session runs, mirroring the `model: sonnet` on their Claude counterparts. `reviewer.toml` pins neither, mirroring `devils-advocate` inheriting the parent.
- `approval_policy = "on-request"` together with `approvals_reviewer = "auto_review"` is the Codex equivalent of Claude's auto permission mode: the workspace sandbox remains active and a separate reviewer handles eligible escalation requests.
