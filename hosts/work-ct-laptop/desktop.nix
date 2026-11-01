{ lib, pkgs, ... }:
{
  myProfiles.desktop = {
    enable = true;
    displayManager = "plasma-login-manager";
    defaultSession = "plasma";

    fonts = with pkgs; [
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

    gtk.settings = {
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

    gtk.gtk3Settings = {
      gtk-button-images = true;
      gtk-menu-images = true;
      gtk-theme-name = "Breeze";
      gtk-toolbar-style = 3;
    };

    plasma = {
      enable = true;
      partitionManager.enable = true;

      excludePackages = with pkgs.kdePackages; [
        okular
        elisa
        khelpcenter
        krdp
        discover
      ];

      extraPackages = with pkgs; [
        kdePackages.filelight
        kdePackages.kcalc
        kdePackages.kdialog
        kdePackages.plasma-thunderbolt
        kdePackages.plymouth-kcm
        haruna
        xsettingsd
        capitaine-cursors
      ];

      config = {
        kdeglobals = {
          General.ColorScheme = "BreezeDark";
          Icons.Theme = "breeze-dark";
          KDE = {
            AnimationDurationFactor = "0.25";
            LookAndFeelPackage = "org.kde.breezedark.desktop";
            widgetStyle = "Breeze";
          };
        };
        kcminputrc.Mouse.cursorTheme = "capitaine-cursors";
        ksmserverrc.General.loginMode = "emptySession";
        arkrc.Extraction.openDestinationFolderAfterExtraction = true;
        baloofilerc = {
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
      };
    };
  };

  services.hardware.bolt.enable = true;
}
