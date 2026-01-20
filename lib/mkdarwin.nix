{ inputs }:

name:
{
  system ? "aarch64-darwin",
  user ? name,
}:

let
  pkgs = inputs.nixpkgs.legacyPackages.${system};

  sbarluaPkg = pkgs.stdenv.mkDerivation {
    pname = "sbarlua";
    version = "unstable";
    src = inputs.sbarlua;

    nativeBuildInputs = with pkgs; [
      clang
      gnumake
      readline
    ];

    buildInputs = [
      pkgs.apple-sdk_15
    ];

    buildPhase = ''
      # Build Lua first
      cd lua-5.4.7
      make macosx CC=clang
      cd ..

      # Build SbarLua
      mkdir -p bin
      mv lua-5.4.7/src/liblua.a bin/

      clang -std=c99 -O3 -g -shared -fPIC \
        -arch arm64 \
        src/*.c \
        -Ilua-5.4.7/src -Lbin -llua \
        -framework CoreFoundation \
        -o bin/sketchybar.so
    '';

    installPhase = ''
      mkdir -p $out/lib/sketchybar_lua
      cp bin/sketchybar.so $out/lib/sketchybar_lua/
    '';
  };
in
inputs.nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = {
    inherit inputs;
    configName = name;
    currentUser = user;
    username = user; # backward compatibility
  };

  modules = [
    ../nix/darwin
    ../hosts/${name}.nix
    inputs.home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "backup";
        sharedModules = [
          inputs.akari-theme.homeModules.default
        ];
        extraSpecialArgs = {
          inherit inputs sbarluaPkg;
          inherit (inputs) tpm;
          configName = name;
          currentUser = user;
          username = user;
          gh-ghq-cd-pkg = inputs.gh-ghq-cd.packages.${system}.gh-ghq-cd;
        };
        users.${user} = import ../nix/home;
      };
    }
  ];
}
