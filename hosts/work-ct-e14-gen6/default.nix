# work-ct-e14-gen6 -- Lenovo ThinkPad E14 Gen 6 (Intel, 21M7), Core Ultra
# (Meteor Lake) with the integrated Arc GPU only.
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ./hardware.nix
    ./desktop.nix
    ./apps.nix
  ];

  myProfiles.interactive.enable = true;

  myProfiles.cachyos = {
    enable = true;

    kernel.binaryCache = {
      substituters = [ "https://cache.lantian.pub/lantian" ];
      trustedPublicKeys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
    };
  };

  myProfiles.gaming.wrappers.enable = false;

  myProfiles.graphics.intel.enable = true;
  myProfiles.power.intelLpmd.enable = true;
  myProfiles.firmware.cpu = "intel";
  myProfiles.networkTuning.regulatoryDomain = "JP";

  # From nixos-hardware lenovo/thinkpad/e14 and lenovo/thinkpad.
  boot.kernelParams = [
    # Backlight via thinkpad_acpi so systemd-backlight can save/restore it.
    "acpi_backlight=native"
    # Keep crash logs out of NVRAM (efi_pstore writes oops dumps there).
    "efi_pstore.pstore_disable=1"
  ];
  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  # Enroll with `fprintd-enroll`.
  services.fprintd.enable = true;

  # Secure Boot via lanzaboote; keys live in /var/lib/sbctl and are enrolled
  # with `sbctl enroll-keys --microsoft`. No NVRAM boot entries: the signed
  # systemd-boot must also be at the fallback path \EFI\BOOT\BOOTX64.EFI,
  # which the firmware's built-in NVMe0 entry boots.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  environment.systemPackages = [ pkgs.sbctl ];

  networking.hostName = "work-ct-e14-gen6";
  networking.networkmanager.enable = true;

  users.users.chicken = {
    isNormalUser = true;
    description = "chicken";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "realtime"
    ];
  };

  system.stateVersion = "26.11";
}
