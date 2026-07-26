{
  config,
  pkgs,
  lib,
  inputs,
  configName,
  currentUser,
  username,
  ...
}:

let
  brewUser = config.homebrew.user; # = system.primaryUser
  brewUserHome = lib.attrByPath [ brewUser "home" ] "/Users/${brewUser}" config.users.users;

  # Homebrew 6.0 requires non-official taps to be trusted before their
  # formulae/casks load. Trust every third-party tap this config references:
  # explicitly declared taps plus the tap prefix of any fully-qualified
  # ("user/repo/name") brew or cask. Custom-remote taps (clone_target) match by
  # remote URL rather than "user/repo", so they are rejected by an assertion
  # below instead of being silently mis-seeded here.
  tapOfQualifiedPackage =
    name:
    let
      parts = lib.splitString "/" name;
    in
    lib.optionalString (
      builtins.length parts >= 3
    ) "${builtins.elemAt parts 0}/${builtins.elemAt parts 1}";
  packageTaps = builtins.filter (s: s != "") (
    map (p: tapOfQualifiedPackage p.name) (config.homebrew.brews ++ config.homebrew.casks)
  );
  declaredTaps = map (t: t.name) config.homebrew.taps;
  trustedTaps = lib.unique (map lib.toLower (declaredTaps ++ packageTaps));

  homebrewTrust = (pkgs.formats.json { }).generate "homebrew-trust.json" {
    trustedtaps = trustedTaps;
  };
