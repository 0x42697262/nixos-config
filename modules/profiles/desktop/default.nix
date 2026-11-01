{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.desktop;

  ini = lib.generators.toINI { };

  settingsType = lib.types.attrsOf (
    lib.types.oneOf [
      lib.types.bool
      lib.types.int
      lib.types.str
    ]
  );

  sessions = lib.filter (name: cfg.${name}.enable or false) [
    "plasma"
    "hyprland"
  ];
in
{
  imports = [
    ./plasma.nix
  ];

  options.myProfiles.desktop = {
    enable = lib.mkEnableOption "a graphical desktop (login manager, fonts, Bluetooth, firmware updates)";

    displayManager = lib.mkOption {
      type = lib.types.enum [
        "plasma-login-manager"
        "sddm"
      ];
      default = "sddm";
      description = "Login manager. A host runs exactly one; it offers every enabled desktop session.";
    };

    defaultSession = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "plasma";
      description = "Session preselected by the login manager.";
    };

    fonts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
      description = "Font packages installed system-wide.";
    };

    bluetooth.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Bluetooth stack.";
    };

    fwupd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "fwupd firmware updates (UEFI, docks, peripherals).";
    };

    gtk = {
      settings = lib.mkOption {
        type = settingsType;
        default = { };
        description = "System-wide GTK 3 and GTK 4 settings.ini defaults (/etc/xdg).";
      };

      gtk3Settings = lib.mkOption {
        type = settingsType;
        default = { };
        description = "Extra keys for GTK 3 only, for settings GTK 4 removed.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = sessions != [ ];
        message = "myProfiles.desktop is enabled without a desktop session; enable myProfiles.desktop.plasma or another session.";
      }
    ];

    services.displayManager.plasma-login-manager.enable = lib.mkIf (
      cfg.displayManager == "plasma-login-manager"
    ) true;

    services.displayManager.sddm = lib.mkIf (cfg.displayManager == "sddm") {
      enable = true;
      wayland.enable = true;
    };

    services.displayManager.defaultSession = lib.mkIf (cfg.defaultSession != null) cfg.defaultSession;

    fonts.packages = cfg.fonts;

    hardware.bluetooth.enable = lib.mkIf cfg.bluetooth.enable true;
    services.fwupd.enable = lib.mkIf cfg.fwupd.enable true;

    environment.etc."xdg/gtk-3.0/settings.ini" =
      lib.mkIf (cfg.gtk.settings != { } || cfg.gtk.gtk3Settings != { })
        {
          text = ini { Settings = cfg.gtk.settings // cfg.gtk.gtk3Settings; };
        };

    environment.etc."xdg/gtk-4.0/settings.ini" = lib.mkIf (cfg.gtk.settings != { }) {
      text = ini { Settings = cfg.gtk.settings; };
    };
  };
}
