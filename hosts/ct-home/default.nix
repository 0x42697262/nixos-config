# ct-home -- Amazon EC2 instance. See README.md for setup/rebuild steps.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
#
# amazon-image.nix provides SSH, the EC2 SSH-key import, disk growth and the
# bootloader -- don't re-declare them here. The hostname comes from EC2
# metadata. Base packages/locale come from modules/common.
{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # The instance boots via UEFI; required on aarch64/Graviton.
  ec2.efi = true;

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
