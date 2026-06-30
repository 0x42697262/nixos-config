# ct-home -- Amazon EC2 instance. See README.md for setup/rebuild steps.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
#
# EC2 plumbing (amazon-image, ec2.efi, SSH-key import, disk growth, headless
# server defaults) all comes from the shared EC2 role. This file only carries
# what's unique to THIS instance. The interactive profile stays off.
{ ... }: {
  imports = [
    ../../modules/roles/ec2.nix
  ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
