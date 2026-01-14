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
        default = 22.0;
        description = "Default font size";
      };
    };
  };
}
