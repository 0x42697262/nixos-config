# Compressed RAM swap (zram). On by default; tunable / disable-able per host via
# myProfiles.zram.*. Note: pointless on WSL (the Windows host manages memory),
# so the WSL hosts set myProfiles.zram.enable = false.
{ config, lib, ... }:
let
  cfg = config.myProfiles.zram;
in
{
  options.myProfiles.zram = {
    enable = lib.mkEnableOption "compressed RAM swap (zram)" // {
      default = true;
    };

    memoryPercent = lib.mkOption {
      type = lib.types.ints.positive;
      default = 100;
      description = ''
        Maximum amount of RAM, as a percentage, the zram device may hold
        (uncompressed). 100 sizes the swap device to all of RAM. Values above
        100 are valid -- zram compresses, so the device can be oversubscribed.
      '';
    };

    algorithm = lib.mkOption {
      type = lib.types.str;
      default = "zstd";
      example = "lz4";
      description = "Compression algorithm used by the zram device.";
    };

    priority = lib.mkOption {
      type = lib.types.int;
      default = 5;
      example = 100;
      description = "Swap priority of the zram device. Higher wins over disk swap.";
    };

    swappiness = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 0 200);
      default = null;
      example = 150;
      description = ''
        vm.swappiness while zram is the swap device. Values above 100 make the
        kernel prefer swapping anonymous pages to zram over dropping file
        cache. null keeps the kernel default.
      '';
    };

    pageCluster = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 0 10);
      default = null;
      example = 0;
      description = ''
        vm.page-cluster (log2 of pages read ahead per swap-in). 0 disables
        swap readahead, which only helps rotating disks. null keeps the kernel
        default.
      '';
    };

    disableZswap = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Turn zswap off on the kernel command line, so pages are not
        compressed twice on their way into zram.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      memoryPercent = cfg.memoryPercent;
      algorithm = cfg.algorithm;
      priority = cfg.priority;
    };

    boot.kernel.sysctl = lib.mkMerge [
      (lib.mkIf (cfg.swappiness != null) { "vm.swappiness" = cfg.swappiness; })
      (lib.mkIf (cfg.pageCluster != null) { "vm.page-cluster" = cfg.pageCluster; })
    ];

    boot.kernelParams = lib.mkIf cfg.disableZswap [ "zswap.enabled=0" ];
  };
}
