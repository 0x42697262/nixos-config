{ inputs, lib, ... }:
let
  domain = lib.fileContents (inputs.ctSecrets + "/domain");
  headscaleSubdomain = lib.fileContents (inputs.ctSecrets + "/headscale_subdomain");
in
{
  imports = [
    ../../modules/roles/ec2.nix
  ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  services.headscale = {
    enable = true;
    address = "127.0.0.1";
    port = 7000;
    settings = {
      server_url = "https://${headscaleSubdomain}.${domain}";

      dns = {
        magic_dns = false;
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."${headscaleSubdomain}.${domain}".extraConfig = ''
      reverse_proxy 127.0.0.1:7000
    '';
  };

  users.users.caddy.extraGroups = [ "gitlab" ];

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
