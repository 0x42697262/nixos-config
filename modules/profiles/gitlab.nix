# Profile: gitlab
# A self-hosted GitLab server. Hosts that explicitly flip
# `myProfiles.gitlab.enable = true` get GitLab.
#
# GitLab needs a handful of secrets that must live outside git. Point
# `myProfiles.gitlab.secretsDir` at a directory on the box (e.g. under
# /etc/nixos/secrets) containing:
#   root_password  db_password  secret  otp  db  jws
#   active_record_primary_key  active_record_deterministic_key  active_record_salt
# Generate the random ones with e.g. `openssl rand -hex 32`.
{ config, lib, ... }:
let
  cfg = config.myProfiles.gitlab;
in
{
  options.myProfiles.gitlab = {
    enable = lib.mkEnableOption "self-hosted GitLab server";

    host = lib.mkOption {
      type = lib.types.str;
      description = "Public FQDN GitLab is served on.";
      example = "gitlab.example.com";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 443;
      description = ''
        External port GitLab is reached on. Used to build repo/clone URLs and
        emails, so it must match the port your reverse proxy serves on. Set to
        something other than 443 when 443 is already taken on the host.
      '';
    };

    secretsDir = lib.mkOption {
      type = lib.types.str;
      description = "Directory holding GitLab's secret files (kept out of git).";
      example = "/etc/nixos/secrets/gitlab";
    };
  };

  config = lib.mkIf cfg.enable {
    myProfiles.server.enable = true;

    services.gitlab = {
      enable = true;
      host = cfg.host;
      https = true;
      port = cfg.port;

      databasePasswordFile = "${cfg.secretsDir}/db_password";
      initialRootPasswordFile = "${cfg.secretsDir}/root_password";
      secrets = {
        secretFile = "${cfg.secretsDir}/secret";
        otpFile = "${cfg.secretsDir}/otp";
        dbFile = "${cfg.secretsDir}/db";
        jwsFile = "${cfg.secretsDir}/jws";
        activeRecordPrimaryKeyFile = "${cfg.secretsDir}/active_record_primary_key";
        activeRecordDeterministicKeyFile = "${cfg.secretsDir}/active_record_deterministic_key";
        activeRecordSaltFile = "${cfg.secretsDir}/active_record_salt";
      };
    };

  };
}
