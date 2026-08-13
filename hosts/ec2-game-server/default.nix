# AMI ID:   ami-08dea6dfd1b09cc4a
# AMI name: nixos/26.05.590.ec942ba042da-aarch64-linux  (aarch64 / Graviton)
{ config, inputs, ... }:
let
  # Placeholders unless /etc/nixos/domains.nix is present and the rebuild ran
  # with --impure. See modules/common/site.nix.
  tankHost = "${config.mySite.subdomains.tank}.${config.mySite.domain}";
in
{
  imports = [
    ../../modules/roles/ec2.nix
    inputs.tanka-maze.nixosModules.default
  ];

  services.tanka-maze = {
    enable = true;
    host = "127.0.0.1";
    port = 8000;
    trustProxy = true;
    allowedOrigins = [ "https://${tankHost}" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts."${tankHost}".extraConfig = ''
      encode zstd gzip
      reverse_proxy 127.0.0.1:8000 {
        header_up X-Forwarded-For {remote_host}
        header_up X-Forwarded-Proto {scheme}
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
