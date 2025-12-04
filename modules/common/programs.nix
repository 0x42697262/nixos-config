{ config, lib, pkgs, ... }: {
  programs.lazygit.enable = true;
  programs.git.enable = true;
  programs.ssh = {
    startAgent = true;
  };
  programs.tmux.enable = true;
  programs.vim.enable = true;
}
