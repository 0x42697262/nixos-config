{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.kernelTuning;
in
{
  options.myProfiles.kernelTuning = {
    enable = lib.mkEnableOption "kernel selection and general kernel tuning";

    package = lib.mkOption {
      type = lib.types.enum [
        "default"
        "latest"
        "zen"
      ];
      default = "default";
      description = ''
        Kernel to boot. default leaves boot.kernelPackages alone, latest is
        linuxPackages_latest, zen is linuxPackages_zen.
      '';
    };

    preempt = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "none"
          "voluntary"
          "full"
          "lazy"
        ]
      );
      default = null;
      example = "full";
      description = "Preemption model passed as preempt= (PREEMPT_DYNAMIC kernels). null keeps the kernel default.";
    };

    disableWatchdog = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Turn off the soft/NMI lockup watchdogs (nowatchdog,
        kernel.nmi_watchdog = 0) and blacklist the hardware watchdog timer
        drivers iTCO_wdt, sp5100_tco and wdat_wdt.
      '';
    };

    sysrq = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 1;
      description = "kernel.sysrq bitmask. 1 enables every SysRq function (REISUB on a hung system).";
    };

    printk = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "3 3 3 3";
      description = "kernel.printk. \"3 3 3 3\" keeps anything below errors off the console.";
    };

    kptrRestrict = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 0 2);
      default = 2;
      description = "kernel.kptr_restrict. 2 hides kernel pointers from everyone.";
    };

    fileMax = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = 2097152;
      description = "fs.file-max, the system-wide open file limit.";
    };

    splitLockMitigate = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = false;
      description = ''
        kernel.split_lock_mitigate. false stops the kernel from slowing down
        tasks that trigger split locks, which some games and Windows
        binaries do constantly. null keeps the kernel default.
      '';
    };

    ntsync = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Load the ntsync module (NT synchronization primitives for Wine/Proton).";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkIf (cfg.package != "default") (
      {
        latest = pkgs.linuxPackages_latest;
        zen = pkgs.linuxPackages_zen;
      }
      .${cfg.package}
    );

    boot.kernelParams =
      lib.optional (cfg.preempt != null) "preempt=${cfg.preempt}"
      ++ lib.optional cfg.disableWatchdog "nowatchdog";

    boot.blacklistedKernelModules = lib.mkIf cfg.disableWatchdog [
      "iTCO_wdt"
      "sp5100_tco"
      "wdat_wdt"
    ];

    boot.kernelModules = lib.mkIf cfg.ntsync [ "ntsync" ];

    boot.kernel.sysctl = lib.filterAttrs (_: v: v != null) {
      "kernel.nmi_watchdog" = if cfg.disableWatchdog then 0 else null;
      "kernel.sysrq" = cfg.sysrq;
      "kernel.printk" = cfg.printk;
      "kernel.kptr_restrict" = cfg.kptrRestrict;
      "fs.file-max" = cfg.fileMax;
      "kernel.split_lock_mitigate" =
        if cfg.splitLockMitigate == null then
          null
        else if cfg.splitLockMitigate then
          1
        else
          0;
    };
  };
}
