# Profile: shell
# Fish as the login shell, with the tide prompt.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.shell;
in
{
  options.myProfiles.shell.enable =
    lib.mkEnableOption "fish shell with the tide prompt";

  config = lib.mkIf cfg.enable {
    users.defaultUserShell = pkgs.fish;

    programs.fish = {
      enable = true;
      shellInit = "set -g fish_greeting";
      shellAbbrs = {
        Ns = "nix-shell -p --command fish";
        Nd = "nix develop";
      };
    };

    environment.systemPackages = [ pkgs.fishPlugins.tide ];
  };
}
