# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Run CI checks locally (flake check, fmt, statix, build)
make check

# Apply configuration (after making changes)
make switch

# Update flake inputs and apply
make update

# First-time setup (bootstrap nix-darwin)
# NIXNAME is required on first run, saved to ~/.config/nix/host for future use
make bootstrap NIXNAME=cappyzawa
```

## Architecture

This is a Nix Flake-based configuration for macOS using nix-darwin and Home Manager.

### Directory Structure

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
    ├── aerospace/
    ├── alacritty/
    ├── helix/
    └── ...
```

### Configuration Flow

```
flake.nix (mkDarwin helper)
  └─→ hosts/{hostname}.nix (machine-specific settings)
  └─→ nix/darwin/ (system-level: homebrew, macOS settings)
  └─→ nix/home/ (user-level: packages, programs, dotfiles)
        └─→ config/ (static configuration files linked via xdg.configFile)
```

### Adding Dependencies

- **CLI tools via Nix**: Add to `home.packages` in `nix/home/default.nix`
- **GUI apps via Homebrew casks**: Add to `homebrew.casks` in `nix/darwin/default.nix`
- **CLI tools via Homebrew**: Add to `homebrew.brews` in `nix/darwin/default.nix`
- **Dotfiles**: Add to `xdg.configFile` in `nix/home/default.nix`, source files go in `config/`
- **Machine-specific settings**: Add to `hosts/{hostname}.nix`

### Key Patterns

- Uses Determinate Nix (nix.enable = false in nix/darwin/default.nix)
- Home Manager programs use declarative configuration (programs.git, programs.zsh, etc.)
- Static config files are symlinked from `config/` directory via `xdg.configFile`
- Target platform: aarch64-darwin (Apple Silicon)
- Machine configurations use `mkDarwin` helper with `hostname` and optional `username` parameters

### Machine-specific Configuration

Each machine has its own configuration file in `hosts/{hostname}.nix`. Use these files to add machine-specific settings like:

- Additional Homebrew casks/brews
- App Store apps (masApps)
- AeroSpace monitor-specific settings
- Any other host-specific overrides
