{ config, lib, pkgs, ... }: {
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.vim.enable = true;
}
