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
make bootstrap

# After first run: use make switch
make switch
```

## Adding Dependencies

- **CLI tools (Nix)**: Add to `home.packages` in [`nix/home/default.nix`](./nix/home/default.nix). Search packages at [search.nixos.org](https://search.nixos.org/packages).
- **GUI apps (Homebrew casks)**: Add to `homebrew.casks` in [`nix/darwin/default.nix`](./nix/darwin/default.nix).
- **CLI tools (Homebrew)**: Add to `homebrew.brews` in [`nix/darwin/default.nix`](./nix/darwin/default.nix).
- **Dotfiles**: Add to `xdg.configFile` in [`nix/home/default.nix`](./nix/home/default.nix), source files go in [`config/`](./config/).
- **Programs**: Use Home Manager modules (e.g., `programs.git`, `programs.zsh`). See [Home Manager options](https://nix-community.github.io/home-manager/options.xhtml).

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
