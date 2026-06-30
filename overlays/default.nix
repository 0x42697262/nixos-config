# nixpkgs overlays. Add package overrides/additions here, then wire this in
# via `nixpkgs.overlays = [ (import ./overlays) ];` from a module when needed.
_final: _prev: {
  # example:
  # myPackage = _prev.myPackage.overrideAttrs (old: { ... });
}
