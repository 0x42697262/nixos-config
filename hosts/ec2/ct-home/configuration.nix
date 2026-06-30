# NixOS configuration for the "ct-home" Amazon EC2 instance.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)

{ modulesPath, config, lib, pkgs, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  ec2.efi = true;

  environment.systemPackages = with pkgs; [
    btop
    git
    neovim
    vim
    wget
  ];

  # This should match the NixOS release you first installed and generally
  # should not be changed on an upgrade. See the comment in any generated
  # configuration.nix for details.
  system.stateVersion = "26.05";
}
