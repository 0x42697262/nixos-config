# Feature-flag profiles. Each file here declares its own `myProfiles.<name>`
# option and implements it behind a `lib.mkIf`. This module is applied to every
# host (via mkHost), so the flags are always available -- a host just flips the
# booleans for the capabilities it wants. All flags default to off.
{ ... }: {
  imports = [
    ./interactive.nix
    ./desktop.nix
    ./gaming.nix
  ];
}
