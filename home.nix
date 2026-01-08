{ config, pkgs, ... }:

{
  home.username = "cappyzawa";
  home.homeDirectory = "/Users/cappyzawa";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

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
}
