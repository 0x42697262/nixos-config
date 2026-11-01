{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.audio;

  hdaPowerSave = pkgs.writeShellScript "hda-power-save" ''
    PARAM=/sys/module/snd_hda_intel/parameters/power_save
    STATE=/run/udev/snd-hda-intel-powersave
    save() { cur="$(cat "$PARAM")"; [ "$cur" != 0 ] && echo "$cur" > "$STATE"; return 0; }
    is_on_ac() {
      for t in /sys/class/power_supply/*/type; do
        grep -q Mains "$t" 2>/dev/null || continue
        [ "$(cat "''${t%/type}/online" 2>/dev/null)" = 1 ] || return 1
      done
      return 0
    }
    case "$1" in
      init) is_on_ac || exit 0; save; echo 0 > "$PARAM" ;;
      battery) v="$(cat "$STATE" 2>/dev/null)"; echo "''${v:-10}" > "$PARAM" ;;
      ac) save; echo 0 > "$PARAM" ;;
    esac
  '';

  limit = domain: item: value: {
    inherit domain item value;
    type = "-";
  };
in
{
  options.myProfiles.audio = {
    enable = lib.mkEnableOption "PipeWire audio (ALSA, 32-bit ALSA, PulseAudio)";

    realtime.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        rtkit plus realtime limits for the audio and realtime groups, and
        group audio access to rtc0, hpet and cpu_dma_latency.
      '';
    };

    hdaPowerSaveOnBatteryOnly = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Turn snd_hda_intel power saving off while on AC (stops pops and
        crackling on many codecs) and restore it on battery.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      }

      (lib.mkIf cfg.realtime.enable {
        security.rtkit.enable = true;
        users.groups.realtime = { };
        security.pam.loginLimits = [
          (limit "@audio" "rtprio" "99")
          (limit "@audio" "nice" "-11")
          (limit "@realtime" "rtprio" "98")
          (limit "@realtime" "memlock" "unlimited")
          (limit "@realtime" "nice" "-11")
        ];
        services.udev.extraRules = ''
          KERNEL=="rtc0", GROUP="audio"
          KERNEL=="hpet", GROUP="audio"
          DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        '';
      })

      (lib.mkIf cfg.hdaPowerSaveOnBatteryOnly {
        services.udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="sound", KERNEL=="card*", DRIVERS=="snd_hda_intel", TEST!="/run/udev/snd-hda-intel-powersave", RUN+="${hdaPowerSave} init"
          ACTION=="add|change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="0", TEST=="/sys/module/snd_hda_intel", RUN+="${hdaPowerSave} battery"
          ACTION=="add|change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", ENV{POWER_SUPPLY_ONLINE}=="1", TEST=="/sys/module/snd_hda_intel", RUN+="${hdaPowerSave} ac"
        '';
      })
    ]
  );
}
