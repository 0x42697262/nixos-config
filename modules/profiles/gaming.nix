# Profile: gaming
# Steam, gamemode, and friends. Scaffold -- fill in as needed. Usually paired
# with myProfiles.desktop.enable on the same host.
{ config, lib, pkgs, ... }:
let
  cfg = config.myProfiles.gaming;

  powerprofilesctl = "${config.services.power-profiles-daemon.package}/bin/powerprofilesctl";

  game-performance = pkgs.writeShellScriptBin "game-performance" ''
    if ! ${powerprofilesctl} list | grep -q 'performance:'; then
      exec "$@"
    fi
    if [ -n "''${GAME_PERFORMANCE_SCREENSAVER_ON:-}" ]; then
      exec ${powerprofilesctl} launch -p performance -r "game-performance" -- "$@"
    fi
    exec systemd-inhibit --why "game-performance is running" \
      ${powerprofilesctl} launch -p performance -r "game-performance" -- "$@"
  '';

  zink-run = pkgs.writeShellScriptBin "zink-run" ''
    export MESA_LOADER_DRIVER_OVERRIDE=zink
    export GALLIUM_DRIVER=zink
    export __GLX_VENDOR_LIBRARY_NAME=mesa
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
    exec "$@"
  '';

  dlss-swapper = pkgs.writeShellScriptBin "dlss-swapper" ''
    export PROTON_ENABLE_NGX_UPDATER=1
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_FG_OVERRIDE=on
    export DXVK_NVAPI_DRS_NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    export DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest
    exec "$@"
  '';
in
{
  options.myProfiles.gaming = {
    enable = lib.mkEnableOption "gaming (Steam, gamemode, etc.)";

    wrappers.enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.enable;
      defaultText = lib.literalExpression "config.myProfiles.gaming.enable";
      description = ''
        Launch wrappers: game-performance (run under the performance power
        profile and inhibit idle), zink-run (OpenGL on Vulkan via Zink) and
        dlss-swapper (Proton DLSS preset/version overrides).
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
    # TODO: for example:
    # programs.steam.enable = true;
    # programs.gamemode.enable = true;
    })

    (lib.mkIf cfg.wrappers.enable {
      myProfiles.power.enable = lib.mkDefault true;
      environment.systemPackages = [
        game-performance
        zink-run
        dlss-swapper
      ];
    })
  ];
}
