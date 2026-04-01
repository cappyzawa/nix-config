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
    casks = [ "twingate" ];
    brews = [
    ];
  };
  home-manager.users.${currentUser} = _: {
  };
}
