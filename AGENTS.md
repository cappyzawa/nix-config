# nix-config

## Repository guidance

- Nix / nix-darwin / Home Manager configuration for the user's machines lives under `nix/`, `hosts/`, and `config/`.
- Read `.claude/rules/architecture.md` and `.claude/rules/build-commands.md` before changing repository structure or validation commands.
- When changing a file, read every `.claude/rules/*.md` whose `paths:` frontmatter matches that file; these files remain the shared path-scoped source until all supported agents implement the same mechanism.
- Read `.claude/rules/claude-config-dir.md` and `.claude/rules/claude-code-config.md` before changing Claude configuration.
- Read `.claude/rules/codex-config.md` before changing Codex configuration.
- Add new files to Git before running `make check`, because flakes do not see untracked paths.
- Run `make check` after Nix or managed configuration changes.
