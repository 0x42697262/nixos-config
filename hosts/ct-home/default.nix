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
  ];

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 443;
    settings = {
      server_url = "https://${domain}";

      tls_letsencrypt_hostname = domain;
      tls_letsencrypt_challenge_type = "TLS-ALPN-01";

      # MagicDNS off for now -- avoids needing a base_domain. Enable later.
      dns.magic_dns = false;
    };
  };

  # headscale runs as a non-root user but must bind privileged port 443.
  # If the journal still shows a bind error, the module is also restricting
  # CapabilityBoundingSet -- add CAP_NET_BIND_SERVICE there too (mkForce).
  systemd.services.headscale.serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];

  networking.firewall.allowedTCPPorts = [ 443 ];

  # This should match the NixOS release first installed and generally should
  # not change on upgrade.
  system.stateVersion = "26.05";
}
