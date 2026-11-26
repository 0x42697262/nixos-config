# Disk layout (same as work-ct-laptop), single 1TB NVMe:
#   p1 "ESP"       4G vfat -> /boot (unencrypted)
#   p2 "cryptroot" LUKS2 -> LVM VG "vg"
#        vg/root 356G XFS -> /  (includes the 48G /swapfile for hibernation)
#        vg/home rest XFS -> /home (Incus data lives here too)
#
# /swapfile is created with dd during the install (not fallocate, so it has
# no unwritten extents). resume_offset is its first physical block from
# `filefrag -v /swapfile` and must be updated if the file is ever recreated.
{ lib, modulesPath, ... }:
let
  xfsOptions = [
    "lazytime"
    "noatime"
    "inode64"
    "logbsize=256k"
    "noquota"
  ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.initrd.luks.devices.cryptroot = {
    device = "/dev/disk/by-partlabel/cryptroot";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/vg/root";
    fsType = "xfs";
    options = xfsOptions;
  };

  fileSystems."/home" = {
    device = "/dev/vg/home";
    fsType = "xfs";
    options = xfsOptions;
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partlabel/ESP";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      priority = 0;
    }
  ];
  boot.resumeDevice = "/dev/vg/root";
  boot.kernelParams = [ "resume_offset=24" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
