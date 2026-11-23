# Machine-specific configuration for personal Mac (cappyzawa)
{
  lib,
  inputs,
  configName,
  ...
}:
{
  # Personal applications
  homebrew = {
    brews = [ "cloudflared" ];
    casks = [ "codex" ]; # OpenAI Codex CLI (cask: prebuilt binary)
    masApps = {
      "LINE" = 539883307;
    };
  };
}
