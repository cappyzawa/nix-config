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
      "fujiwara/tap"
    ];
    casks = [ "twingate" ];
    brews = [
      "ical-buddy"
      "sqldef/sqldef/psqldef"
      "kayac/tap/ecspresso"
      "fujiwara/tap/lambroll"
    ];
  };

  home-manager.users.${currentUser} =
    { config, ... }:
    {
      # Additional packages for work environment
      home.packages = [
        inputs.nixpkgs.legacyPackages.aarch64-darwin.dotenvy
        inputs.nixpkgs.legacyPackages.aarch64-darwin.jsonnet
        inputs.nixpkgs.legacyPackages.aarch64-darwin.postgresql
        (inputs.nixpkgs.legacyPackages.aarch64-darwin.sloth.overrideAttrs (old: {
          ldflags = (old.ldflags or [ ]) ++ [
            "-X github.com/slok/sloth/internal/info.Version=v${old.version}"
          ];
        }))
        inputs.nixpkgs.legacyPackages.aarch64-darwin.wireguard-tools
      ];

      # Meeting opener script and launchd agent
      xdg.configFile."meeting-opener/meeting-opener.sh" = {
        source = ../../config/meeting-opener/meeting-opener.sh;
        executable = true;
      };

      launchd.agents.meeting-opener = {
        enable = true;
        config = {
          Program = "${config.home.homeDirectory}/.config/meeting-opener/meeting-opener.sh";
          ProgramArguments = [ "${config.home.homeDirectory}/.config/meeting-opener/meeting-opener.sh" ];
          StartInterval = 60;
          EnvironmentVariables = {
            PATH = "/opt/homebrew/bin:/usr/bin:/bin";
            HOME = "${config.home.homeDirectory}";
            XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
          };
          StandardErrorPath = "${config.home.homeDirectory}/.local/state/meeting-opener/stderr.log";
          StandardOutPath = "${config.home.homeDirectory}/.local/state/meeting-opener/stdout.log";
        };
      };

      programs = {
        # AWS MCP servers for Claude Code
        claude-code = {
          memory.text = lib.mkAfter (builtins.readFile ./claude-memory.md);
          settings.permissions.allow = [
            "mcp__aws-aegs-staging__suggest_aws_commands"
            "mcp__aws-aegs-staging__call_aws"
            "mcp__aws-aegs-production__suggest_aws_commands"
            "mcp__aws-aegs-production__call_aws"
          ];
          settings.mcpServers =
            let
              awsProfiles = [
                "Aegs-Staging"
                "Aegs-Production"
              ];
              mkAwsServer = profile: {
                type = "stdio";
                command = "uvx";
                args = [ "awslabs.aws-api-mcp-server@latest" ];
                env = {
                  AWS_PROFILE = profile;
                  READ_OPERATIONS_ONLY = "true";
                };
              };
            in
            lib.listToAttrs (map (p: lib.nameValuePair "aws-${lib.toLower p}" (mkAwsServer p)) awsProfiles);
        };

        # AeroSpace settings for external monitors
        aerospace.settings.gaps.outer.top = lib.mkForce [
          { monitor."DELL U2723QE" = 52; }
          { monitor."JAPANNEXT MNT" = 55; }
          8
        ];

        # AWS configuration for work environment
        zsh.sessionVariables = {
          AWS_PROFILE = "Aegs-Staging";
          AWS_VAULT_BACKEND = "keychain";
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
