# Profile: gaming
# Steam, gamemode, and friends. Scaffold -- fill in as needed. Usually paired
# with myProfiles.desktop.enable on the same host.
{ config, lib, ... }:
let
  cfg = config.myProfiles.gaming;
in
{
  options.myProfiles.gaming.enable =
    lib.mkEnableOption "gaming (Steam, gamemode, etc.)";

  config = lib.mkIf cfg.enable {
    # TODO: for example:
    # programs.steam.enable = true;
    # programs.gamemode.enable = true;
  };
}
