# Nix store maintenance for every host: garbage collection, store optimisation,
# and flake-input cache TTL. All on by default and tunable via the
# myProfiles.maintenance.* knobs (override or disable per host).
{ config, lib, ... }:
let
  cfg = config.myProfiles.maintenance;
in
{
  options.myProfiles.maintenance = {
    gc = {
      enable = lib.mkEnableOption "automatic garbage collection" // {
        default = true;
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        example = "daily";
        description = "How often GC runs (systemd OnCalendar). 'weekly' is roughly every 7 days.";
      };

      keepDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 7;
        description = "Delete generations / unreferenced store paths older than this many days.";
      };
    };

    optimise = {
      enable = lib.mkEnableOption "automatic store optimisation (hardlink dedup)" // {
        default = true;
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "How often the store optimiser runs (systemd OnCalendar).";
      };
    };

    tarballTtlDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = ''
        How long fetched flake inputs / tarballs stay cached before Nix
        re-checks them upstream. Sets nix.settings.tarball-ttl.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.gc.enable {
      nix.gc = {
        automatic = true;
        dates = cfg.gc.interval;
        options = "--delete-older-than ${toString cfg.gc.keepDays}d";
      };
    })

    (lib.mkIf cfg.optimise.enable {
      nix.optimise = {
        automatic = true;
        dates = [ cfg.optimise.interval ];
      };
    })

    {
      # seconds = days * 24h * 60m * 60s
      nix.settings.tarball-ttl = cfg.tarballTtlDays * 24 * 60 * 60;
    }
  ];
}
