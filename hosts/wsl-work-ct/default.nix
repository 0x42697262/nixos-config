# wsl-work-ct -- work NixOS-WSL instance.
{ pkgs, ... }: {
  myProfiles.interactive.enable = true;
  myProfiles.zram.enable = false; 
  networking.hostName = "wsl-work-ct";

  wsl.enable = true;
  wsl.defaultUser = "chicken";

  environment.systemPackages = with pkgs; [ gh ];

  programs._1password.enable = true;

  programs.ssh.extraConfig = ''
    Host github.com
    User git
    AddKeysToAgent yes
    IdentityFile ~/.ssh/wsl-work-ct
  '';

  system.stateVersion = "25.05";
}
