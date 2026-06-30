# Role: ec2
# Shared baseline for our Amazon EC2 instances. Import it from a host:
#   imports = [ ../../modules/roles/ec2.nix ];
# Each host then only adds its own delta (stateVersion, extra services, ...).
{ modulesPath, lib, ... }: {
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # Most modern (Nitro / Graviton) instances boot via UEFI. Override per host
  # (ec2.efi = false;) for older x86_64 instance types.
  ec2.efi = lib.mkDefault true;

  # EC2 boxes are headless servers, so the interactive profile stays off (it
  # already defaults off). Add config shared by ALL our instances below --
  # monitoring agents, SSH policy, base firewall rules, etc.
}
