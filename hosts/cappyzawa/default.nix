# Machine-specific configuration for personal Mac (cappyzawa)
{
  lib,
  inputs,
  configName,
  currentUser,
  ...
}:
{
  home-manager.users.${currentUser}.imports = [ ./crequa-git.nix ];

  # Personal applications
  homebrew = {
    brews = [ "cloudflared" ];
    casks = [ "codex" ]; # OpenAI Codex CLI (cask: prebuilt binary)
    masApps = {
      "LINE" = 539883307;
    };
  };
}
