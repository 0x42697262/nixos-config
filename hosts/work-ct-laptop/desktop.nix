{ lib, pkgs, ... }:
let
  ini = lib.generators.toINI { };

  gtkSettings = {
    gtk-application-prefer-dark-theme = true;
    gtk-cursor-theme-name = "capitaine-cursors";
    gtk-cursor-theme-size = 24;
    gtk-decoration-layout = "icon:minimize,maximize,close";
    gtk-enable-animations = true;
    gtk-font-name = "Noto Sans,  10";
    gtk-icon-theme-name = "breeze-dark";
    gtk-primary-button-warps-slider = true;
    gtk-sound-theme-name = "ocean";
    gtk-xft-dpi = 98304;
  };
in
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;
  services.displayManager.defaultSession = "plasma";

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    okular
    elisa
    khelpcenter
    krdp
    discover
  ];

  hardware.bluetooth.enable = true;
  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;

  programs.kdeconnect.enable = true;
  programs.partition-manager.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.filelight
    kdePackages.kcalc
    kdePackages.kdialog
    kdePackages.plasma-thunderbolt
    kdePackages.plymouth-kcm
    haruna
    xsettingsd
    capitaine-cursors
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    cantarell-fonts
    dejavu_fonts
    liberation_ttf
    open-sans
    ttf_bitstream_vera
    fira-sans
    nerd-fonts.meslo-lg
    nerd-fonts.fantasque-sans-mono
  ];

  environment.etc = {
    "xdg/kdeglobals".text = ini {
      General.ColorScheme = "BreezeDark";
      Icons.Theme = "breeze-dark";
      KDE = {
        AnimationDurationFactor = "0.25";
        LookAndFeelPackage = "org.kde.breezedark.desktop";
        widgetStyle = "Breeze";
      };
    };

    "xdg/kcminputrc".text = ini { Mouse.cursorTheme = "capitaine-cursors"; };

    "xdg/ksmserverrc".text = ini { General.loginMode = "emptySession"; };

    "xdg/arkrc".text = ini { Extraction.openDestinationFolderAfterExtraction = true; };

    "xdg/baloofilerc".text = ini {
      "Basic Settings".Indexing-Enabled = false;
      General = {
        "exclude filters version" = 9;
        "exclude filters" = lib.concatStringsSep "," [
          "*~"
          "*.part"
          "*.o"
          "*.la"
          "*.lo"
          "*.loT"
          "*.moc"
          "moc_*.cpp"
          "qrc_*.cpp"
          "ui_*.h"
          "cmake_install.cmake"
          "CMakeCache.txt"
          "CTestTestfile.cmake"
          "libtool"
          "config.status"
          "confdefs.h"
          "autom4te"
          "conftest"
          "confstat"
          "Makefile.am"
          "*.gcode"
          ".ninja_deps"
          ".ninja_log"
          "build.ninja"
          "*.csproj"
          "*.m4"
          "*.rej"
          "*.gmo"
          "*.pc"
          "*.omf"
          "*.aux"
          "*.tmp"
          "*.po"
          "*.vm*"
          "*.nvram"
          "*.rcore"
          "*.swp"
          "*.swap"
          "lzo"
          "litmain.sh"
          "*.orig"
          ".histfile.*"
          ".xsession-errors*"
          "*.map"
          "*.so"
          "*.a"
          "*.db"
          "*.qrc"
          "*.ini"
          "*.init"
          "*.img"
          "*.vdi"
          "*.vbox*"
          "vbox.log"
          "*.qcow2"
          "*.vmdk"
          "*.vhd"
          "*.vhdx"
          "*.sql"
          "*.sql.gz"
          "*.ytdl"
          "*.tfstate*"
          "*.class"
          "*.pyc"
          "*.pyo"
          "*.elc"
          "*.qmlc"
          "*.jsc"
          "*.fastq"
          "*.fq"
          "*.gb"
          "*.fasta"
          "*.fna"
          "*.gbff"
          "*.faa"
          "po"
          "CVS"
          ".svn"
          ".git"
          "_darcs"
          ".bzr"
          ".hg"
          "CMakeFiles"
          "CMakeTmp"
          "CMakeTmpQmake"
          ".moc"
          ".obj"
          ".pch"
          ".uic"
          ".npm"
          ".yarn"
          ".yarn-cache"
          "__pycache__"
          "node_modules"
          "node_packages"
          "nbproject"
          ".terraform"
          ".venv"
          "venv"
          "core-dumps"
          "lost+found"
        ];
      };
    };

    "xdg/gtk-3.0/settings.ini".text = ini {
      Settings = gtkSettings // {
        gtk-button-images = true;
        gtk-menu-images = true;
        gtk-theme-name = "Breeze";
        gtk-toolbar-style = 3;
      };
    };

    "xdg/gtk-4.0/settings.ini".text = ini { Settings = gtkSettings; };
  };
}
