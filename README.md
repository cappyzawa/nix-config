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
# First time: bootstrap nix-darwin (specify your host)
make bootstrap NIXNAME=cappyzawa

# After first run: use make switch
make switch
```

Available hosts can be found in `hosts/` directory or via `make help`.

## Adding Dependencies

- **CLI tools (Nix)**: Add to `home.packages` in [`nix/home/default.nix`](./nix/home/default.nix). Search packages at [search.nixos.org](https://search.nixos.org/packages).
- **GUI apps (Homebrew casks)**: Add to `homebrew.casks` in [`nix/darwin/default.nix`](./nix/darwin/default.nix).
- **CLI tools (Homebrew)**: Add to `homebrew.brews` in [`nix/darwin/default.nix`](./nix/darwin/default.nix).
- **Dotfiles**: Add to `xdg.configFile` in [`nix/home/default.nix`](./nix/home/default.nix), source files go in [`config/`](./config/).
- **Programs**: Use Home Manager modules (e.g., `programs.git`, `programs.zsh`). See [Home Manager options](https://nix-community.github.io/home-manager/options.xhtml).
- **Machine-specific settings**: Add to `hosts/{hostname}/default.nix`.

## Daily Usage

After making changes, apply them with:

```bash
make switch
```

### Update dependencies

[Renovate](.github/renovate.json5) automatically updates flake inputs via pull requests. To update manually:

```bash
make update
```

### Rollback

```bash
make rollback
```

## Multi-machine Setup

This configuration supports multiple machines with different usernames. Each machine has its own configuration in `hosts/`.

To add a new machine:

1. Create `hosts/{hostname}/default.nix` with machine-specific settings
2. Add to `flake.nix`:
   ```nix
   darwinConfigurations.{hostname} = mkDarwin "{hostname}" {
     user = "{username}";  # optional if same as hostname
   };
   ```
3. Bootstrap on the new machine: `make bootstrap NIXNAME={hostname}`

## Per-host local overrides

Some settings depend on machine-local paths (e.g. a tree-sitter grammar checked out in a sibling repo) and should not be committed to this public repo. Such overrides live outside the repo at:

```
~/.config/nix-config-local/{hostname}.nix
```

The Makefile detects this file and, when present, runs `darwin-rebuild` with `NIX_CONFIG_LOCAL=<path>` and `--impure`. The host module imports it via `builtins.getEnv "NIX_CONFIG_LOCAL"`. On hosts without an override file (and on CI / `nix flake check`) evaluation stays pure and the env var is empty, so the import is a no-op.

To enable an override on a host whose `hosts/{hostname}/default.nix` opts in (e.g. `hosts/arkedge/default.nix`):

1. Drop a module at `~/.config/nix-config-local/{hostname}.nix`. It receives the usual module args (`lib`, `currentUser`, `config`, ...).
2. Run `make switch NIXNAME={hostname}` as usual. The Makefile prints `Using local override: ...` when it picks up the file.
