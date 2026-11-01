{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.storage;

  scheduler =
    default:
    lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      inherit default;
      description = "I/O scheduler for this device class. null leaves the kernel's choice.";
    };
in
{
  options.myProfiles.storage = {
    enable = lib.mkEnableOption "block device tuning (I/O schedulers, disk power management)";

    schedulers = {
      nvme = scheduler "kyber";
      ssd = scheduler "mq-deadline";
      hdd = scheduler "bfq";
    };

    hddNoSpindown = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set APM 254 and disable the standby timer on internal rotating SATA disks.";
    };

    sataMaxPerformance = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set SATA link power management to max_performance.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.udev.extraRules = lib.concatStringsSep "\n" (
      lib.optional (cfg.schedulers.hdd != null)
        ''ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="${cfg.schedulers.hdd}"''
      ++
        lib.optional (cfg.schedulers.ssd != null)
          ''ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="${cfg.schedulers.ssd}"''
      ++
        lib.optional (cfg.schedulers.nvme != null)
          ''ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="${cfg.schedulers.nvme}"''
      ++ lib.optional cfg.hddNoSpindown ''ACTION=="add|change", KERNEL=="sd[a-z]", ENV{ID_USB_DRIVER}=="", ATTR{queue/rotational}=="1", ENV{ID_BUS}=="ata", RUN+="${pkgs.hdparm}/bin/hdparm -B 254 -S 0 /dev/%k"''
      ++ lib.optional cfg.sataMaxPerformance ''ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_supported}=="1", ATTR{link_power_management_policy}=="*", ATTR{link_power_management_policy}="max_performance"''
      ++ [ "" ]
    );
  };
}
