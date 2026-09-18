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
| `~/.codex/agents/*.toml` | `config/codex/agents/*.toml` | Individually symlinked without deleting externally installed agents; the directory is currently empty |
| `~/.codex/rules/*.rules` | `config/codex/rules/*.rules` | Individually symlinked without replacing runtime rules |
| `~/.codex/skills/<name>` | `config/codex/skills/<name>` | Compatible skills only, individually symlinked |

MCP servers continue to use `shared.claudeMcpServers` as their Nix source for compatibility, but activation renders that source into both Claude JSON and Codex TOML.

After the first deployment, and whenever `hooks.json` changes, open Codex and approve the user-level hook hash before expecting the herdr integration to run.

## Compatibility boundaries

- Codex `@file` mentions attach context from the prompt composer; unlike Claude's instruction imports, `@path` inside `AGENTS.md`, rules, or `SKILL.md` is not expanded automatically. Use nested `AGENTS.md`, skill `references/`, explicit read instructions, or symlinks for durable composition.
- Codex has no path-scoped rules, so the language rules under `config/claude/rules/` are Claude-only. What the two agents share is the instruction text and the skills.
- Only the herdr lifecycle hooks are deployed to each agent; neither carries workflow gates in hooks.
- Codex uses `PermissionRequest` for herdr's blocked state because it has no `Notification(permission_prompt)` event.
- Codex preserves its existing model, trusted-project, plugin, and migration state unless a managed base or host setting explicitly overrides the same key.
- No custom Codex agents are shipped. Role files pinned `model` / `model_reasoning_effort`, which froze subagents on an older tier as models moved on; the shared `AGENTS.md` now keeps work in the main session unless its subagent gate is met.
- Codex `spawn_agent` defaults to `fork_turns = "all"`, which forks the whole parent thread into each child (a review request once fanned out to 20 children and about 14M input tokens) and ignores `agent_type` / model overrides. There is no config for the default fork mode, so `features.multi_agent_v2.multi_agent_mode_hint_text` in `config/codex/config.toml` carries the stock non-proactive mode text plus an instruction to always pass `fork_turns = "none"`. The override is static text: if proactive delegation mode is ever turned on, or a Codex upgrade changes the stock wording, revisit it.
- `approval_policy = "on-request"` together with `approvals_reviewer = "auto_review"` is the Codex equivalent of Claude's auto permission mode: the workspace sandbox remains active and a separate reviewer handles eligible escalation requests.
