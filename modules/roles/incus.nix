{ modulesPath, ... }: {

  imports = [
    "${modulesPath}/virtualisation/lxc-image-metadata.nix"
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];
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
  myProfiles.zram.enable = false;
  myProfiles.interactive.enable = true;

}
