---
globs:
  - "Makefile"
  - "flake.nix"
---

# Build Commands

```bash
# Run CI checks locally (flake check, fmt, statix, build)
make check

# Apply configuration (after making changes)
# NOTE: Internally calls sudo darwin-rebuild switch, so user must run this manually
make switch

# Update flake inputs and apply
# NOTE: Internally calls sudo darwin-rebuild switch, so user must run this manually
make update

# First-time setup (bootstrap nix-darwin)
# NIXNAME is required on first run, saved to ~/.config/nix/host for future use
make bootstrap NIXNAME=cappyzawa
```
