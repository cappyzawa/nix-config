{
  description = "My Nix configuration for macOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    akari-theme.url = "github:cappyzawa/akari-theme";
    tpm = {
      url = "github:tmux-plugins/tpm";
      flake = false;
    };
    sbarlua = {
      url = "github:FelixKratz/SbarLua";
      flake = false;
    };
    gh-ghq-cd = {
      url = "github:cappyzawa/gh-ghq-cd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      akari-theme,
      tpm,
      sbarlua,
      gh-ghq-cd,
      ...
    }:
    let
      system = "aarch64-darwin";
      username = "cappyzawa";
      pkgs = nixpkgs.legacyPackages.${system};

      # SbarLua derivation
      sbarluaPkg = pkgs.stdenv.mkDerivation {
        pname = "sbarlua";
        version = "unstable";
        src = sbarlua;

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
    {
      formatter.${system} = pkgs.nixfmt-tree;

      # Packages for external flakes
      packages.${system}.sbarlua = sbarluaPkg;

      # Modules for external flakes (e.g., private work config)
      darwinModules = {
        default = ./nix/darwin;
        shared = ./nix/modules/shared.nix;
      };
      homeModules = {
        default = ./nix/home;
        shared = ./nix/modules/shared.nix;
      };

      darwinConfigurations.${username} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          ./nix/darwin
          { myConfig.includePersonalApps = true; }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [
                akari-theme.homeModules.default
              ];
              extraSpecialArgs = {
                inherit
                  username
                  tpm
                  sbarluaPkg
                  ;
                gh-ghq-cd-pkg = gh-ghq-cd.packages.${system}.gh-ghq-cd;
              };
              users.${username} = import ./nix/home;
            };
          }
        ];
      };
    };
}
