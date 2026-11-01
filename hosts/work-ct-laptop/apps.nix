{ pkgs, ... }:
{
  myProfiles.browsers.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "chicken" ];
  };

  myProfiles.docker = {
    enable = true;
    users = [ "chicken" ];
  };

  virtualisation.docker.daemon.settings.ip-forward-no-drop = true;

  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui.enable = true;
    preseed = {
      networks = [
        {
          name = "incusbr0";
          type = "bridge";
          config = {
            "ipv4.address" = "10.185.97.1/24";
            "ipv4.nat" = "true";
            "ipv6.address" = "fd42:72b3:ba13:758::1/64";
            "ipv6.nat" = "true";
          };
        }
      ];
      storage_pools = [
        {
          name = "default";
          driver = "dir";
        }
      ];
      profiles = [
        {
          name = "default";
          devices = {
            eth0 = {
              name = "eth0";
              network = "incusbr0";
              type = "nic";
            };
            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  systemd.services.incus.unitConfig.RequiresMountsFor = [ "/mnt/new" ];

  networking.nftables.enable = true;
  networking.firewall.trustedInterfaces = [ "incusbr0" ];

  users.users.chicken.extraGroups = [ "incus-admin" ];
}
