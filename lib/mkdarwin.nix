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
      # Detect bundled Lua version
      luaDir=$(ls -d lua-* | head -1)

      # Build Lua first
      cd "$luaDir"
      make macosx CC=clang
      cd ..

      # Build SbarLua
      mkdir -p bin
      mv "$luaDir/src/liblua.a" bin/

      clang -std=c99 -O3 -g -shared -fPIC \
        -arch arm64 \
        src/*.c \
        -I"$luaDir/src" -Lbin -llua \
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
    ../hosts/${name}
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
          gws-pkg = inputs.googleworkspace-cli.packages.${system}.default;
        };
        users.${user} = import ../nix/home;
      };
    }
  ];
}
