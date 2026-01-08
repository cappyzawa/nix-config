{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Packages
  home.packages = with pkgs; [
    jq # Used by Claude statusline
  ];

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      version = "1";
      git_protocol = "https";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        cd = "ghq-cd";
      };
    };
  };

  # Starship prompt
  programs.starship = {
    enable = true;
  };

  # Config files
  xdg.configFile = {
    # Claude Code
    "claude/settings.json".source = ./files/claude/settings.json;
    "claude/CLAUDE.md".source = ./files/claude/CLAUDE.md;
    "claude/statusline.sh" = {
      source = ./files/claude/statusline.sh;
      executable = true;
    };

    # Starship for Claude statusline
    "starship/starship-claude.toml".source = ./files/starship/starship-claude.toml;
  };
}
