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
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      memoryPercent = cfg.memoryPercent;
    };
  };
}
