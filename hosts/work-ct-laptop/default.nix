{ pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  myProfiles.interactive.enable = true;

  myProfiles.cachyos = {
    enable = true;

    kernel.binaryCache = {
      substituters = [ "https://cache.lantian.pub/lantian" ];
      trustedPublicKeys = [ "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ=" ];
    };

    gpu.nvidia = {
      enable = true;
      patches =
        let
          base = "https://raw.githubusercontent.com/CachyOS/kernel-patches/f3770b16d069a1bce8dfa63841042137f8b43434/7.3/misc/nvidia";
        in
        [
          (pkgs.fetchurl {
            url = "${base}/0001-fix-dsc-correct-RC-parameter-tables-to-match-VESA-DS.patch";
            hash = "sha256-3LziGhagCKc3EBQiDP8RU62Yk7jQlbICQGYnXUyVO+4=";
          })
          (pkgs.fetchurl {
            url = "${base}/0002-fix-dp-add-Bigscreen-Beyond-VR-headset-to-WAR-databa.patch";
            hash = "sha256-cNwTepvW6VrkueKWrMJNPhOhOHhsb13VSdy806MwWQY=";
          })
          (pkgs.fetchurl {
            url = "${base}/0004-Open-sysfs-config-from-the-userspace-root-on-7.3.patch";
            hash = "sha256-pruuHakb6tcDDteKFh3t0tyNONSV74evJGc2Qu8dfKk=";
          })
        ];
    };
  };

  myProfiles.nvidia.prime = {
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  myProfiles.graphics.intel.enable = true;
  myProfiles.power.intelLpmd.enable = true;
  myProfiles.firmware.cpu = "intel";
  myProfiles.networkTuning.regulatoryDomain = "JP";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "work-ct-laptop";
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
