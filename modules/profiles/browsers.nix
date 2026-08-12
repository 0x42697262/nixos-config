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
  options.myProfiles.browsers.enable = lib.mkEnableOption "everyday web browsers";

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      policies.ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
      };
    };

    environment.systemPackages = [ pkgs.brave ];
  };
}
