{
  description = "This bird's flake";
  inputs = {
    # I only want to use unstable version like arch.
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Home-manager, unstable
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";


    ## Some github repositories:
    ## 

    # For styling
    stylix.url = "github:danth/stylix";

    # better Rust toolchain
    rust-overlay.url = "github:oxalica/rust-overlay";

  };




  outputs =
    inputs@{ self
    , nixpkgs
    , home-manager

    , stylix
    , rust-overlay
    , ...
    }:
    let
      # ---- SYSTEM SETTINGS ---- #
      systemSettings = {
        system = "x86_64-linux"; # system arch
        hostname = "AtomicBird"; # hostname
        profile = "personal"; # select a profile defined from my profiles directory
        timezone = "Asia/Tokyo"; # select timezone
        locale = "ja_JP.UTF-8"; # select locale
        locale_time = "ja_JP.UTF-8"; # select locale time
        bootMode = "uefi"; # uefi or bios
        bootMountPath = "/boot"; # mount path for efi boot partition; only used for uefi boot mode
      };
      # configure lib
      lib = nixpkgs.lib;

      # Systems that can run tests:
      supportedSystems = [ "aarch64-linux" "i686-linux" "x86_64-linux" ];

      # Function to generate a set based on supported systems:
      forAllSystems = inputs.nixpkgs.lib.genAttrs supportedSystems;

      # Attribute set of nixpkgs for each system:
      nixpkgsFor =
        forAllSystems (system: import inputs.nixpkgs { inherit system; });

    in

    {
      nixosConfigurations = {
        hostname = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.birb = import ./home.nix;

              # Optionally, use home-manager.extraSpecialArgs to pass
              # arguments to home.nix
            }

            stylix.nixosModules.stylix

            ({ pkgs, ... }: {
              nixpkgs.overlays = [ rust-overlay.overlays.default ];
              environment.systemPackages = [ pkgs.rust-bin.stable.latest.default ];
            })

          ];
        };
      };
    };
}
