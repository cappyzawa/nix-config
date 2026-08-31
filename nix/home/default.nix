{
  config,
  pkgs,
  lib,
  inputs,
  configName,
  currentUser,
  username,
  sbarluaPkg,
  gh-ghq-cd-pkg,
  herdr-pkg,
  ...
}:

let
  fontFamily = config.shared.fonts.main;
  fontSize = config.shared.fonts.size;
  # Local-only, hand-drawn-style diagram generator (drives the ponchi skill).
  # Not in nixpkgs and has no flake, so build from source pinned to a release tag.
  ponchi = pkgs.rustPlatform.buildRustPackage {
    pname = "ponchi";
    version = "0.3.0";
    src = pkgs.fetchFromGitHub {
      owner = "cappyzawa";
      repo = "ponchi";
      rev = "37f668d9ae72b91722999117708963375d4ad873"; # v0.3.0
      hash = "sha256-zh32lJC4z9Xz0wBYnejueisPTbKCsWNVrvSsJPmzYsQ=";
    };
    cargoHash = "sha256-EYp0QlT/mL/U4/v9way9t0bMjhef+Z/Fxq+GMQU3byc=";
    # Skip the build-time test suite: it exercises the local HTTP server /
    # rendering and is slow (or hangs) in the Nix sandbox. We only need the binary.
    doCheck = false;
    meta = {
      description = "Local-only, hand-drawn-style diagram generator for aligning AI agents and humans";
      homepage = "https://github.com/cappyzawa/ponchi";
      mainProgram = "ponchi";
      platforms = lib.platforms.darwin;
    };
  };
  claudeMcpConfig =
    (pkgs.formats.json { }).generate "claude-mcp-config.json"
      config.shared.claudeMcpServers;
  codexMcpServers = lib.mapAttrs (
    _: server:
    let
      serverEnv = server.env or { };
      inheritedEnvVars = lib.attrNames (
        lib.filterAttrs (name: value: builtins.isString value && value == "\${${name}}") serverEnv
      );
      literalEnv = lib.filterAttrs (
        name: value: !(builtins.isString value && value == "\${${name}}")
      ) serverEnv;
    in
    builtins.removeAttrs server [
      "type"
      "env"
    ]
    // lib.optionalAttrs (literalEnv != { }) { env = literalEnv; }
    // lib.optionalAttrs (inheritedEnvVars != [ ]) { env_vars = inheritedEnvVars; }
  ) config.shared.claudeMcpServers;
  codexMcpConfig = (pkgs.formats.toml { }).generate "codex-mcp-config.toml" {
    mcp_servers = codexMcpServers;
  };
