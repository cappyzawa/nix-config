# Machine-specific configuration for personal Mac (cappyzawa)
{
  lib,
  inputs,
  configName,
  currentUser,
  pkgs,
  ...
}:
{
  home-manager.users.${currentUser} = {
    imports = [ ./crequa-git.nix ];
    home.packages = [ pkgs.cloudflared ];
  };

  # Personal applications
  homebrew = {
    casks = [ "codex" ]; # OpenAI Codex CLI (cask: prebuilt binary)
    masApps = {
      "LINE" = 539883307;
    };
  };
}
