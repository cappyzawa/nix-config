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
      ...
    }@inputs:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
      mkDarwin = import ./lib/mkdarwin.nix { inherit inputs; };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      darwinConfigurations.cappyzawa = mkDarwin "cappyzawa" { };

      darwinConfigurations.arkedge = mkDarwin "arkedge" {
        user = "kutsuzawa-shu";
      };
    };
}
