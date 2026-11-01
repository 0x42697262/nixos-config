{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.power;
in
{
  options.myProfiles.power = {
    enable = lib.mkEnableOption "power-profiles-daemon";

    intelLpmd = {
      enable = lib.mkEnableOption "the Intel Low Power Mode Daemon (hybrid Intel CPUs, Alder Lake and newer)";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../../pkgs/intel-lpmd.nix { };
        defaultText = lib.literalExpression "pkgs.callPackage ../../pkgs/intel-lpmd.nix { }";
        description = "intel-lpmd package to run.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.power-profiles-daemon.enable = true;
    })

    (lib.mkIf cfg.intelLpmd.enable {
      environment.systemPackages = [ cfg.intelLpmd.package ];
      systemd.packages = [ cfg.intelLpmd.package ];
      services.dbus.packages = [ cfg.intelLpmd.package ];
      systemd.services.intel_lpmd.wantedBy = [ "multi-user.target" ];
    })
  ];
}
