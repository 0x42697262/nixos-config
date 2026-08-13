# Site-wide public names: the apex domain and the subdomains hosts serve on.
#
# These are needed at EVALUATION time -- they build Caddy virtual host names
# and headscale's `server_url` -- which rules out sops-nix/agenix, since those
# only decrypt at activation, long after eval. It also rules out an out-of-tree
# flake input (`path:/etc/nixos/secrets`): that pins the directory's narHash in
# flake.lock, so every machine without a byte-identical copy fails to build
# with "NAR hash mismatch", and the whole tree gets copied into the
# world-readable nix store anyway.
#
# So: placeholders live here, the real names live only on the deploying host,
# in /etc/nixos/domains.nix:
#
#   # /etc/nixos/domains.nix
#   {
#     mySite.domain = "example.com";
#     mySite.subdomains = {
#       headscale = "vpn";
#       git = "git";
#       tank = "game";
#     };
#   }
#
# That file is picked up ONLY in impure eval, so deploys need --impure:
#
#   nixos-rebuild switch --flake "github:0x42697262/nixos-config#ec2-vpn" --impure
#
# Forget the flag and the build still succeeds, against the placeholders below
# -- so it warns (see `warnings`). Everywhere else (a laptop, CI, `nix flake
# check`) every host evaluates with no secrets present and nothing to unlock.
{ config, lib, ... }:
let
  cfg = config.mySite;

  placeholder = "example.invalid";

  hostOverride = /etc/nixos/domains.nix;

  # `builtins.currentSystem` does not exist in pure eval, so this is false
  # there and `&&` short-circuits before `pathExists` touches an absolute path
  # -- which pure eval forbids outright rather than reporting as missing.
  useOverride = (builtins ? currentSystem) && builtins.pathExists hostOverride;
in
{
  imports = lib.optional useOverride hostOverride;

  options.mySite = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = placeholder;
      description = ''
        Apex domain this site's services are served on. Overridden per host by
        /etc/nixos/domains.nix; see the header of this file.
      '';
      example = "example.com";
    };

    subdomains = {
      headscale = lib.mkOption {
        type = lib.types.str;
        default = "vpn";
        description = "Subdomain headscale's control server is served on.";
      };

      git = lib.mkOption {
        type = lib.types.str;
        default = "git";
        description = "Subdomain GitLab is served on.";
      };

      tank = lib.mkOption {
        type = lib.types.str;
        default = "tank";
        description = "Subdomain tanka-maze is served on.";
      };
    };
  };

  config = {
    warnings = lib.optional (cfg.domain == placeholder) ''
      mySite.domain is still the placeholder "${placeholder}". This build is
      fine to evaluate but not to deploy: ACME will fail and every URL will be
      wrong. Real deploys need /etc/nixos/domains.nix on the box and --impure
      on the nixos-rebuild command line.
    '';
  };
}
