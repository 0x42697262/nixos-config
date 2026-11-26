# Profile: llmAgents
# LLM coding agents for the terminal. Each agent has its own toggle under
# the profile; claude-code and agy are unfree (allowUnfree is set in
# modules/common/nix.nix).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.myProfiles.llmAgents;
in
{
  options.myProfiles.llmAgents = {
    enable = lib.mkEnableOption "LLM coding agents";

    claudeCode.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Anthropic's Claude Code (`claude`).";
    };

    antigravity.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Google's Antigravity CLI (`agy`).";
    };

    piBolt.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Pi-Bolt (`pi-bolt`), the Pi coding agent compiled ahead of time
        (pkgs/pi-bolt.nix). Install telemetry is off unless PI_TELEMETRY is set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optional cfg.claudeCode.enable pkgs.claude-code
      ++ lib.optional cfg.antigravity.enable pkgs.antigravity-cli
      ++ lib.optional cfg.piBolt.enable (pkgs.callPackage ../../pkgs/pi-bolt.nix { });
  };
}
