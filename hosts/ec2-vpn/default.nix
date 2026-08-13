{ config, ... }:
let
  # Placeholders unless /etc/nixos/domains.nix is present and the rebuild ran
  # with --impure. See modules/common/site.nix.
  headscaleHost = "${config.mySite.subdomains.headscale}.${config.mySite.domain}";
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
      server_url = "https://${headscaleHost}";

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
    virtualHosts."${headscaleHost}".extraConfig = ''
      reverse_proxy 127.0.0.1:7000
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
