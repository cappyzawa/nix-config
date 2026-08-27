# Machine-specific configuration for work Mac (ubie)
{
  configName,
  currentUser,
  ...
}:
{
  # Additional Homebrew packages for this machine
  homebrew = {
    taps = [
    ];
    casks = [
      "gcloud-cli"
      "trunk-io"
      "twingate"
    ];
    brews = [
      "ffmpeg"
      # mise: prebuilt bottle instead of slow Nix source build
      "mise"
    ];
  };
  home-manager.users.${currentUser} =
    { lib, ... }:
    {
      shared.claudeMcpServers = {
        atlassian = {
          type = "http";
          url = "https://mcp.atlassian.com/v1/mcp";
        };
        notion = {
          type = "http";
          url = "https://mcp.notion.com/mcp";
        };
      };
      # mise comes from Homebrew, so resolve it from PATH instead of a store path
      programs.zsh.initContent = lib.mkAfter ''
        zsh-defer eval "$(mise activate zsh)"
      '';
    };
}
