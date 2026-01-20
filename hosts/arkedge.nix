# Machine-specific configuration for work Mac (arkedge)
{ lib, ... }:
{
  # Additional Homebrew casks for this machine
  homebrew.casks = [
    "twingate"
  ];

  # AeroSpace overrides for external monitors
  home-manager.users."kutsuzawa-shu" = {
    programs.aerospace.settings.gaps.outer.top = lib.mkForce [
      { monitor."DELL U2723QE" = 52; }
      { monitor."JAPANNEXT MNT" = 55; }
      8
    ];
  };
}
