# hostpc -- desktop workstation. Stub: flesh out as the machine is set up.
# A hardware.nix (from `nixos-generate-config`) and a desktop module
{ ... }: {
  # imports = [ ./hardware.nix ];

  networking.hostName = "hostpc";

  system.stateVersion = "25.11";
}
