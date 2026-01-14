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

Edit `nix/home/default.nix` and add packages to `home.packages`:

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

Edit `nix/darwin/default.nix` and add to `homebrew.casks`:

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

Edit `nix/darwin/default.nix` and add to `homebrew.brews`:

```nix
homebrew.brews = [
  "docker"
  "colima"
  # Add your formula here
];
```

### Configuration files

Edit `nix/home/default.nix` and add to `xdg.configFile`:

```nix
xdg.configFile = {
  # Single file
  "myapp/config.toml".source = ../config/myapp/config.toml;

  # Directory (recursive)
  "myapp" = {
    source = ../config/myapp;
    recursive = true;
  };

  # Executable file
  "myapp/script.sh" = {
    source = ../config/myapp/script.sh;
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

## Using as a Module

This configuration exports modules that can be imported from another flake.

Create your own flake that imports this configuration:

```nix
{
  inputs = {
    nix-config.url = "github:cappyzawa/nix-config";
  };

  outputs = { nix-config, ... }:
    let
      inherit (nix-config.inputs) nix-darwin home-manager akari-theme tpm gh-ghq-cd;
      system = "aarch64-darwin";
      username = "your-username";
    in
    {
      darwinConfigurations.${username} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          nix-config.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [ akari-theme.homeModules.default ];
              extraSpecialArgs = {
                inherit username tpm;
                sbarluaPkg = nix-config.packages.${system}.sbarlua;
                gh-ghq-cd-pkg = gh-ghq-cd.packages.${system}.gh-ghq-cd;
              };
              users.${username} = {
                imports = [ nix-config.homeModules.default ];
              };
            };
          }
          # Add your overrides here
        ];
      };
    };
}
```

### Exported Outputs

| Output | Description |
|--------|-------------|
| `darwinModules.default` | nix-darwin configuration (macOS settings, Homebrew) |
| `darwinModules.shared` | Shared options module for nix-darwin |
| `homeModules.default` | Home Manager configuration (dotfiles, packages) |
| `homeModules.shared` | Shared options module for Home Manager |
| `packages.${system}.sbarlua` | SbarLua package for SketchyBar |

### Overriding Settings

You can override any setting using `lib.mkForce`:

```nix
{
  programs.git.userName = lib.mkForce "work-name";
  programs.git.userEmail = lib.mkForce "work@example.com";
}
```

### Using Shared Options

The shared module provides common configuration values (fonts, etc.) that can be used across modules.

See [`nix/modules/shared.nix`](./nix/modules/shared.nix) for available options.
