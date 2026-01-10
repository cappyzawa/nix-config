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
    eza       # Better ls
    fzf       # Fuzzy finder
    ripgrep   # Better grep
    gnused    # GNU sed
    wget      # HTTP client

    # Development tools
    ghq       # Repository manager
    helix     # Modal editor
    gh-dash   # GitHub dashboard
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

  # Git
  programs.git = {
    enable = true;
    ignores = [
      "**/.claude/settings.local.json"
      "**/CLAUDE.local.md"
    ];
  };

  # Bat
  programs.bat = {
    enable = true;
    config = {
      theme = "akari-night";
      color = "always";
    };
  };

  # Lazygit
  programs.lazygit = {
    enable = true;
  };

  # Tmux
  programs.tmux = {
    enable = true;
    prefix = "C-t";
    keyMode = "vi";
    escapeTime = 0;
    baseIndex = 1;
    mouse = true;
    terminal = "screen-256color";
    historyLimit = 2000;

    extraConfig = ''
      # Set PATH first for tpm and plugins (include nix paths)
      set-environment -g PATH "/etc/profiles/per-user/''${USER}/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/local/bin:/bin:/usr/bin"

      setenv LANG en_US.UTF-8

      # Nested tmux (F12 to toggle local tmux on/off)
      bind -T root F12 \
        set prefix None \; set key-table off \; refresh-client -S
      bind -T off F12 \
        set -u prefix \; set -u key-table \; refresh-client -S

      set-option -g default-shell /bin/zsh
      set-option -g default-command "exec arch -arch arm64 /bin/zsh --login"
      set-option -g focus-events on

      # Split window from current path
      bind-key \\ split-window -hf -c '#{pane_current_path}'
      bind-key | split-window -hfb -c '#{pane_current_path}'

      # Vertical split window from current path
      bind-key - split-window -v -c '#{pane_current_path}'
      bind-key _ split-window -vb -l 40% -c '#{pane_current_path}'

      # Rebalance pane layout
      bind-key = select-layout -E

      # New Window
      bind-key c new-window -c '#{pane_current_path}'

      # Swap & Select window in order
      bind-key ] swap-window -t +1\; select-window -t +1
      bind-key [ swap-window -t -1\; select-window -t -1

      # Move window in order
      bind-key C-l select-window -t +1
      bind-key C-h select-window -t -1

      # Custom mouse settings
      unbind-key -T root MouseDown1Pane
      unbind-key -T root MouseDown3Pane

      # Allow applications to use OSC 52 to access clipboard
      set -g set-clipboard on
      set -g allow-passthrough on

      # Window settings
      set-option -g renumber-windows on
      set-window-option -g pane-base-index 1

      # Pane selection timeout (for prefix + q)
      set -g display-panes-time 3000

      # Pane Title
      set-option -g pane-border-status top
      bind-key C-t run-shell 'status=$(tmux show-window-option -v pane-border-status); if [ "$status" = "top" ]; then tmux setw pane-border-status off; else tmux setw pane-border-status top; fi'
      bind-key : command-prompt -p "(rename-pane)" "select-pane -T %%"

      # Resize pane
      bind-key -r H resize-pane -L 5
      bind-key -r J resize-pane -D 5
      bind-key -r K resize-pane -U 5
      bind-key -r L resize-pane -R 5

      # Change active pane
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      # Reload config file
      bind-key r source-file ~/.config/tmux/tmux.conf\; display-message "[tmux] config reloaded!"

      # sync
      bind a setw synchronize-panes \; display "synchronize-panes #{?pane_synchronized,on,off}"

      # Look up in a man-page
      bind-key m command-prompt -p "Man:" "split-window 'man %%'"

      # terminal overrides
      set-option -ga terminal-overrides ",xterm-256color:Tc"

      # status bar
      set-option -g status-position top

      # vi mode
      set -g status-keys vi

      bind-key v copy-mode \; display "Copy mode!"

      bind-key p run-shell -b "~/.config/tmux/plugins/tmux-fzf/scripts/clipboard.sh buffer"

      bind-key -T edit-mode-vi Up send-keys -X history-up
      bind-key -T edit-mode-vi Down send-keys -X history-down
      unbind-key -T copy-mode-vi Space

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi V send-keys -X select-line
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi c send-keys -X clear-selection
      bind-key -T copy-mode-vi H send-keys -X start-of-line
      bind-key -T copy-mode-vi L send-keys -X end-of-line
      bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

      TMUX_FZF_SED="/usr/local/opt/gnu-sed/libexec/gnubin/sed"

      # List of plugins
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-open'
      set -g @plugin 'sainnhe/tmux-fzf'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @resurrect-capture-pane-contents 'on'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '10'
      set -g @plugin 'cappyzawa/akari-tmux'
      set -g @akari_variant 'night'
      set -g @akari_icon_normal '󱥸'
      set -g @akari_icon_prefix '''
      set -g @plugin 'cappyzawa/tmux-popups'
      set -g @popup_g 'lazygit'
      set -g @popup_l 'gh cd -p 1'
      set -g @popup_c 'gh cd -p 1 -c claude'
      set -g @popup_d 'gh dash'
      set -g @popup_f 'hx .'

      # Initialize TMUX plugin manager (keep this line at the very bottom)
      run -b '~/.config/tmux/plugins/tpm/tpm'
    '';
  };

  # Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "viins";  # Start in vi insert mode

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
        [[ -d "''${CARGO_HOME:-$HOME/.cargo}/bin" ]] && path=("''${CARGO_HOME:-$HOME/.cargo}/bin" $path)
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

    # Bat theme
    "bat/themes" = {
      source = ./files/bat/themes;
      recursive = true;
    };

    # Lazygit themes
    "lazygit/themes" = {
      source = ./files/lazygit/themes;
      recursive = true;
    };

    # gh-dash
    "gh-dash/config.yml".source = ./files/gh-dash/config.yml;
  };
}
