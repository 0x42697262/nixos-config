{ config, lib, pkgs, ... }: {
  programs.fish = {
    enable = true;
    shellInit = "set -g fish_greeting";
    shellAbbrs = {
      Ns = "nix-shell -p --command fish";
      Nd = "nix develop";
    };
  };
}
