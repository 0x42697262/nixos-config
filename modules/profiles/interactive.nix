# Profile: interactive
# Everything a machine you actually sit at and use wants -- editors, a real
# shell, and the day-to-day CLI tooling. Headless servers leave this off.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.interactive;
in
{
  options.myProfiles.interactive.enable =
    lib.mkEnableOption "interactive workstation tooling (editors, shell, CLI extras)";

  config = lib.mkIf cfg.enable {
    # Default login shell.
    users.defaultUserShell = pkgs.fish;

    # Editors.
    programs.neovim.enable = true;
    programs.vim.enable = true;

    # Dev / CLI programs.
    programs.git.enable = true;
    programs.lazygit.enable = true;
    programs.tmux.enable = true;
    programs.ssh.startAgent = true;

    # Shell.
    programs.fish = {
      enable = true;
      shellInit = "set -g fish_greeting";
      shellAbbrs = {
        Ns = "nix-shell -p --command fish";
        Nd = "nix develop";
      };
    };

    # Base CLI tooling.
    environment.systemPackages = with pkgs; [
      btop
      curl
      fishPlugins.tide
      lsd
      ncdu
      ripgrep
      unzip
      wget
    ];
  };
}
