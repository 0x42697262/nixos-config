# Profile: nvidia
# NVIDIA GPU support, scoped to Ampere and newer -- RTX 3000 series and up.
# Nothing here is on by default.
#
# Two shapes, picked with `container.enable`:
#
#   * bare metal or VM: the whole stack, kernel module included.
#   * Incus container: userspace only. The host owns the kernel module; a
#     container has no business building or loading one, and the driver's
#     userspace half is what its GPU clients actually link against.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.nvidia;

  # Same expression hardware.nvidia.package defaults to, so both shapes draw the
  # driver from one place.
  driver = config.boot.kernelPackages.nvidiaPackages.${cfg.branch};
in
{
  options.myProfiles.nvidia = {
    enable = lib.mkEnableOption
      "NVIDIA GPU support for Ampere and newer (RTX 3000 series and up)";

    container.enable = lib.mkEnableOption ''
      userspace-only NVIDIA support for an Incus container, whose host supplies
      the kernel module. Implies {option}`myProfiles.nvidia.enable`
    '';

    branch = lib.mkOption {
      type = lib.types.str;
      default = "stable";
      example = "production";
      description = ''
        Driver branch, passed through to {option}`hardware.nvidia.branch`.

        In container mode this has to match the version the host has loaded:
        userspace and kernel module ship as one version and refuse to talk to a
        mismatched counterpart. `legacy_*` branches are rejected, since they
        exist for cards older than this profile supports.
      '';
    };
  };

  config = lib.mkMerge [
    # Naming the container shape is enough; no need to also set `enable`.
    (lib.mkIf cfg.container.enable { myProfiles.nvidia.enable = true; })

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !lib.hasPrefix "legacy_" cfg.branch;
          message = ''
            myProfiles.nvidia.branch = "${cfg.branch}" is a legacy branch, kept
            for cards older than the RTX 3000 series this profile targets. Those
            cards also cannot use the open kernel module this profile enables.
          '';
        }
        {
          assertion = !(config.boot.isContainer && !cfg.container.enable);
          message = ''
            myProfiles.nvidia.enable is set on a container, which cannot load a
            kernel module. Set myProfiles.nvidia.container.enable instead to get
            the userspace half only.
          '';
        }
      ];

      warnings = lib.optional (cfg.container.enable && !config.boot.isContainer) ''
        myProfiles.nvidia.container.enable is set on a host that is not a
        container, so nothing will provide the kernel module.
      '';
    })

    (lib.mkIf (cfg.enable && !cfg.container.enable) {
      hardware.nvidia = {
        inherit (cfg) branch;
        # Ampere and newer: the open kernel module is the supported path, and
        # from the 560 series on it is what NVIDIA develops against.
        open = true;
        modesetting.enable = true;
      };

      hardware.graphics.enable = true;

      # Only consulted when X or a display manager is running; harmless on a
      # headless compute box.
      services.xserver.videoDrivers = [ "nvidia" ];
    })

    (lib.mkIf cfg.container.enable {
      # Deliberately no hardware.nvidia: it builds a kernel module, adds it to
      # boot.extraModulePackages, and installs udev rules for devices the
      # container receives ready-made from the host.
      hardware.graphics = {
        enable = true;
        extraPackages = [ driver.out ];
      };

      # nvidia-smi, for checking that the passed-in GPU is visible at all.
      environment.systemPackages = [ driver.bin ];
    })
  ];
}
