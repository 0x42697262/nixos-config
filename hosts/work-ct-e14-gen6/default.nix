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

    kernel.enable = false;
  };

  myProfiles.gaming.wrappers.enable = false;

  myProfiles.graphics.intel.enable = true;
  myProfiles.power.intelLpmd.enable = true;
  myProfiles.firmware.cpu = "intel";
  myProfiles.networkTuning.regulatoryDomain = "JP";

  boot.kernelParams = [
    "acpi_backlight=native"
    "efi_pstore.pstore_disable=1"
  ];
  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };

  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = false;
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "net.reactivated.fprint.device.verify" && subject.isInGroup("users")) {
        return polkit.Result.YES;
      }
    });
  '';

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
