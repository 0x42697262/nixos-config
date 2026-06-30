# Base CLI tooling installed on every host. Editors (vim/neovim) and git come
# from programs.nix / editors.nix, so they intentionally aren't listed here.
# Hosts add their own extras via their own environment.systemPackages.
{ pkgs, ... }: {
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
}
