{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/modules/common/editors.nix"
    "${self}/modules/common/nix.nix"
    "${self}/modules/common/programs.nix"
    "${self}/modules/common/shells.nix"
    "${self}/modules/common/users.nix"
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
