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
    sbarlua = {
      url = "github:FelixKratz/SbarLua";
      flake = false;
    };
    gh-ghq-cd = {
      url = "github:cappyzawa/gh-ghq-cd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned to a release tag; nixpkgs lags herdr releases
    herdr = {
      url = "github:herdrdev/herdr/v0.8.0";
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

      darwinConfigurations = {
        cappyzawa = mkDarwin "cappyzawa" { };
        arkedge = mkDarwin "arkedge" { user = "kutsuzawa-shu"; };
        ubie = mkDarwin "ubie" { user = "shu.kutsuzawa"; };
      };
    };
}
