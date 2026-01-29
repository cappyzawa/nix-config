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
    taps = [
      "sqldef/sqldef"
      "kayac/tap"
    ];
    casks = [ "twingate" ];
    brews = [
      "sqldef/sqldef/psqldef"
      "kayac/tap/ecspresso"
    ];
  };

  # AeroSpace overrides for external monitors
  home-manager.users.${currentUser} = {
    # Additional packages for work environment
    home.packages = [
      inputs.nixpkgs.legacyPackages.aarch64-darwin.dotenvy
      inputs.nixpkgs.legacyPackages.aarch64-darwin.postgresql
    ];

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

      # gh-dash configuration for work environment
      # Note: Update the date filter periodically to exclude old items
      gh-dash.settings = {
        prSections = [
          {
            title = "My Pull Requests";
            filters = "is:open author:@me updated:>2026-01-01";
          }
          {
            title = "Needs My Review";
            filters = "is:open review-requested:@me updated:>2026-01-01";
          }
          {
            title = "Involved";
            filters = "is:open involves:@me -author:@me updated:>2026-01-01";
          }
        ];
        issuesSections = [
          {
            title = "My Issues";
            filters = "is:open author:@me updated:>2026-01-01";
          }
          {
            title = "Assigned";
            filters = "is:open assignee:@me updated:>2026-01-01";
          }
          {
            title = "Involved";
            filters = "is:open involves:@me -author:@me updated:>2026-01-01";
          }
        ];
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
