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

    taps = [];

    brews = [
      "docker"
    ];

    casks = [
      "alacritty"
      "arc"
      "1password"
      "raycast"
      "google-chrome"
      "google-japanese-ime"
      "karabiner-elements"
      "font-monaspace"
      "font-fira-code"
      "drawio"
      "excalidrawz"
      "obsidian"
      "dropbox"
      "appcleaner"
      "logi-options-plus"
      "claude-code"
    ];
  };

  # macOS system settings
  system.defaults = {
    # Dock
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
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
    };
  };

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
