{
    description = "Alexander NixOS";
    inputs = {
			nixpkgs.url = "nixpkgs/nixos-25.05";
			home-manager = {
	   		url = "github:nix-community/home-manager/release-25.05";
	    	inputs.nixpkgs.follows = "nixpkgs";
			};		
    };

    outputs = { self, nixpkgs, home-manager, ... }: {
			nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
	    	system = "x86_64-linux";
	    	modules = [
					./configuration.nix
					home-manager.nixosModules.home-manager
					{
		    		home-manager = {
							useGlobalPkgs = true;
							useUserPackages = true;
							users.alexander = import ./home.nix;
							backupFileExtension = "backup";
		    		};
					}
					({pkgs, ...}: {
						environment.systemPackages = with pkgs; [  
	              # rust packages						
								rustc          # Rust compiler
                cargo          # Rust package manager
  							rust-analyzer  # IDE support
        				rustfmt        # Formatter
        				clippy         # Linter
        				cargo-watch    # Auto-rebuild on file changes
				        cargo-edit     # cargo add/rm commands
				        sqlx-cli
				        lldb
				        clang
				        lld
				        
				        # other packages
  							typescript-language-server
  							llvm
  							nixfmt-rfc-style
  							openssl
  							openssl.dev
                pkg-config
             ];

            # This is the key part for Helix + rust-analyzer
    				environment.variables = {
        			RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
        			PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    				};
					})
	    ];
		};
  };
}
