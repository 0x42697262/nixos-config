{
  description = "My personal NixOS configuration for host, VMs, and WSL2";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    flake-utils.url = "github:numtide/flake-utils";
    tanka-maze = {
      url = "github:0x42697262/tanka-maze/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

        ec2-game-server = mkHost {
          system = "aarch64-linux";
          modules = [ ./hosts/ec2-game-server ];
        };

        hostpc = mkHost {
          system = "x86_64-linux";
          modules = [ ./hosts/hostpc ];
        };

        vm1 = mkHost {
          system = "x86_64-linux";
          modules = [ ./hosts/vm1 ];
        };

        gitlab-runner = mkHost {
          system = "x86_64-linux";
          modules = [ ./hosts/gitlab-runner ];
        };

        # work-ct = mkHost {
        #   system = "x86_64-linux";
        #   modules = [ ./hosts/work-ct ];
        # };
      };
    };
}
