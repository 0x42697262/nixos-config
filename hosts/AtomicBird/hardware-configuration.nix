{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/3477c59c-3fa2-4534-84e5-13613ecb1e11";
      fsType = "btrfs";
    };

  boot.initrd.luks.devices."root".device = "/dev/disk/by-uuid/013f6fb8-7aaf-4026-a7c4-de53d1188a78";

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/3477c59c-3fa2-4534-84e5-13613ecb1e11";
      fsType = "btrfs";
    };

  fileSystems."/var/log" =
    {
      device = "/dev/disk/by-uuid/3477c59c-3fa2-4534-84e5-13613ecb1e11";
      fsType = "btrfs";
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/bebc7a97-e094-4c29-a668-4af831792407";
      fsType = "btrfs";
    };

  boot.initrd.luks.devices."home".device = "/dev/disk/by-uuid/ab14c3ce-d603-49ad-8489-c460324c6042";

  fileSystems."/persist" =
    {
      device = "/dev/disk/by-uuid/3477c59c-3fa2-4534-84e5-13613ecb1e11";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/0F5E-0A77";
      fsType = "vfat";
    };

  fileSystems."/birb" =
    {
      device = "/dev/disk/by-uuid/43cb3165-ca1b-4a5f-9d31-9d48f4a45757";
      fsType = "btrfs";
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlo1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}