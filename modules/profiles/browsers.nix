{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.browsers;
in
{
  options.myProfiles.browsers.enable = lib.mkEnableOption "everyday web browsers (Firefox and Brave)";

  config = lib.mkIf cfg.enable {
    programs.firefox.enable = true;

    environment.systemPackages = [ pkgs.brave ];
  };
}
