# Role: incus
# A NixOS system container for Incus. Builds both halves of an importable image
# (rootfs + metadata), and defines the single unprivileged account these
# containers are driven through.
#
# `gui.enable` adds the guest side of running graphical apps against the host's
# compositor. The host side -- passing the GPU in and bind-mounting the Wayland /
# X11 / PipeWire sockets -- is Incus instance configuration that cannot be
# expressed here; apply it with scripts/apply-nixos-gui-profile.sh from the
# incus-profiles repo (v2 branch), which resolves that session's uid and socket
# names. Note that cloud-init is not enabled on NixOS containers, so the
# vendor-data blocks in the older Arch-oriented Incus profiles do nothing here --
# everything they attempted has to live in this role instead.
{ config, lib, pkgs, modulesPath, ... }:
let
  cfg = config.myRoles.incus;

  user = "chicken";
  # Pinned rather than left to useradd: the host's Incus profile hardcodes this
  # number in its gpu device and in the /run/user/<uid> paths it sources sockets
  # from, so an allocated-by-chance uid would not line up.
  uid = 1000;
  runtimeDir = "/run/user/${toString uid}";

  # Where the host's socket devices land. The names inside are the contract with
  # the Incus profile and are deliberately fixed -- the host may call its socket
  # wayland-0 or wayland-1 and this side never has to know, because the device
  # `path:` renames it on the way in.
  socketDir = "/mnt/.sockets";
in
{
  imports = [
    "${modulesPath}/virtualisation/lxc-image-metadata.nix"
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  options.myRoles.incus.gui.enable = lib.mkEnableOption ''
    graphical apps over sockets passed in from the Incus host. Pair with
    myProfiles.security.gui.enable for the graphical security tools themselves
  '';

  config = lib.mkMerge [
    {
      networking = {
        dhcpcd.enable = false;
        useDHCP = false;
        useHostResolvConf = false;
      };

      systemd.network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };

      users.users.${user} = {
        isNormalUser = true;
        description = user;
        inherit uid;
        extraGroups = [ "wheel" "video" "audio" ];
        hashedPassword = null;
      };

      # No password is set: the account is reached through `incus exec`, never a
      # login prompt, so sudo must not ask for one either. Scoped to this user
      # rather than security.sudo.wheelNeedsPassword, which would drop the
      # prompt for every wheel member. Rendered after the %wheel rule, and the
      # last match in sudoers wins.
      security.sudo.extraRules = [
        {
          users = [ user ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      myProfiles.zram.enable = false;
      myProfiles.interactive.enable = true;
    }

    (lib.mkIf cfg.gui.enable {
      # Recreated on every boot: the sockets come and go with the host's
      # session, and tmpfiles runs before anyone execs in -- unlike an
      # /etc/profile hook, which needs a login shell to fire. Left of the arrow
      # is the canonical name clients expect inside the container, right is the
      # normalized name the Incus profile mounts to.
      systemd.tmpfiles.rules = [
        "d ${runtimeDir} 0700 ${user} ${user} -"
        "d /tmp/.X11-unix 1777 root root -"
        "L+ ${runtimeDir}/wayland-0 - - - - ${socketDir}/wayland"
        "L+ ${runtimeDir}/pipewire-0 - - - - ${socketDir}/pipewire"
        "L+ /tmp/.X11-unix/X0 - - - - ${socketDir}/x11"
      ];

      # Mesa and friends for the passed-through GPU. The container renders
      # locally; only the finished surface goes back over the socket.
      hardware.graphics.enable = true;

      # Java Swing (Burp, ZAP, Ghidra) and Qt (Cutter) both refuse to look
      # presentable without fontconfig and a real font on disk.
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          dejavu_fonts
          liberation_ttf
          noto-fonts
          noto-fonts-color-emoji
        ];
      };

      # /etc/profile only, so `incus exec` with a non-login shell will not see
      # these. The Incus profile sets the same variables as `environment.*`
      # keys, which do reach every exec; these are the login-shell fallback.
      environment.sessionVariables = {
        XDG_RUNTIME_DIR = runtimeDir;
        XDG_SESSION_TYPE = "wayland";
        WAYLAND_DISPLAY = "wayland-0";
        DISPLAY = ":0";
        QT_QPA_PLATFORM = "wayland";
        PULSE_SERVER = "unix:${socketDir}/pulse-native";
        # Swing draws its own decorations wrong under tiling compositors
        # without this, which is how Burp and Ghidra end up a blank gray window.
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };

      environment.systemPackages = with pkgs; [
        wayland-utils # wayland-info, to prove the socket works
        mesa-demos # glxinfo / glxgears, same for the GPU
        pulseaudio # pactl, to prove audio reached the host
      ];
    })
  ];
}
