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

## Instructions

`config/codex/AGENTS.md` is Codex's global instruction file, independent of Claude's `config/claude/CLAUDE.md`.

- The two files share an engineering philosophy but not text: the workflows it implies differ by harness, and wording kept neutral for both was weaker in each. Duplicated rules are accepted because they change rarely.
- Only harness-independent skills are shared, from `config/agents/skills/`.
- The repository-root `AGENTS.md` holds nix-config facts, and the repository-root `CLAUDE.md` is a symlink to it, because those facts do not depend on the harness.

## Home Manager deployment

`setupCodex` in `nix/home/default.nix` deploys the managed configuration to `~/.codex/`.

| Target | Source | Behavior |
|---|---|---|
| `~/.codex/config.toml` | `config/codex/config.toml`, host override, generated MCP config | Deep-merged into the existing writable file so runtime-managed projects and plugin state survive |
| `~/.codex/AGENTS.md` | `config/codex/AGENTS.md` and `hosts/<host>/agent-instructions.md` | Copied into one global instruction file |
| `~/.codex/hooks.json` | `config/codex/hooks.json` | Symlinked |
| `~/.codex/rules/*.rules` | `config/codex/rules/*.rules` | Individually symlinked without replacing runtime rules |
| `~/.codex/skills/<name>` | `config/codex/skills/<name>` | Compatible skills only, individually symlinked |

MCP servers continue to use `shared.claudeMcpServers` as their Nix source for compatibility, but activation renders that source into both Claude JSON and Codex TOML.

After the first deployment, and whenever `hooks.json` changes, open Codex and approve the user-level hook hash before expecting the herdr integration to run.

## Compatibility boundaries

- Codex `@file` mentions attach context from the prompt composer; unlike Claude's instruction imports, `@path` inside `AGENTS.md`, rules, or `SKILL.md` is not expanded automatically. Use nested `AGENTS.md`, skill `references/`, explicit read instructions, or symlinks for durable composition.
- Codex has no path-scoped rules, so the language rules under `config/claude/rules/` are Claude-only. What the two agents share is the harness-independent skills.
- Only the herdr lifecycle hooks are deployed to each agent; neither carries workflow gates in hooks.
- Codex uses `PermissionRequest` for herdr's blocked state because it has no `Notification(permission_prompt)` event.
- Codex preserves its existing model, trusted-project, plugin, and migration state unless a managed base or host setting explicitly overrides the same key.
- No custom Codex roles are shipped. The top-level thread owns a task end to end, and subagents are tactical helpers that inherit its model and effort, so `agents.default_subagent_model` stays unset.
  - If a role is added later, deploy it through a directory link: Codex opens role files with `O_NOFOLLOW`, so a per-file symlink fails with `agent type is currently not available`, while discovery recurses into subdirectories.
- `model_reasoning_effort` applies to normal turns and `plan_mode_reasoning_effort` only to turns in Plan Mode. The higher Plan Mode effort does not make Plan Mode the default workflow; `AGENTS.md` limits Plan Mode to tasks that need the strategy confirmed first.
- Codex `spawn_agent` defaults to `fork_turns = "all"`, which forks the whole parent thread into each child (a review request once fanned out to 20 children and about 14M input tokens) and ignores `agent_type` / model overrides. There is no config for the default fork mode, so `features.multi_agent_v2.multi_agent_mode_hint_text` in `config/codex/config.toml` carries the stock non-proactive mode text plus an instruction to always pass `fork_turns = "none"`. The override is static text: if proactive delegation mode is ever turned on, or a Codex upgrade changes the stock wording, revisit it.
- `approval_policy = "on-request"` together with `approvals_reviewer = "auto_review"` is the Codex equivalent of Claude's auto permission mode: the workspace sandbox remains active and a separate reviewer handles eligible escalation requests.
