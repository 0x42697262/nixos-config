{
  config,
  options,
  lib,
  pkgs,
  inputs ? { },
  ...
}:
let
  cfg = config.myProfiles.cachyos;
  opt = options.myProfiles.cachyos;
  desktop = config.myProfiles.desktop;

  noctalia = pkgs.callPackage ../../pkgs/noctalia.nix { };
  swash = pkgs.callPackage ../../pkgs/swash.nix { };
  hyprDotfiles = pkgs.callPackage ../../pkgs/cachyos-hypr-noctalia.nix { };

  patchesExample = ''
    myProfiles.cachyos.gpu.nvidia.patches =
      let
        base = "https://raw.githubusercontent.com/CachyOS/kernel-patches/f3770b16d069a1bce8dfa63841042137f8b43434/7.3/misc/nvidia";
      in
      [
        (pkgs.fetchurl {
          url = "''${base}/0001-fix-dsc-correct-RC-parameter-tables-to-match-VESA-DS.patch";
          hash = "sha256-3LziGhagCKc3EBQiDP8RU62Yk7jQlbICQGYnXUyVO+4=";
        })
        (pkgs.fetchurl {
          url = "''${base}/0002-fix-dp-add-Bigscreen-Beyond-VR-headset-to-WAR-databa.patch";
          hash = "sha256-cNwTepvW6VrkueKWrMJNPhOhOHhsb13VSdy806MwWQY=";
        })
        (pkgs.fetchurl {
          url = "''${base}/0004-Open-sysfs-config-from-the-userspace-root-on-7.3.patch";
          hash = "sha256-pruuHakb6tcDDteKFh3t0tyNONSV74evJGc2Qu8dfKk=";
        })
      ];
  '';

  binaryCacheExample = ''
    myProfiles.cachyos.kernel.binaryCache = {
      substituters = [ "https://cache.lantian.pub/lantian" ];
      trustedPublicKeys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
    };
  '';

  patchesSet = opt.gpu.nvidia.patches.isDefined;

  gpuVendors = lib.attrNames (lib.filterAttrs (_: v: v.enable) cfg.gpu);
  binaryCacheSet =
    opt.kernel.binaryCache.substituters.isDefined && opt.kernel.binaryCache.trustedPublicKeys.isDefined;

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

      binaryCache = {
        substituters = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          example = [ "https://cache.lantian.pub/lantian" ];
          description = ''
            Binary caches serving the CachyOS kernel builds. Required when
            kernel.enable is true; set [ ] to build kernels locally.
          '';
        };

        trustedPublicKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          example = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
          description = "Signing keys of those caches. Required when kernel.enable is true.";
        };
      };
    };

    gpu = {
      nvidia = {
        enable = lib.mkEnableOption ''
          the NVIDIA setup chwd applies for nvidia-open: myProfiles.nvidia
          with the latest branch, early KMS, CachyOS module and CUDA
          settings, Dynamic Boost on PRIME laptops, and the patches below
        '';

        patches = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.path lib.types.package);
          example = lib.literalExpression patchesExample;
          description = ''
            Patches for the NVIDIA open kernel module, as linux-cachyos
            applies to its prebuilt nvidia-open (CachyOS/kernel-patches
            <kernel>/misc/nvidia). Pin them to the kernel and driver the
            host boots. Required when gpu.nvidia.enable is true; set [ ] to
            apply none.
          '';
        };
      };
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
        assertions = [
          {
            assertion = gpuVendors != [ ];
            message = ''
              myProfiles.cachyos needs at least one GPU vendor enabled under
              myProfiles.cachyos.gpu (available: ${lib.concatStringsSep ", " (lib.attrNames cfg.gpu)}).
            '';
          }
        ];

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

      }

      (lib.mkIf desktop.enable {
        myProfiles.desktop.fonts = lib.mkDefault (
          with pkgs;
          [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            noto-fonts-color-emoji
            cantarell-fonts
            dejavu_fonts
            liberation_ttf
            open-sans
            ttf-bitstream-vera
            fira-sans
            nerd-fonts.meslo-lg
            nerd-fonts.fantasque-sans-mono
          ]
        );
      })

      (lib.mkIf (desktop.enable && desktop.plasma.enable) {
        myProfiles.desktop = {
          displayManager = lib.mkDefault "plasma-login-manager";
          defaultSession = lib.mkDefault "plasma";

          gtk.settings = lib.mapAttrs (_: lib.mkDefault) {
            gtk-application-prefer-dark-theme = true;
            gtk-cursor-theme-name = "capitaine-cursors";
            gtk-cursor-theme-size = 24;
            gtk-decoration-layout = "icon:minimize,maximize,close";
            gtk-enable-animations = true;
            gtk-font-name = "Noto Sans,  10";
            gtk-icon-theme-name = "breeze-dark";
            gtk-primary-button-warps-slider = true;
            gtk-sound-theme-name = "ocean";
            gtk-xft-dpi = 98304;
          };

          gtk.gtk3Settings = lib.mapAttrs (_: lib.mkDefault) {
            gtk-button-images = true;
            gtk-menu-images = true;
            gtk-theme-name = "Breeze";
            gtk-toolbar-style = 3;
          };

          plasma = {
            partitionManager.enable = lib.mkDefault true;

            excludePackages = with pkgs.kdePackages; [
              okular
              elisa
              khelpcenter
              krdp
              discover
            ];

            extraPackages = with pkgs; [
              kdePackages.filelight
              kdePackages.kcalc
              kdePackages.kdialog
              kdePackages.plymouth-kcm
              haruna
              xsettingsd
              capitaine-cursors
            ];

            config = lib.mapAttrsRecursive (_: lib.mkDefault) {
              kdeglobals = {
                General.ColorScheme = "BreezeDark";
                Icons.Theme = "breeze-dark";
                KDE = {
                  AnimationDurationFactor = "0.25";
                  LookAndFeelPackage = "org.kde.breezedark.desktop";
                  widgetStyle = "Breeze";
                };
              };
              kcminputrc.Mouse.cursorTheme = "capitaine-cursors";
              ksmserverrc.General.loginMode = "emptySession";
              arkrc.Extraction.openDestinationFolderAfterExtraction = true;
              baloofilerc = {
                "Basic Settings".Indexing-Enabled = false;
                General = {
                  "exclude filters version" = 9;
                  "exclude filters" = lib.concatStringsSep "," [
                    "*~"
                    "*.part"
                    "*.o"
                    "*.la"
                    "*.lo"
                    "*.loT"
                    "*.moc"
                    "moc_*.cpp"
                    "qrc_*.cpp"
                    "ui_*.h"
                    "cmake_install.cmake"
                    "CMakeCache.txt"
                    "CTestTestfile.cmake"
                    "libtool"
                    "config.status"
                    "confdefs.h"
                    "autom4te"
                    "conftest"
                    "confstat"
                    "Makefile.am"
                    "*.gcode"
                    ".ninja_deps"
                    ".ninja_log"
                    "build.ninja"
                    "*.csproj"
                    "*.m4"
                    "*.rej"
                    "*.gmo"
                    "*.pc"
                    "*.omf"
                    "*.aux"
                    "*.tmp"
                    "*.po"
                    "*.vm*"
                    "*.nvram"
                    "*.rcore"
                    "*.swp"
                    "*.swap"
                    "lzo"
                    "litmain.sh"
                    "*.orig"
                    ".histfile.*"
                    ".xsession-errors*"
                    "*.map"
                    "*.so"
                    "*.a"
                    "*.db"
                    "*.qrc"
                    "*.ini"
                    "*.init"
                    "*.img"
                    "*.vdi"
                    "*.vbox*"
                    "vbox.log"
                    "*.qcow2"
                    "*.vmdk"
                    "*.vhd"
                    "*.vhdx"
                    "*.sql"
                    "*.sql.gz"
                    "*.ytdl"
                    "*.tfstate*"
                    "*.class"
                    "*.pyc"
                    "*.pyo"
                    "*.elc"
                    "*.qmlc"
                    "*.jsc"
                    "*.fastq"
                    "*.fq"
                    "*.gb"
                    "*.fasta"
                    "*.fna"
                    "*.gbff"
                    "*.faa"
                    "po"
                    "CVS"
                    ".svn"
                    ".git"
                    "_darcs"
                    ".bzr"
                    ".hg"
                    "CMakeFiles"
                    "CMakeTmp"
                    "CMakeTmpQmake"
                    ".moc"
                    ".obj"
                    ".pch"
                    ".uic"
                    ".npm"
                    ".yarn"
                    ".yarn-cache"
                    "__pycache__"
                    "node_modules"
                    "node_packages"
                    "nbproject"
                    ".terraform"
                    ".venv"
                    "venv"
                    "core-dumps"
                    "lost+found"
                  ];
                };
              };
            };
          };
        };
      })

      (lib.mkIf (desktop.enable && desktop.hyprland.enable) {
        myProfiles.desktop.hyprland = {
          shell = lib.mkDefault noctalia;
          skel = lib.mkDefault "${hyprDotfiles}/share/cachyos-hypr-noctalia/skel";
          xhostRoot = lib.mkDefault true;
          extraPackages = with pkgs; [
            swash
            adw-gtk3
            kitty
            kdePackages.dolphin
            kdePackages.kde-cli-tools
            gnome-calculator
            gnome-text-editor
            grim
            slurp
            hyprpicker
            wl-clipboard
            qt6Packages.qt6ct
            nwg-look
            qview
            brightnessctl
            ddcutil
            curl
            python3
          ];
        };
      })

      (lib.mkIf cfg.gpu.nvidia.enable {
        assertions = [
          {
            assertion = patchesSet;
            message = ''
              myProfiles.cachyos.gpu.nvidia.patches is not set. Pin the NVIDIA
              open module patches for this host's kernel and driver, or set
              it to [ ]. For linux-cachyos 7.3 with nvidia 615:

              ${patchesExample}'';
          }
        ];

        myProfiles.nvidia = {
          enable = lib.mkDefault true;
          branch = lib.mkDefault "latest";
          earlyKms = lib.mkDefault true;
          moduleParams.NVreg_InitializeSystemMemoryAllocations = lib.mkDefault 0;
          cudaPerfBoost = lib.mkDefault false;
          dynamicBoost.enable = lib.mkDefault nvidiaPrime;
          patches = lib.mkIf patchesSet cfg.gpu.nvidia.patches;
        };
      })

      (lib.mkIf cfg.kernel.enable {
        assertions = [
          {
            assertion = binaryCacheSet;
            message = ''
              myProfiles.cachyos.kernel.binaryCache is not set. Point it at
              a cache serving the nix-cachyos-kernel builds, or set both
              lists to [ ] to build kernels locally:

              ${binaryCacheExample}'';
          }
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

        nix.settings = lib.mkIf binaryCacheSet {
          substituters = cfg.kernel.binaryCache.substituters;
          trusted-public-keys = cfg.kernel.binaryCache.trustedPublicKeys;
        };
      })
    ]
  );
}
