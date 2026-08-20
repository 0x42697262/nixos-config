{ ... }: {
  imports = [
    ../../modules/roles/incus.nix
  ];

  networking.hostName = "owasp";

  myProfiles.security = {
    web.enable = true;
    reversing.enable = true;
    crypto.enable = true;
    gui.enable = true;
  };
  myRoles.incus.gui.enable = true;
  myProfiles.browsers.enable = true;

  networking.firewall.allowedTCPPorts = [ 9876 ];

  system.stateVersion = "26.11";
}