in
{
  imports = [
    ../modules/shared.nix
  ];

  shared.claudeMcpServers = {
    context7 = {
      type = "http";
      url = "https://mcp.context7.com/mcp";
    };
  };

  # Akari theme
  akari = {
    enable = true;
    variant = "night";
    # Cascades on from akari.enable; tmux is gone (herdr took over)
    tmux.enable = false;
  };
  home = {
    inherit username;
    homeDirectory = "/Users/${username}";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "24.11";

    # Home directory files
    file.".yamlfmt".source = ../../config/yamlfmt/config.yaml;

    # Session PATH (declarative PATH management)
    sessionPath = [
      "$HOME/bin"
      "$HOME/go/bin"
      "$HOME/.cargo/bin"
      "$HOME/.local/bin"
      "$HOME/.krew/bin"
      "$HOME/.gem/ruby/bin"
      "$HOME/.claude/bin"
      "$HOME/.npm-global/bin"
    ];

    packages = with pkgs; [
      # Core utilities
      jq # JSON processor
      fd # Better find
      eza # Better ls
      fzf # Fuzzy finder
      ripgrep # Better grep
      gnused # GNU sed
      wget # HTTP client

      # Development tools
      ghq # Repository manager
      # Helix is managed by programs.helix

      # Nix tools
      nix-prefetch-github # Get sha256 for fetchFromGitHub

      # Languages (for Helix)
      go
      deno
      zig
      ruby_3_4 # Ruby
      rustup # Rust toolchain manager
      tree-sitter # Parser generator for Helix grammars

      # Language servers (for Helix)
      gopls # Go
      yaml-language-server # YAML
      taplo # TOML
      bash-language-server # Bash
      typescript-language-server # TypeScript/JavaScript
      vscode-langservers-extracted # JSON, HTML, CSS
      lua-language-server # Lua
      zls # Zig

      # Formatters and linters (for Helix)
      (lib.lowPrio gotools) # goimports (lowPrio to avoid bundle conflict with Ruby)
      shfmt # Shell
      shellcheck # Shell linter
      yamlfmt # YAML
      prettier # Multi-format (JSON, Markdown, CSS, HTML)

      # Additional development tools
      colima # Container runtime
      docker # Docker CLI
      docker-buildx # Docker buildx plugin
      kind # Kubernetes in Docker
      kubectl # Kubernetes CLI
      kubernetes-helm # Kubernetes package manager
      kustomize # Kubernetes configuration customization
      nodejs # Node.js
      pnpm # pnpm package manager
      protobuf # Protocol Buffers compiler (protoc)
      grpcurl # gRPC client for testing
      uv # Python package manager (provides uvx)
      hyperfine # Benchmarking tool
      yq-go # YAML processor
      ponchi # Hand-drawn-style diagram generator (ponchi skill)
      golangci-lint # Go linter
      goreleaser # Go release tool
      glow # Markdown renderer
      bacon # Rust background compiler
      herdr-pkg # Agent multiplexer (persistent sessions for coding agents)

      # Security and credentials
      aws-vault # AWS credential vault
      awscli2 # AWS CLI
      google-cloud-sdk # Google Cloud CLI (gcloud command)
      gnupg # GnuPG (gpg command)
      _1password-cli # 1Password CLI (op command)
    ];

    activation = {
      # Merge MCP servers into ~/.claude.json (user-scope MCP config)
      updateClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -f "$HOME/.claude.json" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --slurpfile mcp ${claudeMcpConfig} '.mcpServers = $mcp[0]' "$HOME/.claude.json" > "$tmp"
          $DRY_RUN_CMD mv "$tmp" "$HOME/.claude.json"
        fi
      '';

      # Claude Code installation via official installer.
      # Install only when claude is missing; the CLI self-updates, so it must
      # not be reinstalled on every switch. The installer now places the binary
      # in ~/.local/bin (older builds used ~/.claude/bin), so probe PATH instead
      # of a fixed path.
      installClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! PATH="$HOME/.local/bin:$HOME/.claude/bin:$PATH" command -v claude >/dev/null 2>&1; then
          $DRY_RUN_CMD /usr/bin/curl -fsSL https://claude.ai/install.sh | PATH="/usr/bin:/bin:$PATH" bash
        fi
      '';

      # Setup Claude config files (settings, CLAUDE.md, rules, skills, agents)
      setupClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        REPO_ROOT="${config.home.homeDirectory}/ghq/src/github.com/cappyzawa/nix-config"
        CLAUDE_DIR="$HOME/.claude"
        SHARED_RULES_DIR="$HOME/.agents/rules"
        HOST="${configName}"

        $DRY_RUN_CMD mkdir -p "$CLAUDE_DIR" "$SHARED_RULES_DIR"

        # Agent-neutral rule bodies. Claude wrappers import these with @path;
        # Codex custom agents read the same files directly.
        for f in "$REPO_ROOT/config/agents/rules"/*.md; do
          $DRY_RUN_CMD ln -sfn "$f" "$SHARED_RULES_DIR/$(basename "$f")"
        done

        # settings.json - copied as a writable file (not a symlink) so Claude Code can
        # persist toggle states (e.g. voiceEnabled) without dirtying the git working tree
        if [ -f "$REPO_ROOT/hosts/$HOST/claude-settings.json" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq -s '
            .[0] as $base | .[1] as $host |
            $base * $host |
            .permissions.allow = ($base.permissions.allow + $host.permissions.allow) |
            .permissions.deny = (($base.permissions.deny // []) + ($host.permissions.deny // []))
          ' "$REPO_ROOT/config/claude/settings.json" "$REPO_ROOT/hosts/$HOST/claude-settings.json" > "$tmp"
          $DRY_RUN_CMD mv "$tmp" "$CLAUDE_DIR/settings.json"
        else
          $DRY_RUN_CMD cp -f "$REPO_ROOT/config/claude/settings.json" "$CLAUDE_DIR/settings.json"
        fi

        # CLAUDE.md - common + host-specific + Claude-only local import.
        tmp=$(mktemp)
        cat "$REPO_ROOT/config/claude/CLAUDE.md" > "$tmp"
        if [ -f "$REPO_ROOT/hosts/$HOST/claude-memory.md" ]; then
          printf '\n' >> "$tmp"
          cat "$REPO_ROOT/hosts/$HOST/claude-memory.md" >> "$tmp"
        fi
        printf '\n\n## Local\n\n@~/.claude/CLAUDE.local.md\n' >> "$tmp"
        $DRY_RUN_CMD mv "$tmp" "$CLAUDE_DIR/CLAUDE.md"

        # rules - the wrappers' @~/.agents/rules/<name>.md imports are inlined
        # here rather than left for Claude Code to resolve. Claude Code resolves
        # instruction imports eagerly at session start and attaches the imported
        # body as a global instruction, so an imported body loses the wrapper's
        # `paths:` scope and stays resident in every session.
        rules_tmp=$(mktemp -d)
        for f in "$REPO_ROOT/config/claude/rules"/*.md; do
          ${pkgs.gawk}/bin/awk -v shared="$SHARED_RULES_DIR" '
            /^@~\/\.agents\/rules\/[^\/]+\.md$/ {
              body = shared "/" substr($0, length("@~/.agents/rules/") + 1)
              while ((getline line < body) > 0) print line
              close(body)
              next
            }
            { print }
          ' "$f" > "$rules_tmp/$(basename "$f")"
        done
        rm -rf "$CLAUDE_DIR/rules"
        $DRY_RUN_CMD mv "$rules_tmp" "$CLAUDE_DIR/rules"
        rm -rf "$rules_tmp"

        # skills, hooks - symlink directories
        for dir in skills hooks; do
          rm -rf "$CLAUDE_DIR/$dir"
          ln -sfn "$REPO_ROOT/config/claude/$dir" "$CLAUDE_DIR/$dir"
        done

        # agent-browser ships its skill with the CLI so the two stay version-matched.
        # Point at the brew-managed stable path, not `agent-browser skills path`
        # (that returns a version-pinned Cellar path and goes stale on upgrade).
        AB_SKILL="/opt/homebrew/opt/agent-browser/libexec/lib/node_modules/agent-browser/skills/agent-browser"
        AB_LINK="$REPO_ROOT/config/claude/skills/agent-browser"
        if [ -d "$AB_SKILL" ]; then
          # Never touch a real directory: an older commit still tracks files here
          if [ ! -e "$AB_LINK" ] || [ -L "$AB_LINK" ]; then
            $DRY_RUN_CMD ln -sfn "$AB_SKILL" "$AB_LINK"
          fi
        elif [ -L "$AB_LINK" ]; then
          $DRY_RUN_CMD rm -f "$AB_LINK"
        fi

        # agents - merge if host-specific exists, otherwise symlink
        if [ -d "$REPO_ROOT/hosts/$HOST/claude-agents" ]; then
          rm -rf "$CLAUDE_DIR/agents"
          mkdir -p "$CLAUDE_DIR/agents"
          for src_dir in "$REPO_ROOT/config/claude/agents" "$REPO_ROOT/hosts/$HOST/claude-agents"; do
            for f in "$src_dir"/*; do
              ln -sf "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
            done
          done
        else
          rm -rf "$CLAUDE_DIR/agents"
          ln -sfn "$REPO_ROOT/config/claude/agents" "$CLAUDE_DIR/agents"
        fi
      '';

      # Setup Codex config while preserving runtime-managed state such as
      # trusted projects, plugin toggles, and migration notices.
      setupCodex = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        REPO_ROOT="${config.home.homeDirectory}/ghq/src/github.com/cappyzawa/nix-config"
        CODEX_DIR="$HOME/.codex"
        HOST="${configName}"

        $DRY_RUN_CMD mkdir -p "$CODEX_DIR" "$CODEX_DIR/agents" "$CODEX_DIR/rules" "$CODEX_DIR/skills"

        runtime_json=$(mktemp)
        base_json=$(mktemp)
        mcp_json=$(mktemp)
        host_json=$(mktemp)
        merged_json=$(mktemp)
        merged_toml=$(mktemp)

        if [ -f "$CODEX_DIR/config.toml" ]; then
          ${pkgs.yq-go}/bin/yq -p toml -o json "$CODEX_DIR/config.toml" > "$runtime_json"
        else
          printf '{}\n' > "$runtime_json"
        fi
        ${pkgs.yq-go}/bin/yq -p toml -o json "$REPO_ROOT/config/codex/config.toml" > "$base_json"
        ${pkgs.yq-go}/bin/yq -p toml -o json ${codexMcpConfig} > "$mcp_json"
        if [ -f "$REPO_ROOT/hosts/$HOST/codex-config.toml" ]; then
          ${pkgs.yq-go}/bin/yq -p toml -o json "$REPO_ROOT/hosts/$HOST/codex-config.toml" > "$host_json"
        else
          printf '{}\n' > "$host_json"
        fi

        ${pkgs.jq}/bin/jq -s '
          .[0] as $runtime | .[1] as $base | .[2] as $mcp | .[3] as $host |
          ($runtime * $base * $host) | .mcp_servers = $mcp.mcp_servers
        ' "$runtime_json" "$base_json" "$mcp_json" "$host_json" > "$merged_json"
        ${pkgs.yq-go}/bin/yq -p json -o toml "$merged_json" > "$merged_toml"
        $DRY_RUN_CMD mv "$merged_toml" "$CODEX_DIR/config.toml"
        rm -f "$runtime_json" "$base_json" "$mcp_json" "$host_json" "$merged_json" "$merged_toml"

        # AGENTS.md - common + host-specific context.
        if [ -f "$REPO_ROOT/hosts/$HOST/claude-memory.md" ]; then
          tmp=$(mktemp)
          cat "$REPO_ROOT/config/codex/AGENTS.md" > "$tmp"
          printf '\n' >> "$tmp"
          cat "$REPO_ROOT/hosts/$HOST/claude-memory.md" >> "$tmp"
          $DRY_RUN_CMD mv "$tmp" "$CODEX_DIR/AGENTS.md"
        else
          $DRY_RUN_CMD cp -fL "$REPO_ROOT/config/codex/AGENTS.md" "$CODEX_DIR/AGENTS.md"
        fi

        # Keep mutable or externally installed entries and replace only the
        # names managed by this repository.
        for f in "$REPO_ROOT/config/codex/agents"/*.toml; do
          $DRY_RUN_CMD ln -sfn "$f" "$CODEX_DIR/agents/$(basename "$f")"
        done
        for f in "$REPO_ROOT/config/codex/rules"/*.rules; do
          $DRY_RUN_CMD ln -sfn "$f" "$CODEX_DIR/rules/$(basename "$f")"
        done
        for f in "$REPO_ROOT/config/codex/skills"/*; do
          $DRY_RUN_CMD ln -sfn "$f" "$CODEX_DIR/skills/$(basename "$f")"
        done
        $DRY_RUN_CMD ln -sfn "$REPO_ROOT/config/codex/hooks.json" "$CODEX_DIR/hooks.json"
      '';

      # SbarLua installation (symlink to expected location)
      sbarluaSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.local/share/sketchybar_lua
        ln -sf ${sbarluaPkg}/lib/sketchybar_lua/sketchybar.so $HOME/.local/share/sketchybar_lua/sketchybar.so
      '';

      # Rustup initialization
      rustupSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if command -v rustup >/dev/null 2>&1; then
          # Install stable toolchain if not already installed
          if ! $DRY_RUN_CMD rustup toolchain list | grep -q stable; then
            $DRY_RUN_CMD rustup default stable
          fi

          # Install rust-analyzer component
          $DRY_RUN_CMD rustup component add rust-analyzer
        fi
      '';

      # npm user config (~/.npmrc): upsert specific keys without touching
      # auth tokens / scoped registries that external tools (e.g. gcloud
      # google-artifactregistry-auth) write to the same file.
      npmSecurityConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm config set min-release-age 7 --location=user
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npm config set registry https://npm.flatt.tech --location=user
      '';
    };
  };

  # Disable manpages to avoid builtins.toFile warning with Determinate Nix
  # See: https://github.com/nix-community/home-manager/issues/7935
  manual.manpages.enable = false;

  # Services
  services = {
    # Colima container runtime
    colima = {
      enable = true;
      profiles = {
        # aarch64 profile (Apple Silicon native)
        docker-build-aarch64 = {
          isService = false; # Manual start/stop (not auto-start)
          isActive = false; # Don't set as active context (manual switching)
          settings = {
            cpu = 4;
            memory = 8;
            disk = 100;
            arch = "aarch64";
            runtime = "docker";
            vmType = "vz";
            rosetta = true;
            kubernetes.enabled = false;
            network = {
              address = false;
              mode = "shared";
            };
            mountType = "virtiofs";
            mounts = [
              {
                location = "~/ghq/src";
                writable = true;
              }
            ];
          };
        };
        # x86_64 profile (AMD64 emulation)
        docker-build-amd64 = {
          isService = false; # Manual start/stop (not auto-start)
          isActive = false; # Don't set as active context (manual switching)
          settings = {
            cpu = 4;
            memory = 8;
            disk = 100;
            arch = "x86_64";
            runtime = "docker";
            vmType = "vz";
            rosetta = true;
            kubernetes.enabled = false;
            network = {
              address = false;
              mode = "shared";
            };
            mountType = "virtiofs";
            mounts = [
              {
                location = "~/ghq/src";
                writable = true;
              }
            ];
          };
        };
      };
    };
  };

  programs = {
    # Let Home Manager manage itself
    home-manager.enable = true;

    # AeroSpace window manager
    aerospace = {
      enable = true;
      settings = {
        # Basic settings
        "config-version" = 2;

        # Configure environment for exec commands
        exec = {
          inherit-env-vars = true;
          env-vars = {
            PATH = "/etc/profiles/per-user/${config.home.username}/bin:/opt/homebrew/bin:\${PATH}";
          };
        };

        # Start JankyBorders and SketchyBar after startup
        "after-startup-command" = [
          "exec-and-forget /opt/homebrew/bin/borders"
          "exec-and-forget /opt/homebrew/bin/sketchybar"
          "exec-and-forget open -a Alacritty"
          "exec-and-forget open -a Slack"
        ];

        # Normalizations
        "enable-normalization-flatten-containers" = true;
        "enable-normalization-opposite-orientation-for-nested-containers" = true;

        # Layout settings
        "accordion-padding" = 30;
        "default-root-container-layout" = "tiles";
        "default-root-container-orientation" = "auto";

        # Mouse follows focus when focused monitor changes
        "on-focused-monitor-changed" = [ "move-mouse monitor-lazy-center" ];

        # Notify SketchyBar about workspace change
        "exec-on-workspace-change" = [
          "/bin/bash"
          "-c"
          "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
        ];

        # Gaps between windows
        gaps = {
          inner = {
            horizontal = 8;
            vertical = 8;
          };
          outer = {
            left = 8;
            bottom = 8;
            top = [
              { monitor."DELL U2723QE" = 52; }
              8
            ];
            right = 8;
          };
        };

        # Window rules
        "on-window-detected" = [
          {
            "if"."app-id" = "org.alacritty";
            run = "move-node-to-workspace 1";
          }
          {
            "if" = {
              "app-id" = "com.google.Chrome";
              "window-title-regex-substring" = "PiP";
            };
            run = "layout floating";
          }
          {
            "if"."app-id" = "com.google.Chrome";
            run = "move-node-to-workspace 9";
          }
          {
            "if"."app-id" = "com.tinyspeck.slackmacgap";
            run = "move-node-to-workspace 2";
          }
          {
            "if"."app-id" = "jp.naver.line.mac";
            run = "move-node-to-workspace 2";
          }
          {
            "if"."app-id" = "us.zoom.xos";
            run = "move-node-to-workspace 3";
          }
          {
            "if"."app-id" = "com.chocoford.excalidraw";
            run = "move-node-to-workspace 7";
          }
          {
            "if"."app-id" = "md.obsidian";
            run = "move-node-to-workspace 8";
          }
          {
            "if"."app-id" = "com.amazon.Lassen";
            run = "move-node-to-workspace 4";
          }
        ];

        # Main binding mode
        mode.main.binding = {
          # Layout
          "alt-slash" = "layout tiles horizontal vertical";
          "alt-comma" = "layout accordion horizontal vertical";

          # Focus (vim-style, ignore floating windows)
          "alt-h" = "focus --ignore-floating left";
          "alt-j" = "focus --ignore-floating down";
          "alt-k" = "focus --ignore-floating up";
          "alt-l" = "focus --ignore-floating right";

          # Focus floating window (Chrome PiP)
          "alt-f" = ''
            exec-and-forget
            id=$(aerospace list-windows --workspace focused --format '%{window-id}|%{window-title}' | grep 'PiP' | head -1 | cut -d'|' -f1)
            if [ -n "$id" ]; then
                aerospace focus --window-id "$id"
            fi
          '';

          # Move window (vim-style)
          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          # Resize
          "alt-minus" = "resize smart -50";
          "alt-equal" = "resize smart +50";

          # Workspaces (1-9)
          "alt-1" = "workspace 1";
          "alt-2" = "workspace 2";
          "alt-3" = "workspace 3";
          "alt-4" = "workspace 4";
          "alt-5" = "workspace 5";
          "alt-6" = "workspace 6";
          "alt-7" = "workspace 7";
          "alt-8" = "workspace 8";
          "alt-9" = "workspace 9";

          # Move window to workspace
          "alt-shift-1" = "move-node-to-workspace 1";
          "alt-shift-2" = "move-node-to-workspace 2";
          "alt-shift-3" = "move-node-to-workspace 3";
          "alt-shift-4" = "move-node-to-workspace 4";
          "alt-shift-5" = "move-node-to-workspace 5";
          "alt-shift-6" = "move-node-to-workspace 6";
          "alt-shift-7" = "move-node-to-workspace 7";
          "alt-shift-8" = "move-node-to-workspace 8";
          "alt-shift-9" = "move-node-to-workspace 9";

          # Toggle Chrome between current workspace and workspace 9
          "alt-o" = ''
            exec-and-forget
            current_ws=$(aerospace list-workspaces --focused)
            info=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{workspace}' | grep "Google Chrome" | head -1)
            id=$(echo "$info" | awk -F'|' '{print $1}')
            ws=$(echo "$info" | awk -F'|' '{print $3}')
            if [ -n "$id" ]; then
                if [ "$ws" = "$current_ws" ]; then
                    aerospace move-node-to-workspace --window-id "$id" 9
                else
                    aerospace move-node-to-workspace --window-id "$id" "$current_ws"
                    osascript -e 'tell application "Google Chrome" to activate'
                fi
                sleep 0.1
                /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
            fi
          '';

          # Toggle Slack between current workspace and workspace 2
          "alt-i" = ''
            exec-and-forget
            current_ws=$(aerospace list-workspaces --focused)
            info=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{workspace}' | grep "Slack" | head -1)
            id=$(echo "$info" | awk -F'|' '{print $1}')
            ws=$(echo "$info" | awk -F'|' '{print $3}')
            if [ -n "$id" ]; then
                if [ "$ws" = "$current_ws" ]; then
                    aerospace move-node-to-workspace --window-id "$id" 2
                else
                    aerospace move-node-to-workspace --window-id "$id" "$current_ws"
                    osascript -e 'tell application "Slack" to activate'
                fi
                sleep 0.1
                /opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
            fi
          '';

          # Workspace navigation
          "alt-tab" = "workspace-back-and-forth";
          "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";

          # Service mode
          "alt-shift-semicolon" = "mode service";
        };

        # Service binding mode
        mode.service.binding = {
          esc = [
            "reload-config"
            "mode main"
          ];
          r = [
            "flatten-workspace-tree"
            "mode main"
          ];
          f = [
            "layout floating tiling"
            "mode main"
          ];
          backspace = [
            "close-all-windows-but-current"
            "mode main"
          ];

          "alt-shift-h" = [
            "join-with left"
            "mode main"
          ];
          "alt-shift-j" = [
            "join-with down"
            "mode main"
          ];
          "alt-shift-k" = [
            "join-with up"
            "mode main"
          ];
          "alt-shift-l" = [
            "join-with right"
            "mode main"
          ];
        };
      };
    };

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
        aws = {
          symbol = " ";
          disabled = false;
        };
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
        nix_shell.symbol = " ";
        # Claude Code statusline modules
        profiles.claude-code = "$directory$git_branch| $claude_model| $claude_context";
        claude_model = {
          format = "[\$symbol\$model](\$style) ";
          symbol = "󰚩 ";
          style = "bold purple";
        };
        claude_context = {
          format = "[\$gauge \$percentage](\$style) ";
          gauge_width = 8;
          display = [
            {
              threshold = 0;
              style = "bold green";
              hidden = true;
            }
            {
              threshold = 30;
              style = "bold green";
              hidden = false;
            }
            {
              threshold = 60;
              style = "bold yellow";
              hidden = false;
            }
            {
              threshold = 80;
              style = "bold red";
              hidden = false;
            }
          ];
        };
        claude_cost.disabled = true;
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
      signing = {
        format = "ssh";
        signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        signByDefault = true;
      };
      ignores = [
        ".idea/*"
        ".envrc"
        ".go-version"
        ".node-version"
        ".DS_Store"
        ".claude/"
        "CLAUDE.md"
        "CLAUDE.local.md"
        ".playwright-mcp/"
      ];
      settings = {
        alias = {
          cm = "checkout main";
          graph = "log --graph --date-order -C -M --pretty=format:\"<%h> %ad [%an] %Cgreen%d%Creset %s\" --all --date=short";
          undo = "reset --soft HEAD^";
        };
        ghq = {
          root = "~/ghq/src";
          afterClone = "git submodule update --init --recursive";
        };
        merge.conflictstyle = "diff3";
        pull.rebase = true;
        init.defaultBranch = "main";
        core.ignorecase = false;
        credential.helper = "cache --timeout=3600";
        gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
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

    # Helix editor (theme is managed by akari-theme module)
    helix = {
      enable = true;
      defaultEditor = false; # Using sessionVariables for EDITOR
      settings = {
        theme = "akari-night";
        editor = {
          true-color = true;
          cursorline = true;
          color-modes = true;
          auto-completion = true;
          auto-save = true;
          auto-format = true;
          auto-pairs = true;
          end-of-line-diagnostics = "hint";
          clipboard-provider = "pasteboard";
          mouse = false;
          statusline = {
            left = [
              "mode"
              "spinner"
              "version-control"
            ];
            center = [ "file-name" ];
            right = [
              "diagnostics"
              "selections"
              "position"
              "file-encoding"
              "file-type"
            ];
            separator = "│";
          };
          lsp = {
            display-messages = true;
            auto-signature-help = true;
            display-inlay-hints = false;
            display-signature-help-docs = true;
            snippets = true;
            goto-reference-include-declaration = true;
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          file-picker = {
            hidden = false;
            follow-symlinks = true;
            deduplicate-links = true;
            parents = true;
            ignore = true;
            git-ignore = true;
            git-global = true;
            git-exclude = true;
          };
          search = {
            smart-case = true;
            wrap-around = true;
          };
          whitespace.render = "none";
          gutters.layout = [
            "diff"
            "diagnostics"
            "line-numbers"
            "spacer"
          ];
          soft-wrap.enable = false;
        };
        keys = {
          normal = {
            p = "paste_clipboard_after";
            P = "paste_clipboard_before";
            y = "yank_to_clipboard";
            Y = "yank_joined_to_clipboard";
            d = [
              "yank_to_clipboard"
              "delete_selection_noyank"
            ];
            b = ":echo %sh{git blame --date=short -L %{cursor_line},+1 %{buffer_name} | cut -d' ' -f1-4 | sed 's/$/)/g'}";
            B = ":echo %sh{git show --no-patch --format='%h (%an: %ar): %s' $(git blame -p %{buffer_name} -L%{cursor_line},+1 | head -1 | cut -d' ' -f1)}";
          };
          select = {
            p = "paste_clipboard_after";
            P = "paste_clipboard_before";
            y = "yank_to_clipboard";
            Y = "yank_joined_to_clipboard";
            R = "replace_selections_with_clipboard";
            d = [
              "yank_to_clipboard"
              "delete_selection_noyank"
            ];
          };
          insert = {
            j.j = "normal_mode";
          };
        };
      };
      languages = {
        use-grammars = {
          except = [
            "hare"
            "wgsl"
          ];
        };
        language = [
          # Go
          {
            name = "go";
            scope = "source.go";
            file-types = [ "go" ];
            roots = [
              "go.work"
              "go.mod"
            ];
            auto-format = true;
            comment-token = "//";
            language-servers = [ "gopls" ];
            formatter = {
              command = "goimports";
            };
            indent = {
              tab-width = 4;
              unit = "\t";
            };
          }
          # Rust
          {
            name = "rust";
            scope = "source.rust";
            roots = [
              "Cargo.toml"
              "Cargo.lock"
            ];
            auto-format = true;
            language-servers = [ "rust-analyzer" ];
          }
          # YAML
          {
            name = "yaml";
            scope = "source.yaml";
            file-types = [
              "yml"
              "yaml"
            ];
            comment-token = "#";
            language-servers = [ "yaml-language-server" ];
            formatter = {
              command = "yamlfmt";
              args = [ "-" ];
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # JSON
          {
            name = "json";
            scope = "source.json";
            file-types = [ "json" ];
            language-servers = [ "vscode-json-language-server" ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "file.json"
              ];
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # TOML
          {
            name = "toml";
            scope = "source.toml";
            injection-regex = "toml";
            file-types = [ "toml" ];
            comment-token = "#";
            language-servers = [ "taplo" ];
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            auto-format = true;
          }
          # Markdown
          {
            name = "markdown";
            scope = "source.md";
            injection-regex = "md|markdown";
            file-types = [
              "md"
              "markdown"
              "PULLREQ_EDITMSG"
              "ISSUE_EDITMSG"
            ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "file.md"
              ];
            };
            auto-format = false;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # Dockerfile
          {
            name = "dockerfile";
            scope = "source.dockerfile";
            file-types = [
              "Dockerfile"
              "dockerfile"
            ];
            comment-token = "#";
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # Bash/Shell
          {
            name = "bash";
            scope = "source.bash";
            injection-regex = "(shell|bash|zsh|sh)";
            file-types = [
              "sh"
              "bash"
              "zsh"
              "zsh-theme"
              { glob = ".zshenv"; }
              { glob = ".zshrc"; }
              { glob = ".zprofile"; }
              { glob = ".bashrc"; }
              { glob = ".bash_profile"; }
              { glob = ".bash_login"; }
              { glob = ".profile"; }
            ];
            shebangs = [
              "sh"
              "bash"
              "dash"
              "zsh"
            ];
            comment-token = "#";
            language-servers = [ "bash-language-server" ];
            formatter = {
              command = "shfmt";
              args = [
                "-i"
                "2"
              ];
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # CSS
          {
            name = "css";
            scope = "source.css";
            file-types = [ "css" ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "file.css"
              ];
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # HTML
          {
            name = "html";
            scope = "text.html.basic";
            file-types = [ "html" ];
            formatter = {
              command = "prettier";
              args = [
                "--stdin-filepath"
                "file.html"
              ];
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # JavaScript
          {
            name = "javascript";
            scope = "source.js";
            file-types = [
              "js"
              "mjs"
            ];
            language-servers = [ "typescript-language-server" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # TypeScript
          {
            name = "typescript";
            scope = "source.ts";
            file-types = [ "ts" ];
            language-servers = [ "typescript-language-server" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # TSX
          {
            name = "tsx";
            scope = "source.tsx";
            file-types = [ "tsx" ];
            language-servers = [ "typescript-language-server" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # Lua
          {
            name = "lua";
            scope = "source.lua";
            file-types = [ "lua" ];
            language-servers = [ "lua-language-server" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # HCL / Terraform
          {
            name = "hcl";
            scope = "source.hcl";
            language-id = "terraform";
            injection-regex = "(hcl|tf|nomad)";
            file-types = [
              "hcl"
              "tf"
              "nomad"
            ];
            comment-token = "#";
            block-comment-tokens = {
              start = "/*";
              end = "*/";
            };
            language-servers = [ "terraform-ls" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # Terraform variables
          {
            name = "tfvars";
            scope = "source.tfvars";
            language-id = "terraform-vars";
            grammar = "hcl";
            file-types = [ "tfvars" ];
            comment-token = "#";
            block-comment-tokens = {
              start = "/*";
              end = "*/";
            };
            language-servers = [ "terraform-ls" ];
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
          # Fish
          {
            name = "fish";
            scope = "source.fish";
            file-types = [ "fish" ];
            comment-token = "#";
            language-servers = [ "fish-lsp" ];
            formatter = {
              command = "fish_indent";
            };
            auto-format = true;
            indent = {
              tab-width = 2;
              unit = "  ";
            };
          }
        ];
        language-server = {
          gopls = {
            command = "gopls";
            args = [ "serve" ];
          };
          rust-analyzer = {
            command = "rust-analyzer";
            config.check.command = "clippy";
          };
          yaml-language-server = {
            command = "yaml-language-server";
            args = [ "--stdio" ];
          };
          vscode-json-language-server = {
            command = "vscode-json-language-server";
            args = [ "--stdio" ];
          };
          taplo = {
            command = "taplo";
            args = [
              "lsp"
              "stdio"
            ];
          };
          bash-language-server = {
            command = "bash-language-server";
            args = [ "start" ];
          };
          typescript-language-server = {
            command = "typescript-language-server";
            args = [ "--stdio" ];
          };
          lua-language-server = {
            command = "lua-language-server";
          };
          terraform-ls = {
            command = "terraform-ls";
            args = [ "serve" ];
          };
          fish-lsp = {
            command = "fish-lsp";
            args = [ "start" ];
          };
        };
      };
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
            # Store path, not bare "herdr": PATH may resolve to a stale
            # manual install, and version skew aborts the client
            "exec ${lib.getExe herdr-pkg}"
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

    # Zsh
    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "viins"; # Start in vi insert mode

      # LANG cannot live in sessionVariables: home-manager emits those behind a
      # __HM_ZSH_SESS_VARS_SOURCED once-guard (from .zprofile for login shells,
      # which is what herdr panes are), and the long-lived herdr server hands
      # panes that flag without the variables it protects, leaving them in the
      # C locale where ZLE mangles multibyte input. Keyed on LANG being absent
      # rather than exported unconditionally, so `LANG=xx zsh -c ...` wins.
      envExtra = ''
        [[ -n "$LANG" ]] || export LANG="en_US.UTF-8"
      '';

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

      initContent = ''
        # Deduplicate PATH entries
        typeset -U path

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
      '';

      # Zsh options and environment variables
      # LG_CONFIG_FILE is managed by akari-theme module
      sessionVariables = {
        KEYTIMEOUT = "20";
        EDITOR = "hx";
        VISUAL = "hx";
        CVSEDITOR = "hx";
        SVN_EDITOR = "hx";
        GIT_EDITOR = "hx";
        GEM_HOME = "$HOME/.gem/ruby";
      };

      shellAliases = {
        # Navigation
        ".." = "cd ..";
        l = "ls -l";
        ll = "ls -lF";
        lla = "ls -lAF";
        la = "ls -AF";
        lx = "ls -lXB";
        lk = "ls -lSr";
        lc = "ls -ltcr";
        lu = "ls -ltur";
        lt = "ls -ltr";
        lr = "ls -lR";

        # System utilities
        du = "du -h";
        job = "jobs -l";
        grep = "grep --color=auto";
        fgrep = "fgrep --color=auto";
        egrep = "egrep --color=auto";

        # macOS specific
        flushdns = "sudo killall -HUP mDNSResponder";

        # Git
        gst = "git status";

        # Kubernetes
        k = "kubectl";

        # Colima profiles (aarch64 and amd64)
        colima-aarch64-start = "colima start docker-build-aarch64 --save-config=false";
        colima-aarch64-stop = "colima stop docker-build-aarch64";
        colima-aarch64-status = "colima status docker-build-aarch64";

        colima-amd64-start = "colima start --profile docker-build-amd64 --arch x86_64 --cpu 4 --memory 8 --vm-type vz --save-config=false";
        colima-amd64-stop = "colima stop docker-build-amd64";
        colima-amd64-status = "colima status docker-build-amd64";

        # Tools (Nix-managed, always available)
        ls = "eza";
        lg = "lazygit";
        vim = "hx";
      };
    };
  };

  xdg = {
    # XDG Base Directory
    enable = true;

    # Config files
    configFile = {
      # AeroSpace is managed by programs.aerospace

      # Git allowed signers (for `git log --show-signature` verification)
      "git/allowed_signers".source = ../../config/git/allowed_signers;

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

      # Helix is managed by programs.helix + akari-theme module

      # Starship is managed by programs.starship + akari-theme module

      # pnpm global config (supply-chain hardening via release cooldown)
      "pnpm/rc".text = ''
        minimumReleaseAge=10080
      '';

      # Zsh config files
      "zsh/10_aliases.zsh".source = ../../config/zsh/10_aliases.zsh;
      "zsh/20_keybinds.zsh".source = ../../config/zsh/20_keybinds.zsh;
      "zsh/30_fzf.zsh".source = ../../config/zsh/30_fzf.zsh;
      "zsh/40_integrations.zsh".source = ../../config/zsh/40_integrations.zsh;

      # Bat theme, Lazygit themes, and gh-dash are managed by akari-theme module

      # Karabiner-Elements (force to avoid .backup conflict with Karabiner's own backup)
      "karabiner/karabiner.json" = {
        source = ../../config/karabiner/karabiner.json;
        force = true;
      };

      # Herdr (agent multiplexer, the Alacritty entry point)
      "herdr/config.toml".source = ../../config/herdr/config.toml;

      # Scripts
      "scripts/set-wallpaper.py" = {
        source = ../../config/scripts/set-wallpaper.py;
        executable = true;
      };
    };
  };

}
