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
    ];
  };
  home-manager.users.${currentUser} = _: {
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
    programs.mise.enable = true;
  };
}
