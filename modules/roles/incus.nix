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
  users.users.chicken = {
    isNormalUser = true;
    description = "chicken";
    extraGroups = [ "wheel" ];
    hashedPassword = null;
  };
  security.sudo.extraRules = [
    {
      users = [ "chicken" ];
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
