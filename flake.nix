{
  description = "Alexander's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixos/configuration.nix
          {
            # Pull select packages from nixos-unstable while the rest of the
            # system stays on stable. Add more here as needed.
            nixpkgs.overlays = [
              (_final: _prev: {
                redisinsight = nixpkgs-unstable.legacyPackages.${system}.redisinsight;
              })
            ];
          }
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.alexander = import ./home/alexander.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}
