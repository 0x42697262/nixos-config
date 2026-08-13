# ct-home -- Amazon EC2 instance. See README.md for setup/rebuild steps.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
{ config, inputs, ... }:
let
  # Real names come from /etc/nixos/domains.nix on the box and
  # only when the rebuild runs with --impure. Otherwise these are placeholders.
  # See modules/common/site.nix and README.
  gitHost = "${config.mySite.subdomains.git}.${config.mySite.domain}";
  headscaleHost = "${config.mySite.subdomains.headscale}.${config.mySite.domain}";
  tankHost = "${config.mySite.subdomains.tank}.${config.mySite.domain}";
in
{
  imports = [
    ../../modules/roles/ec2.nix
    inputs.tanka-maze.nixosModules.default
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

  myProfiles.gitlab = {
    enable = true;
    host = gitHost;
    secretsDir = "/etc/nixos/secrets/gitlab"; # see the option's description in modules/profiles/gitlab.nix.
  };

  services.tanka-maze = {
    enable = true;
    host = "127.0.0.1";
    port = 8000;
    trustProxy = true;
    allowedOrigins = [ "https://${tankHost}" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts."${headscaleHost}".extraConfig = ''
      reverse_proxy 127.0.0.1:7000
    '';
    virtualHosts."${gitHost}".extraConfig = ''
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    '';
    virtualHosts."${tankHost}".extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:8000 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
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
