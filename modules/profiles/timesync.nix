{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.timesync;
in
{
  options.myProfiles.timesync = {
    enable = lib.mkEnableOption "custom NTP servers for systemd-timesyncd";

    servers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "time.cloudflare.com" ];
      description = "Primary NTP servers.";
    };

    fallbackServers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "time.google.com"
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
      description = "Fallback NTP servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.timesyncd = {
      enable = true;
      servers = cfg.servers;
      fallbackServers = cfg.fallbackServers;
    };
  };
}
