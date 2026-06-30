# wsl2-tgt -- NixOS-WSL instance.
{ pkgs, ... }: {
  networking.hostName = "wsl2-tgt";

  wsl.enable = true;
  wsl.defaultUser = "slave";

  environment.systemPackages = with pkgs; [ nmap ];

  system.stateVersion = "24.11";
}
