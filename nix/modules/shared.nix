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
    claudeMcpServers = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "MCP servers merged into ~/.claude.json at activation";
    };
  };
}
