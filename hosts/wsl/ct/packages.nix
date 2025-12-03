{ config, libs, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    gh
  ];
  programs._1password = {
    enable = true;
  };

}
