{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  options.myConfig = {
    includePersonalApps = lib.mkEnableOption "personal applications (LINE, etc.)";
  };

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
            "/Applications/Alacritty.app"
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
          "com.apple.symbolichotkeys" = {
            AppleSymbolicHotKeys = {
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

      # Set desktop wallpaper to akari-night background color
      activationScripts.extraActivation.text = ''
        sudo -u ${username} /usr/bin/python3 /Users/${username}/.config/scripts/set-wallpaper.py || true
      '';

      # Apply settings without logout/login
      activationScripts.postActivation.text = ''
        sudo -u ${username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';
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
    };

    # User configuration
    users.users.${username} = {
      name = username;
      home = "/Users/${username}";
    };

    # Homebrew configuration
    homebrew = {
      enable = true;

      onActivation = {
        autoUpdate = false;
        cleanup = "zap"; # Remove unlisted casks/formulas
      };

      taps = [
        "nikitabobko/tap"
        "FelixKratz/formulae"
      ];

      brews = [
        "docker"
        "lua"
        "mas"
        "switchaudio-osx"
        "nowplaying-cli"
        "FelixKratz/formulae/borders"
        "FelixKratz/formulae/sketchybar"
      ];

      casks = [
        "nikitabobko/tap/aerospace"
        "alacritty"
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
        "claude-code"
      ];

      masApps =
        { }
        // lib.optionalAttrs config.myConfig.includePersonalApps {
          "LINE" = 539883307;
        };
    };

    # Enable Touch ID for sudo
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}
