# Disk layout (same as work-ct-laptop), single 1TB NVMe:
#   p1 "ESP"       4G vfat -> /boot (unencrypted)
#   p2 "cryptroot" LUKS2 -> LVM VG "vg"
#        vg/root 256G XFS -> /
#        vg/home rest XFS -> /home (Incus data lives here too)
#
# TODO: initrd modules are a best guess for this machine. Reconcile with
# `nixos-generate-config --show-hardware-config` during the install.
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
    "vmd"
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

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
