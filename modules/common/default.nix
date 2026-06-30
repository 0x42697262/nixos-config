# Base configuration applied to EVERY host (via mkHost), including headless
# servers. Keep this minimal -- only things that genuinely belong everywhere.
# Optional capabilities live in ../profiles (toggled per host with feature
# flags); machine "kinds" live in ../roles.
{ ... }: {
  imports = [
    ./nix.nix     # flakes + allowUnfree
    ./locale.nix  # timezone + locale
    ./maintenance.nix  # garbage collection, store optimise, tarball TTL
  ];
}
