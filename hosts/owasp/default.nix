{ modulesPath, ... }: {
  imports = [
    ../../modules/roles/incus.nix
  ];

  networking.hostName = "owasp";

  system.stateVersion = "26.11";
}
