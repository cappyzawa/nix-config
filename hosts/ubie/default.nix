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
      "google-cloud-sdk"
      "trunk-io"
      "twingate"
    ];
    brews = [
    ];
  };
  home-manager.users.${currentUser} = _: {
    programs.mise.enable = true;
  };
}
