# ct-home -- Amazon EC2 instance. See README.md for setup/rebuild steps.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
{ inputs, lib, ... }:
let
  # /etc/nixos/ct-secrets/domain on the box -- NOT in git. See README.
  domain = lib.fileContents (inputs.ctSecrets + "/domain");
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
    address = "0.0.0.0";
    port = 443;
    settings = {
      server_url = "https://${domain}";

      tls_letsencrypt_hostname = domain;
      tls_letsencrypt_challenge_type = "TLS-ALPN-01";

      dns = {
        magic_dns = false;
        nameservers.global = [ "1.1.1.1" "1.0.0.1" ];
      };
    };
  };


  systemd.services.headscale.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  services.tanka-maze = {
    enable = true;
    host = "127.0.0.1";
    port = 8081;
    trustProxy = true;
    allowedOrigins = [ "https://${domain}:8080" ];
  };

  services.caddy = {
    enable = true;
    globalConfig = ''
      https_port 8080
    '';
    virtualHosts.${domain}.extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:8081 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 443 80 8080 ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
