# vm1 -- scratch VM. Stub: add a hardware.nix and any extras before deploying.
{ ... }: {
  # imports = [ ./hardware.nix ];

  # Opt into capabilities as needed, e.g.:
  # myProfiles.interactive.enable = true;

  networking.hostName = "vm1";

  system.stateVersion = "25.11";
}
