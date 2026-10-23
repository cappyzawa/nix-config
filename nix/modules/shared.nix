{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.shared = {
    fonts = {
      main = mkOption {
        type = types.str;
        default = "Moralerspace Argon";
        description = "Main font family used across applications";
      };
      size = mkOption {
        type = types.float;
        default = 20.0;
        description = "Default font size";
      };
    };
    mainApp = mkOption {
      type = types.submodule {
        options = {
          path = mkOption { type = types.str; };
          bundleId = mkOption { type = types.str; };
        };
      };
      default = {
        path = "/Applications/ChatGPT.app";
        bundleId = "com.openai.codex";
      };
      description = "Primary work app, pinned to the Dock and sent to AeroSpace workspace 1";
    };
    claudeMcpServers = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "MCP servers deployed to Claude Code and Codex at activation";
    };
  };
}
