{
  config,
  pkgs,
  lib,
  username,
  tpm,
  sbarluaPkg,
  gh-ghq-cd-pkg,
  ...
}:

let
  fontFamily = config.shared.fonts.main;
  fontSize = config.shared.fonts.size;
in
{
  imports = [
    ../modules/shared.nix
  ];

  # Akari theme
  akari = {
    enable = true;
    variant = "night";
    tmux = {
      iconNormal = "󱥸";
      iconPrefix = "";
    };
  };
  home = {
    inherit username;
    homeDirectory = "/Users/${username}";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.11";

    # Home directory files
    file.".yamlfmt".source = ../../config/yamlfmt/config.yaml;

    packages = with pkgs; [
      # Core utilities
      jq # JSON processor (used by Claude statusline)
      fd # Better find
      eza # Better ls
      fzf # Fuzzy finder
      ripgrep # Better grep
      gnused # GNU sed
      wget # HTTP client

      # Development tools
      ghq # Repository manager
      helix # Modal editor

      # Nix tools
      nix-prefetch-github # Get sha256 for fetchFromGitHub

      # Languages (for Helix)
      go
      deno
      zig
      tree-sitter # Parser generator for Helix grammars

      # Language servers (for Helix)
      gopls # Go
      rust-analyzer # Rust
      yaml-language-server # YAML
      taplo # TOML
      marksman # Markdown
      nodePackages.bash-language-server # Bash
      nodePackages.typescript-language-server # TypeScript/JavaScript
      vscode-langservers-extracted # JSON, HTML, CSS
      lua-language-server # Lua
      terraform-ls # Terraform
      zls # Zig

      # Formatters and linters (for Helix)
      gotools # goimports
      shfmt # Shell
      shellcheck # Shell linter
      yamlfmt # YAML
      nodePackages.prettier # Multi-format (JSON, Markdown, CSS, HTML)
      terraform # HCL formatter

      # Additional development tools
      colima # Container runtime
      nodejs # Node.js
      uv # Python package manager (provides uvx)
      hyperfine # Benchmarking tool
      yq-go # YAML processor
      golangci-lint # Go linter
      goreleaser # Go release tool
      glow # Markdown renderer
    ];

    # SbarLua installation (symlink to expected location)
    activation.sbarluaSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p $HOME/.local/share/sketchybar_lua
      ln -sf ${sbarluaPkg}/lib/sketchybar_lua/sketchybar.so $HOME/.local/share/sketchybar_lua/sketchybar.so
    '';
  };

  # Disable manpages to avoid builtins.toFile warning with Determinate Nix
  # See: https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # GitHub CLI
    gh = {
      enable = true;
      extensions = [
        pkgs.gh-dash # config is managed by programs.gh-dash + akari-theme
        gh-ghq-cd-pkg
      ];
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

    # Starship prompt (akari-night palette is managed by akari-theme module)
    starship = {
      enable = true;
      settings = {
        add_newline = true;
        # akari-night palette is added by akari-theme module

        os = {
          disabled = true;
          symbols = {
            Alpaquita = " ";
            Alpine = " ";
            AlmaLinux = " ";
            Amazon = " ";
            Android = " ";
            AOSC = " ";
            Arch = " ";
            Artix = " ";
            CachyOS = " ";
            CentOS = " ";
            Debian = " ";
            DragonFly = " ";
            Elementary = " ";
            Emscripten = " ";
            EndeavourOS = " ";
            Fedora = " ";
            FreeBSD = " ";
            Garuda = "󰛓 ";
            Gentoo = " ";
            HardenedBSD = "󰞌 ";
            Illumos = "󰈸 ";
            Ios = "󰀷 ";
            Kali = " ";
            Linux = " ";
            Mabox = " ";
            Macos = " ";
            Manjaro = " ";
            Mariner = " ";
            MidnightBSD = " ";
            Mint = " ";
            NetBSD = " ";
            NixOS = " ";
            Nobara = " ";
            OpenBSD = "󰈺 ";
            openSUSE = " ";
            OracleLinux = "󰌷 ";
            Pop = " ";
            Raspbian = " ";
            Redhat = " ";
            RedHatEnterprise = " ";
            RockyLinux = " ";
            Redox = "󰀘 ";
            Solus = "󰠳 ";
            SUSE = " ";
            Ubuntu = " ";
            Unknown = " ";
            Void = " ";
            Windows = "󰍲 ";
            Zorin = " ";
          };
        };

        kubernetes = {
          symbol = "󱃾 ";
          disabled = false;
        };
        docker_context.disabled = true;
        directory = {
          truncation_length = 2;
          read_only = "󱧵 ";
          read_only_style = "";
        };
        git_branch.symbol = " ";
        git_status = {
          conflicted = "=";
          up_to_date = "";
          untracked = "?\${count}";
          stashed = "\\$\${count}";
          modified = "!\${count}";
          staged = "+\${count}";
          renamed = "»";
          deleted = "✘";
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
          behind = "⇣\${count}";
        };
        aws.disabled = true;
        nodejs.symbol = "󰎙 ";
        dotnet.symbol = " ";
        python.symbol = " ";
        java.symbol = " ";
        c.symbol = " ";
        golang.symbol = " ";
        lua = {
          symbol = " ";
          disabled = true;
        };
        terraform.symbol = "󱁢 ";
        fill = {
          symbol = "─";
          style = "fg:current_line";
        };
        cmd_duration.min_time = 500;
        shell = {
          unknown_indicator = "shell";
          powershell_indicator = "powershell";
          bash_indicator = "bash";
          zsh_indicator = "zsh";
          fish_indicator = "fish";
          disabled = true;
        };
        time = {
          time_format = "%H:%M";
          disabled = true;
        };
        username = {
          show_always = true;
          disabled = true;
        };
        character = {
          success_symbol = "[](bold green)";
          error_symbol = "[](bold red)";
          vicmd_symbol = "[](bold yellow)";
        };
        package.symbol = "󰏗 ";
        rust.symbol = "󱘗 ";
        gcloud.symbol = " ";
      };
    };

    # Direnv
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Git
    git = {
      enable = true;
      ignores = [
        ".idea/*"
        ".envrc"
        ".go-version"
        ".node-version"
        ".DS_Store"
        ".claude/"
        "CLAUDE.md"
        "CLAUDE.local.md"
        ".serena/"
      ];
      settings = {
        alias = {
          cm = "checkout main";
          graph = "log --graph --date-order -C -M --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --all --date=short";
          undo = "reset --soft HEAD^";
        };
        ghq.root = "~/ghq/src";
        merge.conflictstyle = "diff3";
        pull.rebase = true;
        init.defaultBranch = "main";
        core.ignorecase = false;
        credential.helper = "cache --timeout=3600";
        include.path = "~/.gitconfig.local";
      };
    };

    # Delta (git pager) - theme is managed by akari-theme module
    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    # Bat (theme is managed by akari-theme module)
    bat = {
      enable = true;
      config = {
        color = "always";
      };
    };

    # Lazygit
    lazygit = {
      enable = true;
    };

    # gh-dash (installed via gh.extensions, config managed by akari-theme)
    gh-dash = {
      enable = true;
      package = null; # installed via programs.gh.extensions
    };

    # Atuin (shell history)
    atuin = {
      enable = true;
      enableZshIntegration = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        search_mode = "fuzzy";
        filter_mode = "global";
        style = "compact";
      };
    };

    # Alacritty (theme is managed by akari-theme module)
    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          builtin_box_drawing = true;
          size = fontSize;
          bold = {
            family = fontFamily;
            style = "Bold";
          };
          italic = {
            family = fontFamily;
            style = "Italic";
          };
          normal = {
            family = fontFamily;
            style = "Regular";
          };
        };
        terminal.shell = {
          program = "/bin/zsh";
          args = [
            "-l"
            "-c"
            "tmux new-session -AD -s zzz"
          ];
        };
        window = {
          decorations = "none";
          dynamic_padding = true;
          option_as_alt = "Both";
          padding = {
            x = 5;
            y = 5;
          };
        };
        cursor.style = {
          shape = "Block";
          blinking = "Off";
        };
        keyboard.bindings = [ ];
      };
    };

    # Tmux
    tmux = {
      enable = true;
      prefix = "C-t";
      keyMode = "vi";
      escapeTime = 0;
      baseIndex = 1;
      mouse = true;
      terminal = "screen-256color";
      historyLimit = 2000;

      extraConfig = ''
        # Remove session flags so new windows get fresh environment from /etc/zshenv
        set-environment -gu __HM_ZSH_SESS_VARS_SOURCED
        set-environment -gu __ETC_ZSHENV_SOURCED
        set-environment -gu __NIX_DARWIN_SET_ENVIRONMENT_DONE

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
        # akari-tmux is now managed by akari-theme module
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
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "viins"; # Start in vi insert mode

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
        # akari-fzf and akari-zsh are now managed by akari-theme module
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
          # Starship is now managed by programs.starship + akari-theme module

          # Direnv (deferred)
          zsh-defer eval "$(direnv hook zsh)"

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
      # LG_CONFIG_FILE is managed by akari-theme module
      sessionVariables = {
        KEYTIMEOUT = "20";
        EDITOR = "hx";
        VISUAL = "hx";
        CVSEDITOR = "hx";
        SVN_EDITOR = "hx";
        GIT_EDITOR = "hx";
        CLAUDE_CONFIG_DIR = "$HOME/.config/claude";
      };
    };
  };

  xdg = {
    # XDG Base Directory
    enable = true;

    # Config files
    configFile = {
      # AeroSpace
      "aerospace/aerospace.toml".source = ../../config/aerospace/aerospace.toml;

      # JankyBorders
      "borders/bordersrc" = {
        source = ../../config/borders/bordersrc;
        executable = true;
      };

      # SketchyBar
      "sketchybar/sketchybarrc" = {
        source = ../../config/sketchybar/sketchybarrc;
        executable = true;
      };
      "sketchybar/init.lua".source = ../../config/sketchybar/init.lua;
      "sketchybar/bar.lua".source = ../../config/sketchybar/bar.lua;
      "sketchybar/colors.lua".source = ../../config/sketchybar/colors.lua;
      "sketchybar/default.lua".source = ../../config/sketchybar/default.lua;
      "sketchybar/icons.lua".source = ../../config/sketchybar/icons.lua;
      "sketchybar/settings.lua".source = ../../config/sketchybar/settings.lua;
      "sketchybar/helpers/init.lua".source = ../../config/sketchybar/helpers/init.lua;
      "sketchybar/helpers/default_font.lua".source = ../../config/sketchybar/helpers/default_font.lua;
      "sketchybar/helpers/icon_map.lua".source = ../../config/sketchybar/helpers/icon_map.lua;
      "sketchybar/items/init.lua".source = ../../config/sketchybar/items/init.lua;
      "sketchybar/items/spaces.lua".source = ../../config/sketchybar/items/spaces.lua;
      "sketchybar/items/front_app.lua".source = ../../config/sketchybar/items/front_app.lua;
      "sketchybar/items/clock.lua".source = ../../config/sketchybar/items/clock.lua;
      "sketchybar/items/date.lua".source = ../../config/sketchybar/items/date.lua;
      "sketchybar/items/media.lua".source = ../../config/sketchybar/items/media.lua;
      "sketchybar/items/widgets/init.lua".source = ../../config/sketchybar/items/widgets/init.lua;
      "sketchybar/items/widgets/battery.lua".source = ../../config/sketchybar/items/widgets/battery.lua;
      "sketchybar/items/widgets/volume.lua".source = ../../config/sketchybar/items/widgets/volume.lua;
      "sketchybar/items/widgets/cpu.lua".source = ../../config/sketchybar/items/widgets/cpu.lua;
      "sketchybar/items/widgets/memory.lua".source = ../../config/sketchybar/items/widgets/memory.lua;
      "sketchybar/items/widgets/wifi.lua".source = ../../config/sketchybar/items/widgets/wifi.lua;

      # Alacritty is managed by programs.alacritty + akari-theme module

      # Claude Code
      "claude/settings.json".source = ../../config/claude/settings.json;
      "claude/CLAUDE.md".source = ../../config/claude/CLAUDE.md;
      "claude/statusline.sh" = {
        source = ../../config/claude/statusline.sh;
        executable = true;
      };

      # Helix (themes are managed by akari-theme module)
      "helix/config.toml".source = ../../config/helix/config.toml;
      "helix/languages.toml".source = ../../config/helix/languages.toml;

      # Starship is managed by programs.starship + akari-theme module
      # Keep starship-claude.toml for Claude Code
      "starship/starship-claude.toml".source = ../../config/starship/starship-claude.toml;

      # Zsh config files
      "zsh/10_aliases.zsh".source = ../../config/zsh/10_aliases.zsh;
      "zsh/20_keybinds.zsh".source = ../../config/zsh/20_keybinds.zsh;
      "zsh/30_fzf.zsh".source = ../../config/zsh/30_fzf.zsh;
      "zsh/40_integrations.zsh".source = ../../config/zsh/40_integrations.zsh;

      # Bat theme, Lazygit themes, and gh-dash are managed by akari-theme module

      # Karabiner-Elements
      "karabiner/karabiner.json".source = ../../config/karabiner/karabiner.json;

      # TPM (Tmux Plugin Manager)
      "tmux/plugins/tpm" = {
        source = tpm;
        recursive = true;
      };

      # Scripts
      "scripts/set-wallpaper.py" = {
        source = ../../config/scripts/set-wallpaper.py;
        executable = true;
      };
    };
  };
}
