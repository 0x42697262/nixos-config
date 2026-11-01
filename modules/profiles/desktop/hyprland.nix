{
  config,
  lib,
  pkgs,
  ...
}:
let
  desktop = config.myProfiles.desktop;
  cfg = desktop.hyprland;
in
{
  options.myProfiles.desktop.hyprland = {
    enable = lib.mkEnableOption "the Hyprland session (managed by UWSM)";

    shell = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      example = lib.literalExpression "pkgs.callPackage ../../../pkgs/noctalia.nix { }";
      description = ''
        Desktop shell (bar, launcher, notifications, lock screen, polkit
        agent) installed alongside Hyprland. The Hyprland config is
        expected to start it.
      '';
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Applications and tools the Hyprland config uses (terminal, screenshot tools, themes...).";
    };

    skel = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Directory of dotfiles copied into a user's home at login, before
        the session starts, while ~/.config/hypr does not exist yet.
        Existing files are never overwritten.
      '';
    };

    xhostRoot = lib.mkEnableOption "the xhost tool, for granting root access to XWayland (xhost +SI:localuser:root)";
  };

  config = lib.mkIf (desktop.enable && cfg.enable) (
    lib.mkMerge [
      {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
          xwayland.enable = true;
        };

        services.gnome.gnome-keyring.enable = true;
        security.polkit.enable = true;
        hardware.i2c.enable = true;

        environment.systemPackages =
          lib.optional (cfg.shell != null) cfg.shell
          ++ lib.optional cfg.xhostRoot pkgs.xhost
          ++ cfg.extraPackages;

        environment.extraInit = lib.mkIf config.myProfiles.nvidia.enable ''
          if [ -d /sys/module/nvidia ] && [ ! -d /sys/module/i915 ] && [ ! -d /sys/module/xe ] && [ ! -d /sys/module/amdgpu ]; then
            export GBM_BACKEND=nvidia-drm
            export EGL_PLATFORM=wayland
          fi
        '';
      }

      (lib.mkIf (cfg.skel != null) {
        systemd.user.services.hyprland-skel = {
          description = "Seed Hyprland dotfiles into the home directory";
          wantedBy = [ "default.target" ];
          before = [ "graphical-session-pre.target" ];
          unitConfig.ConditionPathExists = "!%h/.config/hypr";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/cp -r --update=none --no-preserve=mode,ownership ${cfg.skel}/. %h/";
          };
        };
      })
    ]
  );
}
