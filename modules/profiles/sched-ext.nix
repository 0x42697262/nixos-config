{
  config,
  lib,
  ...
}:
let
  cfg = config.myProfiles.schedExt;
in
{
  options.myProfiles.schedExt = {
    enable = lib.mkEnableOption "a sched_ext BPF CPU scheduler";

    scheduler = lib.mkOption {
      type = lib.types.str;
      default = "scx_lavd";
      example = "scx_bpfland";
      description = "Scheduler binary from the scx package to run.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra arguments for the scheduler.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.scx = {
      enable = true;
      scheduler = cfg.scheduler;
      extraArgs = cfg.extraArgs;
    };
  };
}
