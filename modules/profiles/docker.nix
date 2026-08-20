{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.docker;
in
{
  options.myProfiles.docker = {
    enable = lib.mkEnableOption "the Docker daemon and CLI";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "chicken" ];
      description = ''
        Accounts added to the `docker` group, which is root-equivalent on this
        host -- anyone in it can bind-mount / into a container. Leave empty and
        `docker` has to be run through sudo.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;

      enableOnBoot = false;

      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };

    users.groups.docker.members = cfg.users;

    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
