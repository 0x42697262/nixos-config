{
  config,
  lib,
  pkgs,
  ...
}:
let
  desktop = config.myProfiles.desktop;
  cfg = desktop.plasma;

  ini = lib.generators.toINI { };

  kdeglobals = lib.recursiveUpdate (cfg.config.kdeglobals or { }) (
    lib.optionalAttrs (cfg.colorScheme.name != null) { General.ColorScheme = cfg.colorScheme.name; }
  );

  kdeglobalsFile = pkgs.runCommand "kdeglobals" { } ''
    cat ${cfg.colorScheme.package}/share/color-schemes/${cfg.colorScheme.name}.colors > $out
    printf '\n' >> $out
    cat ${pkgs.writeText "kdeglobals-settings" (ini kdeglobals)} >> $out
  '';

  configFiles = lib.mapAttrs' (file: groups: lib.nameValuePair "xdg/${file}" { text = ini groups; }) (
    removeAttrs cfg.config [ "kdeglobals" ]
  );
in
{
  options.myProfiles.desktop.plasma = {
    enable = lib.mkEnableOption "the KDE Plasma 6 session";

    excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Packages removed from NixOS's default Plasma application set.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional KDE applications and themes.";
    };

    kdeconnect.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "KDE Connect, including its firewall ports.";
    };

    partitionManager.enable = lib.mkEnableOption "KDE Partition Manager";

    colorScheme = {
      name = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "BreezeDark";
        description = ''
          Default color scheme. Its colors are written into the system-wide
          kdeglobals so they apply before the scheme is ever chosen in
          System Settings.
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kdePackages.breeze;
        defaultText = lib.literalExpression "pkgs.kdePackages.breeze";
        description = "Package providing share/color-schemes/<name>.colors.";
      };
    };

    config = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.attrsOf (
          lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.float
              lib.types.str
            ]
          )
        )
      );
      default = { };
      example = {
        kdeglobals.KDE.AnimationDurationFactor = "0.5";
        baloofilerc."Basic Settings".Indexing-Enabled = false;
      };
      description = ''
        KDE configuration written to /etc/xdg as system-wide defaults
        (file, group, key). Anything in a user's ~/.config still wins.
      '';
    };
  };

  config = lib.mkIf (desktop.enable && cfg.enable) {
    services.desktopManager.plasma6.enable = true;
    environment.plasma6.excludePackages = cfg.excludePackages;
    environment.systemPackages = cfg.extraPackages;

    programs.kdeconnect.enable = cfg.kdeconnect.enable;
    programs.partition-manager.enable = cfg.partitionManager.enable;

    environment.etc =
      configFiles
      // lib.optionalAttrs (kdeglobals != { } && cfg.colorScheme.name == null) {
        "xdg/kdeglobals".text = ini kdeglobals;
      }
      // lib.optionalAttrs (cfg.colorScheme.name != null) {
        "xdg/kdeglobals".source = kdeglobalsFile;
      };
  };
}
