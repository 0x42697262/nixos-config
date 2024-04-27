# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  #boot.loader.grub.device = "/dev/vda";
  #boot.loader.grub.efiSupport = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableAllFirmware = true;

  boot.supportedFilesystems = [ "btrfs" ];
  boot.tmp.useTmpfs = true;




  fileSystems."/" =
    {
      options = [ "subvol=root" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    };


  fileSystems."/home" =
    {
      options = [ "compress=zstd:3" "relatime" "discard=async" "ssd" "space_cache=v2" ];
    };

  fileSystems."/nix" =
    {
      options = [ "subvol=nix" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    };

  fileSystems."/persist" =
    {
      options = [ "subvol=persist" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
    };

  fileSystems."/var/log" =
    {
      options = [ "subvol=log" "compress=zstd:3" "discard=async" "noatime" "ssd" "space_cache=v2" ];
      neededForBoot = true;
    };

  fileSystems."/birb" =
    {
      options = [ "compress=zstd:3" "discard=async" "relatime" "ssd" "space_cache=v2" ];
    };

  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /mnt
    mount -t btrfs /dev/mapper/root /mnt
    btrfs subvolume delete /mnt/root
    btrfs subvolume snapshot /mnt/root-clean /mnt/root
  '';

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "AtomicBird"; # Define your hostname.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chewing
      fcitx5-mozc
    ];

  };





  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  users.defaultUserShell = pkgs.fish;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.birb = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "video"
      "networkmanager"
      "docker"
    ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      fishPlugins.tide
      vlc
      mpv
      antora
      asciidoc-full-with-plugins
      asciidoctor-with-extensions
      dunst
      grimblast
      lazygit
      zathura
      lxqt.lxqt-policykit
      lynx
      metasploit
      neofetch
      nvtop
      obs-studio
      openssl
      pavucontrol
      rofi
      slurp
      texliveFull
      thunderbird
      tree
      typst
      udiskie
      waybar
      wget
    ];
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;

  };
  programs.firejail = {
    enable = true;
    wrappedBinaries = {

      # osu = {
      #   executable = "${pkgs.osu-lazer-bin}/bin/osu!";
      #   extraArgs = [
      #     "--private=~/firejail"
      #     "--noprofile"
      #   ];
      # };

      chromium = {
        executable = "${pkgs.chromium}/bin/chromium";
        extraArgs = [
          "--private=~/firejail"
          "--noprofile"
        ];
      };

      appimage-run = {
        executable = "${pkgs.appimage-run}/bin/appimage-run";
        extraArgs = [
          "--private=~/firejail"
          "--noprofile"
        ];
      };

      geekbench = {
        executable = "${pkgs.geekbench}/bin/geekbench6";
        extraArgs = [
          "--private=~/firejail"
          "--noprofile"
        ];
      };
    };
  };

  environment.shellAliases = {
    ls = "lsd -la";
    ".." = "cd ..";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    "....." = "cd ../../../..";
    "......" = "cd ../../../../..";
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #cpupower
    acpilight
    btop
    firefox
    lsd
    git
    gparted
    htop
    kitty
    ncdu
    neovim
    nmap
    openvpn
    pciutils
    pkgs.linuxKernel.packages.linux_latest_libre.cpupower
    unzip
    usbutils
    vim
    w3m
    wireplumber
    wl-clipboard-rs
    zstd
  ];

  fonts.packages = with pkgs; [
    meslo-lgs-nf
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    vistafonts
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  hardware.bluetooth.enable = true;

  hardware.opentabletdriver = {
    enable = true;
    daemon.enable = true;
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    prime.amdgpuBusId = "PCI:0:6:0";
    prime.nvidiaBusId = "PCI:0:1:0";
    prime.offload = {
      enable = true;
      enableOffloadCmd = true;
    };
  };

  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
  services.blueman.enable = true;
  services.udisks2.enable = true;

  # List services that you want to enable:
  # services.automatic-timezoned.enable = true;
  services.timesyncd.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  systemd.services = {
    sshd = {
      wantedBy = lib.mkForce [ ];
    };
    NetworkManager-wait-online.wantedBy = lib.mkForce [ ];
    vmware-networks.wantedBy = lib.mkForce [ ];
  };

  boot.extraModprobeConfig = "options kvm_amd nested=1";
  # boot.extraModprobeConfig = ''
  #   blacklist nouveau
  #   options nouveau modeset=0
  # '';
  #
  # services.udev.extraRules = ''
  #   # Remove NVIDIA USB xHCI Host Controller devices, if present
  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
  #   # Remove NVIDIA USB Type-C UCSI devices, if present
  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
  #   # Remove NVIDIA Audio devices, if present
  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
  #   # Remove NVIDIA VGA/3D controller devices
  #   ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  # '';
  # boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];


  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    storageDriver = "btrfs";
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  virtualisation.vmware.host = {
    enable = true;
  };
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      ovmf = {
        enable = true;
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
    allowedBridges = [
      "nm-bridge"
      "virbr0"
    ];
  };
  programs.virt-manager = {
    enable = true;
  };

  programs.fish = {
    enable = true;
    shellInit = ''
      set -g fish_greeting
    '';
    shellAbbrs = {
      Ns = "nix-shell -p --command fish";
      Nd = "nix develop";
    };
  };

  security.polkit.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

}
