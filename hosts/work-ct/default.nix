# work-ct -- VirtualBox VM. Not wired into the flake by default; see flake.nix.
{ pkgs, ... }: {
  imports = [ ./hardware.nix ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "work-ct";
  networking.networkmanager.enable = true;

  # Keymap in X11.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define the user account. Set a password with `passwd`.
  users.users.chicken = {
    isNormalUser = true;
    description = "chicken";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  system.stateVersion = "25.11";
}
