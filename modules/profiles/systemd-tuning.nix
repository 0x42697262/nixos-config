{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.systemdTuning;

  nullableStr = lib.types.nullOr lib.types.str;

  managerSettings =
    nofile:
    lib.filterAttrs (_: v: v != null) {
      DefaultTimeoutStartSec = cfg.timeouts.start;
      DefaultTimeoutStopSec = cfg.timeouts.stop;
      DefaultLimitNOFILE = nofile;
    };

  oomdSlice = {
    ManagedOOMSwap = "kill";
    ManagedOOMMemoryPressure = "kill";
    ManagedOOMMemoryPressureLimit = cfg.oomd.memoryPressureLimit;
  };
in
{
  options.myProfiles.systemdTuning = {
    enable = lib.mkEnableOption "systemd manager, journal and OOM tuning";

    timeouts = {
      start = lib.mkOption {
        type = nullableStr;
        default = "15s";
        description = "DefaultTimeoutStartSec for the system and user managers.";
      };

      stop = lib.mkOption {
        type = nullableStr;
        default = "10s";
        description = "DefaultTimeoutStopSec for the system and user managers.";
      };
    };

    nofile = {
      system = lib.mkOption {
        type = nullableStr;
        default = "2048:2097152";
        description = "DefaultLimitNOFILE (soft:hard) for system services.";
      };

      user = lib.mkOption {
        type = nullableStr;
        default = "1024:1048576";
        description = "DefaultLimitNOFILE (soft:hard) for user services.";
      };
    };

    journalMaxUse = lib.mkOption {
      type = nullableStr;
      default = "50M";
      description = "SystemMaxUse for the persistent journal.";
    };

    coredumpRetention = lib.mkOption {
      type = nullableStr;
      default = "3d";
      description = "Age after which stored coredumps in /var/lib/systemd/coredump are deleted.";
    };

    oomd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Let systemd-oomd kill the worst cgroup in system.slice and user
          slices on swap exhaustion or sustained memory pressure, while
          leaving session.slice alone.
        '';
      };

      memoryPressureLimit = lib.mkOption {
        type = lib.types.str;
        default = "80%";
        description = "ManagedOOMMemoryPressureLimit for the managed slices.";
      };
    };

    userDelegation = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "cpu"
        "cpuset"
        "io"
        "memory"
        "pids"
      ];
      description = "cgroup controllers delegated to user@.service. Empty leaves the systemd default.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        systemd.settings.Manager = managerSettings cfg.nofile.system;
        systemd.user.settings.Manager = managerSettings cfg.nofile.user;

        services.journald.extraConfig = lib.optionalString (
          cfg.journalMaxUse != null
        ) "SystemMaxUse=${cfg.journalMaxUse}";

        systemd.tmpfiles.rules = lib.optional (
          cfg.coredumpRetention != null
        ) "e /var/lib/systemd/coredump - - - ${cfg.coredumpRetention}";

        systemd.services."user@".serviceConfig.Delegate = lib.mkIf (cfg.userDelegation != [ ]) (
          lib.concatStringsSep " " cfg.userDelegation
        );
      }

      (lib.mkIf cfg.oomd.enable {
        systemd.oomd = {
          enable = true;
          enableSystemSlice = true;
          enableUserSlices = true;
        };
        systemd.slices."system".sliceConfig = oomdSlice;
        systemd.slices."user-".sliceConfig = oomdSlice;
        systemd.slices."session".sliceConfig.ManagedOOMPreference = "omit";
      })
    ]
  );
}
