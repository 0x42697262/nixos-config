{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.firmware;
in
{
  options.myProfiles.firmware = {
    enable = lib.mkEnableOption "redistributable firmware (linux-firmware, SOF, ALSA) and CPU microcode";

    cpu = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "intel"
          "amd"
        ]
      );
      default = null;
      description = "CPU vendor whose microcode updates are loaded early. null loads none.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.intel.updateMicrocode = lib.mkIf (cfg.cpu == "intel") true;
    hardware.cpu.amd.updateMicrocode = lib.mkIf (cfg.cpu == "amd") true;
  };
}
