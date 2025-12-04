{ config, libs, pkgs, ...}:

{
  environment.systemPackages = with pkgs; [
    gh
  ];

  programs._1password = {
    enable = true;
  };
  programs.ssh = {
    extraConfig = ''
      Host github.com
      User git
      AddKeysToAgent yes
      IdentityFile ~/.ssh/wsl-work-ct
    '';
  };
}
