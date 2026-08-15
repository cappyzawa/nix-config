---
paths:
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

## After make switch

The herdr server keeps the environment it was started with and hands it to
every new pane, so panes opened after a switch still see the pre-switch env
(PATH, session vars). To pick up the new environment, restart the server —
`herdr server stop`, then reopen Alacritty. Sessions are restored, but the
processes inside panes are terminated, so finish or checkpoint agent work
first.
