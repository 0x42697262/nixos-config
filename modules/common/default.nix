# Common configuration shared by every host. Importing this single file pulls
# in the whole baseline (Nix settings, packages, locale, shells, editors, etc.)
# so a host only has to declare what makes it different.
{ ... }: {
  imports = [
    ./editors.nix
    ./locale.nix
    ./nix.nix
    ./packages.nix
    ./programs.nix
    ./shells.nix
    ./users.nix
  ];
}
