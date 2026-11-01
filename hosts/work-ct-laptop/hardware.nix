{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "vmd"
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "usbhid"
    "sr_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.initrd.luks.devices.cryptroot.device = "/dev/disk/by-partlabel/cryptroot";

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "xfs";
    options = [
      "lazytime"
      "noatime"
      "inode64"
      "logbsize=256k"
      "noquota"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/mnt/new" = {
    device = "/dev/disk/by-uuid/ff174c2d-e637-4bb8-b71c-868b41f212ca";
    fsType = "xfs";
    options = [
      "noatime"
      "lazytime"
      "nofail"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
