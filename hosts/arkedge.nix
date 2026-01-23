# Machine-specific configuration for work Mac (arkedge)
{
  lib,
  inputs,
  configName,
  currentUser,
  ...
}:
{
  # Additional Homebrew packages for this machine
  homebrew = {
    taps = [ "sqldef/sqldef" ];
    casks = [ "twingate" ];
    brews = [ "sqldef/sqldef/psqldef" ];
  };

  # AeroSpace overrides for external monitors
  home-manager.users.${currentUser} = {
    # Additional packages for work environment
    home.packages = [ inputs.nixpkgs.legacyPackages.aarch64-darwin.dotenvy ];

    programs = {
      # AeroSpace settings for external monitors
      aerospace.settings.gaps.outer.top = lib.mkForce [
        { monitor."DELL U2723QE" = 52; }
        { monitor."JAPANNEXT MNT" = 55; }
        8
      ];

      # AWS configuration for work environment
      zsh.sessionVariables = {
        AWS_PROFILE = "Aegs-Staging";
      };

      # Helix opslang support (work-specific)
      helix.languages = {
        language = [
          {
            name = "opslang";
            scope = "source.opslang";
            injection-regex = "opslang";
            file-types = [ "ops" ];
            comment-token = "#";
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            grammar = "opslang";
          }
        ];
        grammar = [
          {
            name = "opslang";
            source = {
              git = "https://github.com/arkedge/tree-sitter-opslang";
              rev = "main";
            };
          }
        ];
      };
    };
  };
}
