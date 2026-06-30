# hostpc -- desktop workstation. Stub: flesh out as the machine is set up.
# A hardware.nix (from `nixos-generate-config`) and a desktop module
{ ... }: {
  # imports = [ ./hardware.nix ];

  # A desktop workstation: interactive tooling + a graphical environment.
  # (desktop.nix is still a scaffold -- fill in the DE there.)
  myProfiles.interactive.enable = true;
  myProfiles.desktop.enable = true;

  networking.hostName = "hostpc";

  system.stateVersion = "25.11";
}
