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

  primeOffload =
    cfg.prime.nvidiaBusId != null && (cfg.prime.intelBusId != null || cfg.prime.amdgpuBusId != null);

  prime-run = pkgs.writeShellScriptBin "prime-run" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';
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

    prime = {
      intelBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:0:2:0";
        description = "Bus ID of the Intel iGPU. Set together with nvidiaBusId for PRIME render offload.";
      };

      amdgpuBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:6:0:0";
        description = "Bus ID of the AMD iGPU. Set together with nvidiaBusId for PRIME render offload.";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:1:0:0";
        description = "Bus ID of the NVIDIA dGPU.";
      };
    };

    dynamicBoost.enable = lib.mkEnableOption "nvidia-powerd (Dynamic Boost, laptops with Ampere or newer)";

    earlyKms = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Load nvidia, nvidia_modeset, nvidia_uvm and nvidia_drm from the initrd.";
    };

    moduleParams = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.int lib.types.str);
      default = { };
      example = {
        NVreg_InitializeSystemMemoryAllocations = 0;
      };
      description = "Extra parameters for the nvidia kernel module.";
    };

    cudaPerfBoost = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Let CUDA contexts (NVENC/NVDEC included) push the GPU into its boost
        clocks. false sets CUDA_DISABLE_PERF_BOOST=1, which lowers idle power
        while video is decoded or encoded on the GPU.
      '';
    };

    patches = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.path lib.types.package);
      default = [ ];
      description = "Patches applied to the open kernel module source.";
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

      hardware.nvidia.package = lib.mkIf (cfg.patches != [ ]) (
        driver
        // {
          open = driver.open.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ cfg.patches;
          });
        }
      );

      hardware.nvidia.dynamicBoost.enable = cfg.dynamicBoost.enable;

      boot.initrd.kernelModules = lib.mkIf cfg.earlyKms [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];

      boot.extraModprobeConfig = lib.mkIf (cfg.moduleParams != { }) (
        "options nvidia "
        + lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${toString v}") cfg.moduleParams)
      );

      environment.sessionVariables.CUDA_DISABLE_PERF_BOOST = lib.mkIf (!cfg.cudaPerfBoost) "1";
    })

    (lib.mkIf (cfg.enable && !cfg.container.enable && primeOffload) {
      hardware.nvidia = {
        prime = {
          offload.enable = true;
          offload.enableOffloadCmd = true;
          nvidiaBusId = cfg.prime.nvidiaBusId;
          intelBusId = lib.mkIf (cfg.prime.intelBusId != null) cfg.prime.intelBusId;
          amdgpuBusId = lib.mkIf (cfg.prime.amdgpuBusId != null) cfg.prime.amdgpuBusId;
        };
        powerManagement.enable = true;
        powerManagement.finegrained = true;
      };

      services.switcherooControl.enable = true;

      environment.systemPackages = [ prime-run ];
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
