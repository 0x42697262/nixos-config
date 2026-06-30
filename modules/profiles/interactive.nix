# Profile: interactive
# A full workstation you sit at. Composes the smaller shell + editors profiles
# and adds the heavier day-to-day CLI tooling on top. Headless boxes that only
# want shell/editors should enable those flags directly instead of this one.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.interactive;
in
{
  options.myProfiles.interactive.enable =
    lib.mkEnableOption "full interactive workstation (shell + editors + extra CLI tooling)";

  config = lib.mkIf cfg.enable {
    # Pull in the finer-grained profiles.
    myProfiles.shell.enable = true;
    myProfiles.editors.enable = true;

    # Extras beyond the shell/editor basics.
    programs.git.enable = true;
    programs.lazygit.enable = true;
    programs.tmux.enable = true;
    programs.ssh.startAgent = true;

    environment.systemPackages = with pkgs; [
      btop
      curl
      lsd
      ncdu
      ripgrep
      unzip
      wget
    ];
  };
}
