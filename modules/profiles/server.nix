# Profile: server
{ config, lib, ... }:
let
  cfg = config.myProfiles.server;
in
{
  options.myProfiles.server.enable =
    lib.mkEnableOption "baesline server tooling (shell + editors + git + tmux)";

  config = lib.mkIf cfg.enable {
    # Pull in the finer-grained profiles.
    myProfiles.shell.enable = true;
    myProfiles.editors.enable = true;

    # Extras beyond the shell/editor basics.
    programs.git.enable = true;
    programs.tmux.enable = true;
  };
}