in
{
  imports = [
    ../modules/shared.nix
  ];

  config = {
    system = {
      # Primary user for user-specific settings
      primaryUser = username;

      # System state version
      stateVersion = 6;

      # macOS system settings
      defaults = {
        # Dock
        dock = {
          autohide = true;
          minimize-to-application = true;
          mineffect = "scale";
          show-recents = false;
          tilesize = 48;
          persistent-apps = [
            "${config.users.users.${username}.home}/Applications/Home Manager Apps/Alacritty.app"
            "/Applications/Google Chrome.app"
          ];
        };

        # Finder
        finder = {
          AppleShowAllExtensions = true;
          ShowPathbar = true;
          FXEnableExtensionChangeWarning = false;
        };

        # Trackpad
        trackpad = {
          Clicking = true;
          TrackpadRightClick = true;
        };

        # Mouse
        ".GlobalPreferences"."com.apple.mouse.scaling" = 1.5;

        # Global settings
        NSGlobalDomain = {
          ApplePressAndHoldEnabled = false; # Enable key repeat instead of accent menu
          AppleShowAllExtensions = true;
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          _HIHideMenuBar = true; # Hide menu bar for sketchybar
        };

        # Window Manager (disable desktop widgets)
        WindowManager = {
          EnableStandardClickToShowDesktop = false;
          StandardHideWidgets = true;
        };

        # Keyboard shortcuts
        CustomUserPreferences = {
          # Disable App Nap for Slack so huddle audio does not drop out when its
          # window is moved off-screen by AeroSpace on inactive workspaces.
          "com.tinyspeck.slackmacgap" = {
            NSAppSleepDisabled = true;
          };
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
              # Disable Spotlight search (Command + Space)
              "64" = {
                enabled = false;
              };
              # Show Notification Center: Command + Option + N
              "163" = {
                enabled = true;
                value = {
                  parameters = [
                    110 # 'n' ASCII code
                    45 # N key code
                    1572864 # Command (1048576) + Option (524288)
                  ];
                  type = "standard";
                };
              };
            };
          };
        };
      };

      activationScripts = {
        # Seed Homebrew's tap trust store before `brew bundle` runs (the homebrew
        # activation step runs after preActivation). brew aborts the whole
        # activation on an untrusted tap, so the file must already exist.
        preActivation.text = lib.mkBefore (
          lib.optionalString config.homebrew.enable ''
            /usr/bin/install -d -o ${lib.escapeShellArg brewUser} -m 0755 ${lib.escapeShellArg "${brewUserHome}/.config/homebrew"}
            /usr/bin/install -o ${lib.escapeShellArg brewUser} -m 0600 ${lib.escapeShellArg "${homebrewTrust}"} ${lib.escapeShellArg "${brewUserHome}/.config/homebrew/trust.json"}
          ''
        );

        # Set desktop wallpaper to akari-night background color
        extraActivation.text = ''
          sudo -u ${username} /usr/bin/python3 /Users/${username}/.config/scripts/set-wallpaper.py || true
        '';

        # Apply settings without logout/login
        postActivation.text = ''
          sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
        '';
      };
    };

    # Disable nix-darwin's Nix management (using Determinate Nix)
    nix.enable = false;

    # Add Determinate Nix and Homebrew to PATH
    environment.systemPath = [
      "/nix/var/nix/profiles/default/bin"
      "/opt/homebrew/bin"
    ];

    nixpkgs = {
      # Allow unfree packages
      config.allowUnfree = true;

      # The platform the configuration will be used on
      hostPlatform = "aarch64-darwin";

      overlays = [ ];
    };

    # User configuration
    users.users.${username} = {
      name = username;
      home = "/Users/${username}";
    };

    # The tap trust seeding above keys on "user/repo"; custom-remote taps are
    # matched by their clone URL instead, so fail loudly rather than seed a
    # reference that Homebrew would never match.
    assertions = [
      {
        assertion = lib.all (tap: tap.clone_target == null) config.homebrew.taps;
        message = "Homebrew tap trust seeding does not support taps with clone_target.";
      }
    ];

    # Homebrew configuration
    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap"; # Remove unlisted casks/formulas
        # Homebrew now requires an explicit force flag for `bundle install --cleanup`.
        # Workaround for https://github.com/nix-darwin/nix-darwin/issues/1787;
        # remove once https://github.com/nix-darwin/nix-darwin/pull/1789 is merged
        # and the nix-darwin input is updated past it.
        extraFlags = [ "--force-cleanup" ];
        # Pin the trust store location so `brew bundle` reads the same
        # trust.json that preActivation seeds (activation runs without
        # XDG_CONFIG_HOME, so brew would otherwise fall back to ~/.homebrew).
        extraEnv.XDG_CONFIG_HOME = "${brewUserHome}/.config";
        # Homebrew 6.0 defaults HOMEBREW_UPGRADE_AUTO_UPDATES_CASKS to true, so
        # `brew upgrade` now targets `auto_updates true` casks whenever the app
        # bundle version differs from the tap version. Self-updating apps trail
        # the tap during staged rollouts (Chrome via Keystone), so activation
        # would re-download the cask and force-quit the running app, only to be
        # overwritten by the app's own updater. Restore the pre-6.0 behaviour and
        # let those casks update themselves; `brew upgrade --cask --greedy` still
        # works for one-off manual upgrades. Homebrew treats any non-empty value
        # as "set", so this can only be disabled by removing the line.
        extraEnv.HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS = "1";
      };

      taps = [
        "FelixKratz/formulae"
        "k1LoW/tap"
        "hashicorp/tap"
      ];

      brews = [
        "lua"
        "mas"
        "pkgx"
        "switchaudio-osx"
        "nowplaying-cli"
        "terminal-notifier"
        "FelixKratz/formulae/borders"
        "FelixKratz/formulae/sketchybar"
        "k1LoW/tap/mo"
        "agent-browser"
        "oven-sh/bun/bun"
        "terraform-ls" # Terraform language server
        "hashicorp/tap/terraform" # Terraform (BSL: prebuilt binary instead of slow Nix source build)
      ];

      casks = [
        "1password"
        "raycast"
        "google-chrome"
        "google-japanese-ime"
        "karabiner-elements"
        "font-moralerspace"
        "sf-symbols"
        "font-sf-mono"
        "font-sf-pro"
        "font-sketchybar-app-font"
        "drawio"
        "excalidrawz"
        "obsidian"
        "dropbox"
        "appcleaner"
        "logi-options+"
      ];

      masApps = {
        "Kindle" = 302584613;
      };
    };

    # Enable Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
