# Profile: desktop
# Graphical environment. Scaffold -- fill in your DE/compositor of choice.
{ config, lib, ... }:
let
  cfg = config.myProfiles.desktop;
in
{
  options.myProfiles.desktop.enable =
    lib.mkEnableOption "graphical desktop environment";

  config = lib.mkIf cfg.enable {
    # TODO: pick a desktop. For example (GNOME):
    # services.xserver.enable = true;
    # services.displayManager.gdm.enable = true;
    # services.desktopManager.gnome.enable = true;
  };
}
