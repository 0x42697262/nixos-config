{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.networkTuning;
in
{
  options.myProfiles.networkTuning = {
    enable = lib.mkEnableOption "network stack and resolver tuning";

    resolved = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use systemd-resolved, and make NetworkManager hand DNS to it when NetworkManager is enabled.";
    };

    defaultQdisc = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "fq_codel";
      description = "net.core.default_qdisc. null keeps the kernel's built-in default.";
    };

    netdevMaxBacklog = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 4096;
      description = "net.core.netdev_max_backlog, packets queued per CPU before the stack drops them.";
    };

    regulatoryDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "JP";
      description = "Wi-Fi regulatory domain (ISO 3166-1 alpha-2) set via cfg80211 ieee80211_regdom.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved.enable = lib.mkIf cfg.resolved true;
    networking.networkmanager.dns = lib.mkIf (
      cfg.resolved && config.networking.networkmanager.enable
    ) "systemd-resolved";

    boot.kernel.sysctl = lib.filterAttrs (_: v: v != null) {
      "net.core.default_qdisc" = cfg.defaultQdisc;
      "net.core.netdev_max_backlog" = cfg.netdevMaxBacklog;
    };

    boot.extraModprobeConfig = lib.optionalString (
      cfg.regulatoryDomain != null
    ) "options cfg80211 ieee80211_regdom=${cfg.regulatoryDomain}";
  };
}
