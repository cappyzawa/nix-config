# Machine-specific configuration for work Mac (arkedge)
{
  lib,
  inputs,
  configName,
  currentUser,
  ...
}:
let
  # Optional per-host override module loaded via NIX_CONFIG_LOCAL env var.
  # `builtins.getEnv` returns "" without --impure, so pure evaluation always
  # yields an empty imports list and the override is silently ignored.
  localModulePath = builtins.getEnv "NIX_CONFIG_LOCAL";
  localModules = lib.optionals (localModulePath != "" && builtins.pathExists localModulePath) [
    (import localModulePath)
  ];
in
{
  imports = localModules;

  # Additional Homebrew packages for this machine
  homebrew = {
    taps = [
      "sqldef/sqldef"
      "kayac/tap"
      "fujiwara/tap"
    ];
    casks = [
      "twingate"
      "codex" # OpenAI Codex CLI (cask: prebuilt binary)
    ];
    brews = [
      "ical-buddy"
      "sqldef/sqldef/psqldef"
      "kayac/tap/ecspresso"
      "fujiwara/tap/lambroll"
      "influxdb-cli"
      "awscurl"
      "ffmpeg"
      "duckdb"
      "poppler"
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
        inputs.nixpkgs.legacyPackages.aarch64-darwin.prometheus.cli # promtool
        inputs.nixpkgs.legacyPackages.aarch64-darwin.wireguard-tools
        inputs.nixpkgs.legacyPackages.aarch64-darwin.ssm-session-manager-plugin
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

      # Single AWS MCP server; switch accounts/envs via `--profile` in call_aws.
      # No AWS_PROFILE pinned here: profile is resolved by boto3's default
      # credential chain. Credentials come from ~/.aws/config, which is managed
      # manually outside this repo (aws-vault credential_process / SSO).
      shared.claudeMcpServers.aws = {
        type = "stdio";
        command = "uvx";
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        env = {
          READ_OPERATIONS_ONLY = "true";
        };
      };

      # esa.io official MCP server (stdio). The access token is referenced as a
      # placeholder and expanded from the shell environment at MCP launch; the
      # real token lives in ~/.zshrc.local (kept out of this public repo).
      shared.claudeMcpServers.esa = {
        type = "stdio";
        command = "npx";
        args = [ "@esaio/esa-mcp-server" ];
        env = {
          ESA_ACCESS_TOKEN = "\${ESA_ACCESS_TOKEN}";
          LANG = "ja";
        };
      };

      programs = {
        # AeroSpace settings for external monitors
        aerospace.settings.gaps.outer.top = lib.mkForce [
          { monitor."DELL U2723QE" = 52; }
          { monitor."JAPANNEXT MNT" = 55; }
          8
        ];

        # AWS configuration for work environment
        # AWS_PROFILE default lives in ~/.zshrc.local (kept out of this public repo).
        zsh.sessionVariables = {
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
      };
    };
}
