{
  description = "This bird's flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # nixpkgs.url = "nixpkgs/nixos-unstable-small";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , rust-overlay
    , ...
    }:
    let
      lib = nixpkgs.lib;
    in

    {
      nixosConfigurations = {
        AtomicBird = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ rust-overlay.overlays.default ];
              environment.systemPackages = [
                pkgs.rust-bin.stable.latest.default
                pkgs.rust-analyzer
                pkgs.rustup
              ];
            })
          ];
        };
      };
    };
}
