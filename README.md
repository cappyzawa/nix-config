# nix-config

My Nix configuration for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager).

## What's included

- **nix-darwin**: macOS system settings, Homebrew management
- **Home Manager**: User environment, CLI tools, dotfiles

## Fresh macOS Setup

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your terminal after installation.

### 2. Clone this repository

```bash
# Using git (pre-installed on macOS)
git clone https://github.com/cappyzawa/nix-config.git ~/nix-config
cd ~/nix-config
```

### 3. Apply the configuration

```bash
# First time: bootstrap nix-darwin
nix run nix-darwin -- switch --flake '.#cappyzawa'

# After first run: use darwin-rebuild
sudo darwin-rebuild switch --flake '.#cappyzawa'
```

## Adding Dependencies

### CLI tools (Nix packages)

Edit `home.nix` and add packages to `home.packages`:

```nix
home.packages = with pkgs; [
  jq
  fd
  bat
  # Add your package here
  kubectl
  terraform
];
```

Search for packages at [search.nixos.org](https://search.nixos.org/packages).

### GUI applications (Homebrew casks)

Edit `darwin.nix` and add to `homebrew.casks`:

```nix
homebrew.casks = [
  "alacritty"
  "arc"
  # Add your cask here
  "slack"
  "zoom"
];
```

### CLI tools via Homebrew

Edit `darwin.nix` and add to `homebrew.brews`:

```nix
homebrew.brews = [
  "docker"
  "colima"
  # Add your formula here
];
```

### Configuration files

Edit `home.nix` and add to `xdg.configFile`:

```nix
xdg.configFile = {
  # Single file
  "myapp/config.toml".source = ./files/myapp/config.toml;

  # Directory (recursive)
  "myapp" = {
    source = ./files/myapp;
    recursive = true;
  };

  # Executable file
  "myapp/script.sh" = {
    source = ./files/myapp/script.sh;
    executable = true;
  };
};
```

### Programs with Home Manager modules

Many programs have dedicated Home Manager modules with configuration options:

```nix
programs.git = {
  enable = true;
  userName = "Your Name";
  userEmail = "your@email.com";
};

programs.starship = {
  enable = true;
  settings = {
    add_newline = false;
  };
};
```

See [Home Manager options](https://nix-community.github.io/home-manager/options.xhtml) for available modules.

## Daily Usage

After making changes, apply them with:

```bash
make switch
```

### Update dependencies

```bash
make update
```

### Rollback

```bash
# List generations
darwin-rebuild --list-generations

# Rollback to previous generation
sudo darwin-rebuild switch --rollback
```

## File Structure

```
.
├── Makefile        # Build commands
├── flake.nix       # Flake entry point
├── flake.lock      # Locked dependencies
├── darwin.nix      # macOS system configuration
├── home.nix        # Home Manager configuration
└── files/          # Configuration files
    ├── alacritty/
    ├── claude/
    ├── helix/
    ├── starship/
    └── zsh/
```
