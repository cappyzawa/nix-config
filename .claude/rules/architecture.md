---
globs:
  - "**/*.nix"
  - "config/**"
---

# Architecture

This is a Nix Flake-based configuration for macOS using nix-darwin and Home Manager.

## Directory Structure

```
.
├── flake.nix          # Entry point: inputs, outputs, mkDarwin helper
├── hosts/             # Machine-specific configuration
│   └── cappyzawa.nix  # Personal Mac settings
├── nix/
│   ├── darwin/        # nix-darwin configuration
│   │   └── default.nix    # macOS system: Homebrew, system defaults, security
│   ├── home/          # home-manager configuration
│   │   └── default.nix    # User environment: packages, programs, dotfiles
│   └── modules/       # Shared modules
│       └── shared.nix
└── config/            # Static configuration files
    ├── borders/
    ├── sketchybar/
    └── ...
```

## Configuration Flow

```
flake.nix (mkDarwin helper)
  └─→ hosts/{hostname}.nix (machine-specific settings)
  └─→ nix/darwin/ (system-level: homebrew, macOS settings)
  └─→ nix/home/ (user-level: packages, programs, dotfiles)
        └─→ config/ (static configuration files linked via xdg.configFile)
```

## Adding Dependencies

- **CLI tools via Nix**: Add to `home.packages` in `nix/home/default.nix`
- **GUI apps via Homebrew casks**: Add to `homebrew.casks` in `nix/darwin/default.nix`
- **CLI tools via Homebrew**: Add to `homebrew.brews` in `nix/darwin/default.nix`
- **Dotfiles**: Add to `xdg.configFile` in `nix/home/default.nix`, source files go in `config/`
- **Machine-specific settings**: Add to `hosts/{hostname}.nix`
