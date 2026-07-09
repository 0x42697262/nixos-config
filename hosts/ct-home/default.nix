# ct-home -- Amazon EC2 instance. See README.md for setup/rebuild steps.
#
# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
{ inputs, lib, ... }:
let
  # /etc/nixos/ct-secrets/domain on the box -- NOT in git. See README.
  domain = lib.fileContents (inputs.ctSecrets + "/domain");
  gitSubdomain = lib.fileContents (inputs.ctSecrets + "/git_subdomain");
  headscaleSubdomain = lib.fileContents (inputs.ctSecrets + "/headscale_subdomain");
  tankSubdomain = lib.fileContents (inputs.ctSecrets + "/tank_subdomain");
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
      server_url = "https://${headscaleSubdomain}.${domain}";

      dns = {
        magic_dns = false;
        nameservers.global = [ "1.1.1.1" "1.0.0.1" ];
      };
    };
  };

  myProfiles.gitlab = {
    enable = true;
    host = "${gitSubdomain}.${domain}";
    secretsDir = "/etc/nixos/secrets/gitlab";
  };

  services.tanka-maze = {
    enable = true;
    host = "127.0.0.1";
    port = 8000;
    trustProxy = true;
    allowedOrigins = [ "https://${tankSubdomain}.${domain}" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts."${headscaleSubdomain}.${domain}".extraConfig = ''
      reverse_proxy 127.0.0.1:7000
    '';
    virtualHosts."${gitSubdomain}.${domain}".extraConfig = ''
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    '';
    virtualHosts."${tankSubdomain}.${domain}".extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:8000 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
    '';
  };

  users.users.caddy.extraGroups = [ "gitlab" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
