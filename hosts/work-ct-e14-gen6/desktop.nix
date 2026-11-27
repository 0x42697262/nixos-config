{ pkgs, ... }:
let
  kdeWin11 = pkgs.callPackage ../../pkgs/kde-win11.nix { };
in
{
  myProfiles.desktop = {
    enable = true;
    displayManager = "sddm";

    gtk.settings = {
      gtk-application-prefer-dark-theme = false;
      gtk-icon-theme-name = "kde-win11";
      gtk-cursor-theme-name = "kde-win11-cursors";
    };

    plasma = {
      enable = true;

      extraPackages = [
        pkgs.kdePackages.plasma-thunderbolt
        pkgs.kdePackages.qtstyleplugin-kvantum
        kdeWin11
      ];

      colorScheme = {
        name = "KdeWin11Light";
        package = kdeWin11;
      };

      config = {
        kdeglobals = {
          Icons.Theme = "kde-win11";
          KDE = {
            LookAndFeelPackage = "com.github.0x42697262.kdewin11.light";
            widgetStyle = "kvantum";
          };
        };
        plasmarc.Theme.name = "kde-win11-light";
        ksplashrc.KSplash = {
          Engine = "KSplashQML";
          Theme = "com.github.0x42697262.kdewin11.light";
        };
        kcminputrc.Mouse = {
          cursorTheme = "kde-win11-cursors";
          cursorSize = 24;
        };
        kwinrc = {
          "org.kde.kdecoration2" = {
            library = "org.kde.kwin.aurorae";
            theme = "__aurorae__svg__kde-win11-light";
            ButtonsOnLeft = "M";
            ButtonsOnRight = "IAX";
          };
          WindowSwitcher.LayoutName = "thumbnail_grid";
          DesktopSwitcher.LayoutName = "org.kde.breeze.desktop";
        };
        "Kvantum/kvantum.kvconfig".General.theme = "KdeWin11Light";
      };
    };
  };

  fonts.packages = [ pkgs.inter ];

  services.displayManager.sddm = {
    theme = "kde-win11";
    settings.Theme = {
      CursorTheme = "kde-win11-cursors";
      CursorSize = 24;
    };
  };

  services.hardware.bolt.enable = true;
}
