{ config, lib, pkgs, ... }: {
  modules = [
    ../common/editors.nix
    ../common/nix.nix
    ../common/programs.nix
    ../common/shells.nix
    ../common/users.nix
  ];

  environment.systemPackages = with pkgs; [
    btop
    fishPlugins.tide
    lsd
    ncdu
    ripgrep
    unzip
  ];

}
