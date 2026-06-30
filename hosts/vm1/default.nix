# vm1 -- scratch VM. Stub: add a hardware.nix and any extras before deploying.
{ ... }: {
  # imports = [ ./hardware.nix ];

  networking.hostName = "vm1";

  system.stateVersion = "25.11";
}
