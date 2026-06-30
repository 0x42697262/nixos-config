{
  description = "My personal NixOS configuration for host, VMs, and WSL2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    flake-utils.url = "github:numtide/flake-utils";

    ctSecrets = {
      url = "path:/etc/nixos/secrets";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, flake-utils, ... }@inputs:
    let
      mkHost = { system, modules ? [ ] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit self inputs; };
          modules = [ ./modules/common ./modules/profiles ] ++ modules;
        };
    in
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
        wsl2-tgt = mkHost {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl2-tgt
          ];
        };

        wsl-work-ct = mkHost {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.default
            ./hosts/wsl-work-ct
          ];
        };

        ct-home = mkHost {
          system = "aarch64-linux";
          modules = [ ./hosts/ct-home ];
        };

        hostpc = mkHost {
          system = "x86_64-linux";
          modules = [ ./hosts/hostpc ];
        };

        vm1 = mkHost {
          system = "x86_64-linux";
          modules = [ ./hosts/vm1 ];
        };

        # work-ct = mkHost {
        #   system = "x86_64-linux";
        #   modules = [ ./hosts/work-ct ];
        # };
      };
    };
}
