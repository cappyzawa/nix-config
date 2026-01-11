{ pkgs, username, ... }:

{
  # Primary user for user-specific settings
  system.primaryUser = username;

  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System state version
  system.stateVersion = 6;

  # The platform the configuration will be used on
  nixpkgs.hostPlatform = "aarch64-darwin";

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
      cleanup = "zap";  # Remove unlisted casks/formulas
    };

    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];

    brews = [
      "docker"
      "lua"
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
  };

  # macOS system settings
  system.defaults = {
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
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      _HIHideMenuBar = true;  # Hide menu bar for sketchybar
    };

    # Window Manager (disable desktop widgets)
    WindowManager = {
      EnableStandardClickToShowDesktop = false;
      StandardHideWidgets = true;
    };
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Set desktop wallpaper to akari-night background color
  system.activationScripts.extraActivation.text = ''
    sudo -u ${username} /usr/bin/python3 /Users/${username}/.config/scripts/set-wallpaper.py || true
  '';
}
