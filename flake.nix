{
  description = "My personal NixOS configuration for host, VMs, and WSL2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixos-wsl, flake-utils, ... }:
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
            ./hosts/wsl2-tgt/configuration.nix
            ./modules/common/editors.nix
            ./modules/common/nix.nix
            ./modules/common/shells.nix
            ./modules/common/users.nix
            # ./modules/wsl.nix
          ];
        };

        work-ct = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/vms/work-ct/configuration.nix
            ./modules/common/editors.nix
            ./modules/common/nix.nix
            ./modules/common/shells.nix
            ./modules/common/users.nix
            # ./modules/wsl.nix
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
