---
paths:
  - "**/*.nix"
---

# Nix Patterns

- Uses Determinate Nix (nix.enable = false in nix/darwin/default.nix)
- Home Manager programs use declarative configuration (programs.git, programs.zsh, etc.)
- Static config files are symlinked from `config/` directory via `xdg.configFile`
- Target platform: aarch64-darwin (Apple Silicon)
- Machine configurations use `mkDarwin` helper with `hostname` and optional `username` parameters

## Machine-specific Configuration

Each machine has its own directory at `hosts/{hostname}/` with a `default.nix` and optional config files. Use these to add machine-specific settings like:

- Additional Homebrew casks/brews
- App Store apps (masApps)
- AeroSpace monitor-specific settings
- Host-specific config files (e.g., `claude-memory.md`)
- Any other host-specific overrides
