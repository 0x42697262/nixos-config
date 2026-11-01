{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.memory;

  nullableInt = lib.types.nullOr lib.types.int;
in
{
  options.myProfiles.memory = {
    enable = lib.mkEnableOption "desktop-oriented virtual memory tuning";

    vfsCachePressure = lib.mkOption {
      type = nullableInt;
      default = 50;
      description = "vm.vfs_cache_pressure. Lower keeps dentry/inode caches around longer.";
    };

    dirtyBytes = lib.mkOption {
      type = nullableInt;
      default = 268435456;
      description = "vm.dirty_bytes. Absolute cap on dirty page cache before writers block.";
    };

    dirtyBackgroundBytes = lib.mkOption {
      type = nullableInt;
      default = 67108864;
      description = "vm.dirty_background_bytes. Dirty page cache size at which background writeback starts.";
    };

    dirtyWritebackCentisecs = lib.mkOption {
      type = nullableInt;
      default = 1500;
      description = "vm.dirty_writeback_centisecs. Interval of the background writeback thread.";
    };

    compactionProactiveness = lib.mkOption {
      type = nullableInt;
      default = 0;
      description = "vm.compaction_proactiveness. 0 disables proactive compaction stalls.";
    };

    watermarkBoostFactor = lib.mkOption {
      type = nullableInt;
      default = 0;
      description = "vm.watermark_boost_factor. 0 stops reclaim bursts after fragmentation events.";
    };

    transparentHugepages = {
      enabled = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "always"
            "madvise"
            "never"
          ]
        );
        default = null;
        example = "always";
        description = "Boot-time THP mode (transparent_hugepage=). null keeps the kernel's built-in default.";
      };

      defrag = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "always"
            "defer"
            "defer+madvise"
            "madvise"
            "never"
          ]
        );
        default = "defer+madvise";
        description = "THP defrag policy written to /sys/kernel/mm/transparent_hugepage/defrag.";
      };

      maxPtesNone = lib.mkOption {
        type = nullableInt;
        default = 409;
        description = ''
          khugepaged max_ptes_none. How many empty PTEs khugepaged accepts when
          collapsing into a huge page; lower wastes less memory.
        '';
      };
    };

    mglruMinTtlMs = lib.mkOption {
      type = nullableInt;
      default = 100;
      description = ''
        /sys/kernel/mm/lru_gen/min_ttl_ms. Working set younger than this is
        protected from eviction, which avoids thrashing under memory pressure.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = lib.filterAttrs (_: v: v != null) {
      "vm.vfs_cache_pressure" = cfg.vfsCachePressure;
      "vm.dirty_bytes" = cfg.dirtyBytes;
      "vm.dirty_background_bytes" = cfg.dirtyBackgroundBytes;
      "vm.dirty_writeback_centisecs" = cfg.dirtyWritebackCentisecs;
      "vm.compaction_proactiveness" = cfg.compactionProactiveness;
      "vm.watermark_boost_factor" = cfg.watermarkBoostFactor;
    };

    boot.kernelParams = lib.optional (
      cfg.transparentHugepages.enabled != null
    ) "transparent_hugepage=${cfg.transparentHugepages.enabled}";

    systemd.tmpfiles.rules =
      lib.optional (
        cfg.transparentHugepages.defrag != null
      ) "w! /sys/kernel/mm/transparent_hugepage/defrag - - - - ${cfg.transparentHugepages.defrag}"
      ++
        lib.optional (cfg.transparentHugepages.maxPtesNone != null)
          "w! /sys/kernel/mm/transparent_hugepage/khugepaged/max_ptes_none - - - - ${toString cfg.transparentHugepages.maxPtesNone}"
      ++ lib.optional (
        cfg.mglruMinTtlMs != null
      ) "w! /sys/kernel/mm/lru_gen/min_ttl_ms - - - - ${toString cfg.mglruMinTtlMs}";
  };
}
