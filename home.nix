{ config, pkgs, lib, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Disable manpages to avoid builtins.toFile warning with Determinate Nix
  # See: https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Packages
  home.packages = with pkgs; [
    # Core utilities
    jq        # JSON processor (used by Claude statusline)
    fd        # Better find
    bat       # Better cat
    eza       # Better ls
    fzf       # Fuzzy finder
    ripgrep   # Better grep
    gnused    # GNU sed
    wget      # HTTP client

    # Development tools
    ghq       # Repository manager
    lazygit   # Git TUI
    helix     # Modal editor
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

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
  };

  # Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      extended = true;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
    };

    plugins = [
      # zsh-defer for deferred loading
      {
        name = "zsh-defer";
        src = pkgs.fetchFromGitHub {
          owner = "romkatv";
          repo = "zsh-defer";
          rev = "53a26e287fbbe2dcebb3aa1801546c6de32416fa";
          sha256 = "sha256-MFlvAnPCknSgkW3RFA8pfxMZZS/JbyF3aMsJj9uHHVU=";
        };
      }
      # fzf-tab for tab completion with fzf
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.2.0";
          sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
        };
      }
      # fzf history search
      {
        name = "zsh-fzf-history-search";
        src = pkgs.fetchFromGitHub {
          owner = "joshskidmore";
          repo = "zsh-fzf-history-search";
          rev = "master";
          sha256 = "sha256-4Dp2ehZLO83NhdBOKV0BhYFIvieaZPqiZZZtxsXWRaQ=";
        };
      }
      # Akari fzf theme
      {
        name = "akari-fzf";
        file = "akari-night.sh";
        src = pkgs.fetchFromGitHub {
          owner = "cappyzawa";
          repo = "akari-fzf";
          rev = "main";
          sha256 = "sha256-Csc14RVdesSDNQOw5KOEj3FpYPIh0jci+E+A6P3n72g=";
        };
      }
      # Akari zsh-syntax-highlighting theme
      {
        name = "akari-zsh";
        file = "akari-night.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "cappyzawa";
          repo = "akari-zsh";
          rev = "main";
          sha256 = "sha256-oXm3C6ChfSp2lqFn99wd/YHrGNtyYE/EPQPjiQm6ePM=";
        };
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # PATH management (must be first for nix-managed tools)
        typeset -U path
        # nix-darwin + home-manager uses per-user profile
        [[ -d "/etc/profiles/per-user/''${USER}/bin" ]] && path=("/etc/profiles/per-user/''${USER}/bin" $path)
        # Standalone home-manager uses .nix-profile
        [[ -d "''${HOME}/.nix-profile/bin" ]] && path=("''${HOME}/.nix-profile/bin" $path)
        [[ -d "''${HOME}/bin" ]] && path=("''${HOME}/bin" $path)
        [[ -d "''${CARGO_HOME}/bin" ]] && path=("''${CARGO_HOME}/bin" $path)
        [[ -d "''${HOME}/.local/bin" ]] && path+=("''${HOME}/.local/bin")
        [[ -d "''${HOME}/.krew/bin" ]] && path+=("''${HOME}/.krew/bin")
      '')
      ''
        # Starship (cached daily for performance)
        export STARSHIP_CONFIG="''${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
        () {
          local cache="''${HOME}/.cache/zsh/starship-init-$(date +%Y%m%d).zsh"
          if [[ ! -f "$cache" ]]; then
            mkdir -p "''${cache:h}"
            starship init zsh > "$cache"
          fi
          source "$cache"
        }

        # Direnv (deferred)
        zsh-defer eval "$(direnv hook zsh)"

        # fzf-history-search settings
        export ZSH_FZF_HISTORY_SEARCH_REMOVE_DUPLICATES=1
        export ZSH_FZF_HISTORY_SEARCH_DATES_IN_SEARCH=1

        # Source local config files
        for config_file ("''${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/*.zsh(N)); do
          source "$config_file"
        done

        # Deferred config files
        for config_file ("''${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/*.defer.zsh(N)); do
          zsh-defer source "$config_file"
        done

        # Load local configuration (machine-specific, secrets)
        [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
      ''
    ];

    # Zsh options and environment variables
    sessionVariables = {
      KEYTIMEOUT = "20";
      EDITOR = "hx";
      VISUAL = "hx";
      CVSEDITOR = "hx";
      SVN_EDITOR = "hx";
      GIT_EDITOR = "hx";
    };
  };

  # Config files
  xdg.configFile = {
    # Alacritty
    "alacritty" = {
      source = ./files/alacritty;
      recursive = true;
    };

    # Claude Code
    "claude/settings.json".source = ./files/claude/settings.json;
    "claude/CLAUDE.md".source = ./files/claude/CLAUDE.md;
    "claude/statusline.sh" = {
      source = ./files/claude/statusline.sh;
      executable = true;
    };

    # Helix
    "helix/config.toml".source = ./files/helix/config.toml;
    "helix/languages.toml".source = ./files/helix/languages.toml;
    "helix/themes" = {
      source = ./files/helix/themes;
      recursive = true;
    };

    # Starship
    "starship/starship.toml".source = ./files/starship/starship.toml;
    "starship/starship-claude.toml".source = ./files/starship/starship-claude.toml;

    # Zsh config files
    "zsh/10_aliases.zsh".source = ./files/zsh/10_aliases.zsh;
    "zsh/20_keybinds.zsh".source = ./files/zsh/20_keybinds.zsh;
    "zsh/30_fzf.zsh".source = ./files/zsh/30_fzf.zsh;
    "zsh/40_integrations.zsh".source = ./files/zsh/40_integrations.zsh;
    "zsh/60_gh-extensions.defer.zsh".source = ./files/zsh/60_gh-extensions.defer.zsh;
  };
}
