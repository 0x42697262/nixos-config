{
  description = "My personal NixOS configuration for host, VMs, and WSL2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-wsl, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        { formatter = pkgs.nixpkgs-fmt; }) // {
      nixosConfigurations = {
        wsl2-tgt = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl/wsl2-tgt/configuration.nix
            ./modules/common/editors.nix
            ./modules/common/nix.nix
            ./modules/common/shells.nix
            ./modules/common/users.nix
            # ./modules/wsl.nix
          ];
        };

        wsl-work-ct = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
	  specialArgs = {
	    inherit self inputs;
	  };
          modules = [
	     { nixpkgs.config.allowUnfree = true; }
            nixos-wsl.nixosModules.default
            ./hosts/wsl/ct/configuration.nix
            ./hosts/wsl/wsl.nix
          ];
        };

        hostpc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # ./hosts/hostpc/configuration.nix
            ./modules/common/editors.nix
            ./modules/common/nix.nix
            ./modules/common/shells.nix
            ./modules/common/users.nix
            # ./modules/desktop/gnome.nix
          ];
        };

        vm1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # ./hosts/vm1/configuration.nix
            ./modules/common/editors.nix
            # ./modules/common/nix.nix
            # ./modules/common/users.nix
          ];
        };
      };
    };
}
