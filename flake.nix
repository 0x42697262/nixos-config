{
  description = "chimkenjoy's flake";
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , systems
    , ...
    } @ inputs:
    let
      inherit (self) outputs;
      lib = nixpkgs.lib // home-manager.lib;
      forEachSystem = f: lib.genAttrs (import systems) (system: f fpkgsFor.${system});
      pkgsFor = lib.genAttrs (import systems) (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
    in
    {
      inherit lib;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      overlays = import ./overlays { inherit inputs outputs; };

      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      formatter = forEachSystem (pkgs: pkgs.alejandra);
      # devShells = forEachSystem (pkgs: import ./shell.nix { inherit pkgs; }); # i don't know the purpose of this, for now

      nixosConfigurations = {
        # Laptop
        AtomicBird = lib.nixosSystem {
          modules = [ ./hosts/AtomicBird ];
          specialArgs = {
            inherit inputs outputs;
          };
        };
      };
      # nixosConfigurations = {
      #   AtomicBird = lib.nixosSystem {
      #     system = "x86_64-linux";
      #     modules = [
      #       ./configuration.nix
      #       ({ pkgs, ... }: {
      #         nixpkgs.overlays = [ rust-overlay.overlays.default ];
      #         environment.systemPackages = [
      #           pkgs.rust-bin.stable.latest.default
      #           pkgs.rust-analyzer
      #           pkgs.rustup
      #         ];
      #       })
      #     ];
      #   };
      # };
    };

}
