{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking = [
    hostName = "AtomicBird";
    networkmanager.enable = true;
  ];

  time.timeZone = "Asia/Tokyo";

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelPackages = pkgs.linuxPackages_latest;
    extraModprobeConfig = "options kvm_amd nested=1";

    supportedFilesystems = [ "btrfs" ];
    tmp.useTmpfs = true;

    initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /mnt
      mount -t btrfs /dev/mapper/root /mnt
      btrfs subvolume delete /mnt/root
      btrfs subvolume snapshot /mnt/root-clean /mnt/root
    '';
  };


  hardware = {
    enableAllFirmware = true;

    bluetooth.enable = true;

    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };

    graphics = {
      enable = true;
    };

    nvidia = {
      open = false;
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.production;
      prime.amdgpuBusId = "PCI:0:6:0";
      prime.nvidiaBusId = "PCI:0:1:0";
      prime.offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
  };

  programs = {
    programs.virt-manager = {
      enable = true;
    };

    programs.fish = {
      enable = true;
      shellInit = ''
        set -g fish_greeting
      '';
      shellAbbrs = {
        Ns = "nix-shell -p --command fish";
        Nd = "nix develop";
      };
    };

    hyprland = {
      enable = true;
      # xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
    firejail = {
      enable = true;

      wrappedBinaries = {

        osu = {
          executable = "${pkgs.osu-lazer-bin}/bin/osu!";
          extraArgs = [
            "--private=~/firejail"
            "--noprofile"
          ];
        };
        steam = {
          executable = "${pkgs.steam}/bin/steam";
          extraArgs = [
            "--private=~/firejail"
            "--noprofile"
          ];
        };
        chromium = {
          executable = "${pkgs.chromium}/bin/chromium";
          extraArgs = [
            "--private=~/firejail"
            "--noprofile"
          ];
        };

        appimage-run = {
          executable = "${pkgs.appimage-run}/bin/appimage-run";
          extraArgs = [
            "--private=~/firejail"
            "--noprofile"
          ];
        };

        geekbench = {
          executable = "${pkgs.geekbench}/bin/geekbench6";
          extraArgs = [
            "--private=~/firejail"
            "--noprofile"
          ];
        };
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
  };

  fileSystems = {
    "/".options = [ "subvol=root" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    "/home".options = [ "compress=zstd:3" "relatime" "discard=async" "ssd" "space_cache=v2" ];
    "/nix". options = [ "subvol=nix" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    "/persist".options = [ "subvol=persist" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    "/birb".options = [ "compress=zstd:3" "discard=async" "relatime" "ssd" "space_cache=v2" ];
    "/var/log".options = [ "subvol=log" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    "/var/log".neededForBoot = true;
  };


  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  virtualisation.waydroid.enable = true;
  # virtualisation.vmware.host = {
  #   enable = true;
  # };
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
    allowedBridges = [
      "nm-bridge"
      "virbr0"
    ];
  };
  system.stateVersion = "24.05"; # Did you read the comment?






  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chewing
      fcitx5-mozc
    ];

  };
}
