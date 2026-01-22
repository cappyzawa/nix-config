# Machine-specific configuration for work Mac (arkedge)
{
  lib,
  inputs,
  configName,
  currentUser,
  ...
}:
{
  # Additional Homebrew casks for this machine
  homebrew.casks = [
    "twingate"
  ];

  # AeroSpace overrides for external monitors
  home-manager.users.${currentUser} = {
    programs.aerospace.settings.gaps.outer.top = lib.mkForce [
      { monitor."DELL U2723QE" = 52; }
      { monitor."JAPANNEXT MNT" = 55; }
      8
    ];

    # AWS configuration for work environment
    programs.zsh.sessionVariables = {
      AWS_PROFILE = "Aegs-Staging";
    };
  };
}
