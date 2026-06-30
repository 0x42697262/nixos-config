# Profile: editors
# Terminal editors -- neovim (primary) and vim (fallback).
{ config, lib, ... }:
let
  cfg = config.myProfiles.editors;
in
{
  options.myProfiles.editors.enable =
    lib.mkEnableOption "terminal editors (neovim + vim)";

  config = lib.mkIf cfg.enable {
    programs.neovim.enable = true;
    programs.vim.enable = true;
  };
}
