{ pkgs, ... }:
let
  emerald = pkgs.callPackage ../../pkgs/cachyos-emerald-kde.nix { };
in
{
  myProfiles.desktop = {
    enable = true;

    gtk.settings.gtk-icon-theme-name = "Qogir-Dark";

    plasma = {
      enable = true;

      extraPackages = [
        pkgs.kdePackages.plasma-thunderbolt
        emerald
        pkgs.qogir-icon-theme
      ];

      colorScheme = {
        name = "EmeraldDark";
        package = emerald;
      };

      config = {
        kdeglobals = {
          Icons.Theme = "Qogir-Dark";
          KDE.LookAndFeelPackage = "com.github.rkstrdee.emerald";
        };
        plasmarc.Theme.name = "cachyos-emerald-color";
        ksplashrc.KSplash.Theme = "com.github.rkstrdee.emerald";
        kwinrc.WindowSwitcher.LayoutName = "big_icons";
      };
    };
  };

  services.hardware.bolt.enable = true;
}
