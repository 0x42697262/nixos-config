# Incus role

`incus.nix` turns a host configuration into an [Incus](https://linuxcontainers.org/incus/)
system container image. It is a role, not a feature flag — a host imports it
directly instead of enabling an option, and everything it sets is
unconditional.

The role pulls in two upstream nixpkgs modules:

| Module | Provides |
| --- | --- |
| `virtualisation/lxc-container.nix` | `boot.isContainer`, the `register-nix-paths` boot service, and `system.build.tarball` — the container rootfs. |
| `virtualisation/lxc-image-metadata.nix` | `system.build.metadata` — the `metadata.yaml` tarball Incus needs to recognize the image. Not imported by `lxc-container.nix`, so it has to be listed separately. |

On top of those it configures networking and trims a couple of defaults that
make no sense inside a container:

- `dhcpcd`, `networking.useDHCP`, and `useHostResolvConf` are all off, in favor
  of `systemd-networkd`.
- A single network, `50-eth0`, takes IPv4 DHCP and accepts IPv6 RAs, and is
  required for `network-online.target`.
- `myProfiles.zram` off (the host handles swap), `myProfiles.interactive` on.

## Using it in a host

The role carries no options, so a host only supplies its identity:

```nix
{ ... }: {
  imports = [ ../../modules/roles/incus.nix ];

  networking.hostName = "owasp";

  system.stateVersion = "26.11";
}
```

Then register it in `flake.nix` like any other host:

```nix
owasp = mkHost {
  system = "x86_64-linux";
  modules = [ ./hosts/owasp ];
};
```

## Building an image

Two artifacts, built from the same configuration. Both derivations name their
output file identically — `nixos-image-lxc-<version>-<system>.tar.xz` — so give
them separate output paths or they collide:

```fish
nix build .#nixosConfigurations.owasp.config.system.build.tarball  -o /tmp/owasp-rootfs
nix build .#nixosConfigurations.owasp.config.system.build.metadata -o /tmp/owasp-meta
```

The rootfs is a full system closure and runs a few hundred MB; the metadata
tarball is well under a kilobyte. Building outside the repository keeps the
`result` symlinks from dirtying the worktree.

For a cheap syntax and option check before either build, evaluate the
derivation without realizing it:

```fish
nix eval .#nixosConfigurations.owasp.config.system.build.tarball.drvPath
```

## Importing and launching

`incus image import` takes the **metadata tarball first**, then the rootfs.
Reversing them fails:

```fish
incus image import /tmp/owasp-meta/tarball/*.tar.xz /tmp/owasp-rootfs/tarball/*.tar.xz \
  --alias owasp

incus launch owasp owasp
incus exec owasp -- bash
```

## Testing a host before it is in `flake.nix`

Flakes only see git-tracked files, so a brand-new `hosts/<name>/` directory is
invisible until it is at least staged:

```fish
git add -N hosts/owasp modules/roles/incus.nix
```

To skip `flake.nix` entirely, build the same module set by hand against the
locked nixpkgs. Referencing the paths directly also sidesteps the git
requirement above:

```fish
nix eval --impure --raw --expr '
let
  flake = builtins.getFlake "/home/chicken/Projects/nixos-config";
  root = /home/chicken/Projects/nixos-config;
in (flake.inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { self = flake; inputs = flake.inputs; };
  modules = [ (root + "/modules/common") (root + "/modules/profiles") (root + "/hosts/owasp") ];
}).config.system.build.tarball.drvPath'
```

The `specialArgs` have to be passed explicitly here, since `mkHost` is what
normally supplies `self` and `inputs`.

## Caveats

**The interface must be named `eth0`.** `50-eth0` matches on that name only, so
a container whose nic device is named anything else comes up with no address.
Incus's `default` profile does use `eth0`; a custom profile may not.

**An image is host-specific.** `networking.hostName` is baked in, so every
container launched from the image reports the same name internally. For one
reusable image, drop `hostName` from the host and render `/etc/hostname` from
`{{ container.name }}` with `virtualisation.lxc.templates` — the option is
documented in nixpkgs' `lxc-image-metadata.nix`.

**There is no `/etc/nixos` in the image.** `nixos-rebuild` inside a fresh
container has nothing to build. Either rebuild and re-import the image for each
change, or clone this repository into the container and run
`nixos-rebuild switch --flake .#owasp` there — `register-nix-paths` sets up the
store database and the `system` profile on first boot, so that path does work.
