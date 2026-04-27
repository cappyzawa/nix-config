---
paths:
  - "**/*.nix"
  - "config/**"
---

# Architecture

This is a Nix Flake-based configuration for macOS using nix-darwin and Home Manager.

## Directory Structure

```
.
├── flake.nix          # Entry point: inputs, outputs, mkDarwin helper
├── hosts/             # Machine-specific configuration (per-host directories)
│   ├── arkedge/
│   │   ├── default.nix        # Work Mac settings
│   │   └── claude-memory.md   # Host-specific CLAUDE.md additions
│   ├── cappyzawa/
│   │   └── default.nix        # Personal Mac settings
│   └── ubie/
│       └── default.nix        # Work Mac settings
├── nix/
│   ├── darwin/        # nix-darwin configuration
│   │   └── default.nix    # macOS system: Homebrew, system defaults, security
│   ├── home/          # home-manager configuration
│   │   └── default.nix    # User environment: packages, programs, dotfiles
│   └── modules/       # Shared modules
│       └── shared.nix
└── config/            # Static configuration files (shared across hosts)
    ├── borders/
    ├── sketchybar/
    └── ...
```

## Configuration Flow

```
flake.nix (mkDarwin helper)
  └─→ hosts/{hostname}/default.nix (machine-specific settings and config files)
  └─→ nix/darwin/ (system-level: homebrew, macOS settings)
  └─→ nix/home/ (user-level: packages, programs, dotfiles)
        └─→ config/ (static configuration files linked via xdg.configFile)
```

## Adding Dependencies

- **CLI tools via Nix**: Add to `home.packages` in `nix/home/default.nix`
- **CLI tools from a flake (not in nixpkgs)**: Add the repo as a flake input in `flake.nix`, expose its package through `extraSpecialArgs` in `lib/mkdarwin.nix` (e.g. `gh-ghq-cd-pkg`, `gws-pkg`), then accept the arg in `nix/home/default.nix` and reference it from `home.packages` or `programs.gh.extensions`
- **GUI apps via Homebrew casks**: Add to `homebrew.casks` in `nix/darwin/default.nix`
- **CLI tools via Homebrew**: Add to `homebrew.brews` in `nix/darwin/default.nix`
- **Dotfiles**: Add to `xdg.configFile` in `nix/home/default.nix`, source files go in `config/`
- **Machine-specific settings**: Add to `hosts/{hostname}/default.nix`
- **Host-specific config files**: Place alongside `default.nix` in `hosts/{hostname}/`
