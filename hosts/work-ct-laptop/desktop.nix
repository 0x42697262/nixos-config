{ pkgs, ... }:
{
  myProfiles.desktop = {
    enable = true;
    plasma = {
      enable = true;
      extraPackages = [ pkgs.kdePackages.plasma-thunderbolt ];
    };
  };

  services.hardware.bolt.enable = true;
}
