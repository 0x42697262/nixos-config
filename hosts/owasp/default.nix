{ modulesPath, ... }: {
  imports = [
    ../../modules/roles/incus.nix
  ];

  networking.hostName = "owasp";

  myProfiles.security = {
    web.enable = true;
    reversing.enable = true;
    crypto.enable = true;
  };

  system.stateVersion = "26.11";
}
