{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.ananicy;
in
{
  options.myProfiles.ananicy = {
    enable = lib.mkEnableOption "ananicy-cpp automatic process nice/ionice/scheduling rules";

    package = lib.mkPackageOption pkgs "ananicy-cpp" { };

    rulesProvider = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Rule set to load. null keeps the NixOS default rule set.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = cfg.package;
      rulesProvider = lib.mkIf (cfg.rulesProvider != null) cfg.rulesProvider;
    };
  };
}
