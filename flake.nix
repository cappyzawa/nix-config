{
  description = "My Nix configuration for macOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      mkHome = username: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username; };
        modules = [ ./home.nix ];
      };
    in
    {
      homeConfigurations."cappyzawa" = mkHome "cappyzawa";
      # Add more users as needed:
      # homeConfigurations."work-user" = mkHome "work-user";
    };
}
