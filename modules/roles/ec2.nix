# Role: ec2
# Shared baseline for our Amazon EC2 instances. Import it from a host:
#   imports = [ ../../modules/roles/ec2.nix ];
# Each host then only adds its own delta (stateVersion, extra services, ...).
{ modulesPath, lib, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # The EC2 AMI's EFI partition is only ~249 MiB and each kernel+initrd is
  # ~89 MiB. GRUB copies the new generation's kernel before pruning old ones,
  # so a switch peaks at (limit + 1) distinct kernels. Only limit = 1 (peak of
  # two kernels, ~178 MiB) is guaranteed to fit; higher values overflow /boot on
  # a kernel bump. Runtime rollback still works via `nixos-rebuild --rollback`.
  boot.loader.grub.configurationLimit = 2;

  # Most modern (Nitro / Graviton) instances boot via UEFI. Override per host
  # (ec2.efi = false;) for older x86_64 instance types.
  ec2.efi = lib.mkDefault true;

  myProfiles.server.enable = true;
}
