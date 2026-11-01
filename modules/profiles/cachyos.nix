{
  config,
  lib,
  pkgs,
  inputs ? { },
  ...
}:
let
  cfg = config.myProfiles.cachyos;

  kernelPatches = "https://raw.githubusercontent.com/CachyOS/kernel-patches/f3770b16d069a1bce8dfa63841042137f8b43434";

  nvidiaPatches = [
    (pkgs.fetchurl {
      url = "${kernelPatches}/7.3/misc/nvidia/0001-fix-dsc-correct-RC-parameter-tables-to-match-VESA-DS.patch";
      hash = "sha256-3LziGhagCKc3EBQiDP8RU62Yk7jQlbICQGYnXUyVO+4=";
    })
    (pkgs.fetchurl {
      url = "${kernelPatches}/7.3/misc/nvidia/0002-fix-dp-add-Bigscreen-Beyond-VR-headset-to-WAR-databa.patch";
      hash = "sha256-cNwTepvW6VrkueKWrMJNPhOhOHhsb13VSdy806MwWQY=";
    })
    (pkgs.fetchurl {
      url = "${kernelPatches}/7.3/misc/nvidia/0004-Open-sysfs-config-from-the-userspace-root-on-7.3.patch";
      hash = "sha256-pruuHakb6tcDDteKFh3t0tyNONSV74evJGc2Qu8dfKk=";
    })
  ];

  nvidiaPrime =
    config.myProfiles.nvidia.prime.nvidiaBusId != null
    && (
      config.myProfiles.nvidia.prime.intelBusId != null
      || config.myProfiles.nvidia.prime.amdgpuBusId != null
    );
in
{
  options.myProfiles.cachyos = {
    enable = lib.mkEnableOption "the CachyOS system defaults, kernel and NVIDIA setup";

    kernel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Boot a CachyOS kernel from the nix-cachyos-kernel flake input.";
      };

      variant = lib.mkOption {
        type = lib.types.str;
        default = "linuxPackages-cachyos-latest-lto-x86_64-v3";
        example = "linuxPackages-cachyos-bore-lto-x86_64-v3";
        description = ''
          Attribute under nix-cachyos-kernel's legacyPackages.<system>. The
          default matches linux-cachyos from the cachyos-v3 repository.
        '';
      };

      binaryCache = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use the nix-cachyos-kernel binary cache (cache.lantian.pub).";
      };
    };

    nvidiaPatches = lib.mkOption {
      type = lib.types.bool;
      default = cfg.kernel.enable;
      defaultText = lib.literalExpression "config.myProfiles.cachyos.kernel.enable";
      description = ''
        Apply the NVIDIA open module patches linux-cachyos ships with its
        prebuilt nvidia-open (CachyOS/kernel-patches 7.3/misc/nvidia).
        They target the 615 driver on 7.3 kernels.
      '';
    };

    ananicyRules = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use the CachyOS ananicy-cpp rule set (pkgs.ananicy-rules-cachyos).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        myProfiles.zram = {
          enable = lib.mkDefault true;
          memoryPercent = lib.mkDefault 100;
          algorithm = lib.mkDefault "zstd";
          priority = lib.mkDefault 100;
          swappiness = lib.mkDefault 150;
          pageCluster = lib.mkDefault 0;
          disableZswap = lib.mkDefault true;
        };

        myProfiles.memory = {
          enable = lib.mkDefault true;
          transparentHugepages.enabled = lib.mkDefault "always";
        };

        myProfiles.kernelTuning = {
          enable = lib.mkDefault true;
          preempt = lib.mkDefault (if cfg.kernel.enable then null else "full");
        };

        myProfiles.storage.enable = lib.mkDefault true;
        myProfiles.systemdTuning.enable = lib.mkDefault true;

        myProfiles.audio = {
          enable = lib.mkDefault true;
          hdaPowerSaveOnBatteryOnly = lib.mkDefault true;
        };

        myProfiles.ananicy = {
          enable = lib.mkDefault true;
          rulesProvider = lib.mkIf cfg.ananicyRules (lib.mkDefault pkgs.ananicy-rules-cachyos);
        };

        myProfiles.networkTuning.enable = lib.mkDefault true;
        myProfiles.timesync.enable = lib.mkDefault true;
        myProfiles.power.enable = lib.mkDefault true;
        myProfiles.gaming.wrappers.enable = lib.mkDefault true;
        myProfiles.graphics.enable = lib.mkDefault true;
        myProfiles.firmware.enable = lib.mkDefault true;

        myProfiles.boot = {
          enable = lib.mkDefault true;
          quiet = lib.mkDefault true;
          plymouth.enable = lib.mkDefault true;
        };

        myProfiles.shell.extras.enable = lib.mkDefault config.myProfiles.shell.enable;

        myProfiles.nvidia = {
          branch = lib.mkDefault "latest";
          earlyKms = lib.mkDefault true;
          moduleParams.NVreg_InitializeSystemMemoryAllocations = lib.mkDefault 0;
          cudaPerfBoost = lib.mkDefault false;
          dynamicBoost.enable = lib.mkDefault nvidiaPrime;
          patches = lib.mkIf cfg.nvidiaPatches nvidiaPatches;
        };
      }

      (lib.mkIf cfg.kernel.enable {
        assertions = [
          {
            assertion = inputs ? nix-cachyos-kernel;
            message = "myProfiles.cachyos.kernel needs the nix-cachyos-kernel flake input.";
          }
          {
            assertion = config.myProfiles.kernelTuning.package == "default";
            message = ''
              myProfiles.cachyos.kernel and myProfiles.kernelTuning.package =
              "${config.myProfiles.kernelTuning.package}" both pick a kernel. Disable one.
            '';
          }
        ];

        boot.kernelPackages = lib.mkIf (
          config.myProfiles.kernelTuning.package == "default"
        ) inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.${cfg.kernel.variant};

        nix.settings = lib.mkIf cfg.kernel.binaryCache {
          substituters = [ "https://cache.lantian.pub/lantian" ];
          trusted-public-keys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
        };
      })
    ]
  );
}
