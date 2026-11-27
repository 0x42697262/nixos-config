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
      description = "Pi-Bolt (`pi-bolt`).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      lib.optional cfg.claudeCode.enable pkgs.claude-code
      ++ lib.optional cfg.antigravity.enable pkgs.antigravity-cli
      ++ lib.optional cfg.piBolt.enable (pkgs.callPackage ../../pkgs/pi-bolt.nix { });
  };
}
