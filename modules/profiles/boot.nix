{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.boot;
in
{
  options.myProfiles.boot = {
    enable = lib.mkEnableOption "desktop boot defaults";

    tmpOnTmpfs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Mount /tmp as tmpfs.";
    };

    quiet = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Quiet kernel and initrd output (quiet, low console loglevel, no udev chatter).";
    };

    plymouth.enable = lib.mkEnableOption "the Plymouth boot splash";
  };

  config = lib.mkIf cfg.enable {
    boot.tmp.useTmpfs = cfg.tmpOnTmpfs;

    boot.plymouth.enable = cfg.plymouth.enable;

    boot.consoleLogLevel = lib.mkIf cfg.quiet 3;
    boot.kernelParams = lib.mkIf cfg.quiet [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };
}
