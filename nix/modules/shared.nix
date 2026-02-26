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
    # Workaround for HM claude-code module --append-flags bug.
    # Merged across host configs, then baked into a custom-wrapped package.
    claudeMcpServers = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "MCP servers for Claude Code";
    };
  };
}
