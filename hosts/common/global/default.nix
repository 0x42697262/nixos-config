{ inputs, outputs, ... }:

{
  imports = [
    ./nix.nix
  ];
  ++ (builtins.attrValues outputs.nixosModules);

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = {
      allowUnfree = true;
    };
  };

  security.polkit.enable = true;
}
