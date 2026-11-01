{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.graphics;
in
{
  options.myProfiles.graphics = {
    enable = lib.mkEnableOption "hardware graphics acceleration (Mesa, Vulkan, VA-API)";

    enable32Bit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "32-bit graphics drivers, needed by Wine and Steam.";
    };

    intel.enable = lib.mkEnableOption "Intel media acceleration (iHD VA-API driver and oneVPL runtime)";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = cfg.enable32Bit;
        };
      }

      (lib.mkIf cfg.intel.enable {
        hardware.graphics.extraPackages = with pkgs; [
          intel-media-driver
          vpl-gpu-rt
        ];
        hardware.graphics.extraPackages32 = lib.mkIf cfg.enable32Bit [
          pkgs.pkgsi686Linux.intel-media-driver
        ];
      })
    ]
  );
}
