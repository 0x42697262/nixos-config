{ config, libs, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [];
  programs._1password = {
    enable = true;
  };

}
