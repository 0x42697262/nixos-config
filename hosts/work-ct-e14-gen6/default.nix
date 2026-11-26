# work-ct-e14-gen6 -- Lenovo ThinkPad E14 Gen 6 (Intel, 21M7), Core Ultra
# (Meteor Lake) with the integrated Arc GPU only.
{ ... }:
{
  imports = [
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

  # The launch wrappers only matter for games; this laptop has no dGPU.
  myProfiles.gaming.wrappers.enable = false;

  myProfiles.graphics.intel.enable = true;
  myProfiles.power.intelLpmd.enable = true;
  myProfiles.firmware.cpu = "intel";
  myProfiles.networkTuning.regulatoryDomain = "JP";

  # From nixos-hardware lenovo/thinkpad/e14 and lenovo/thinkpad. The rest of
  # those modules (microcode, iGPU/VA-API, fstrim, TLP vs PPD) is already
  # covered by the profiles above.
  boot.kernelParams = [
    # Backlight via thinkpad_acpi so systemd-backlight can save/restore it.
    "acpi_backlight=native"
  ];
  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  # Power-button fingerprint reader. Enroll with `fprintd-enroll`.
  services.fprintd.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
