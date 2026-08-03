{
  description = "Alexander's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      # redisinsight is SSPL, classified as non-free by nixpkgs.
      allowedUnfree = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "redisinsight" ];
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/nixos/configuration.nix
          {
            nixpkgs.config.allowUnfreePredicate = allowedUnfree;
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
