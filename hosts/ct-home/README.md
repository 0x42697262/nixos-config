# ct-home (Amazon EC2)

NixOS running on an Amazon EC2 instance. This file is my reminder for how to
get a fresh box building from this flake, since I always forget.

## What's already handled

The `configuration.nix` here imports nixpkgs' `amazon-image.nix` module, which
takes care of the EC2-specific plumbing:

- GRUB bootloader on the correct device
- growing the root partition to fill the EBS volume
- pulling the SSH key you picked at launch into the default user

So launching a NixOS AMI and SSHing in mostly just works. The steps below are
about turning that stock instance into something managed by **this** flake.

## 0. Launch the instance

This host runs on an **aarch64 / Graviton** instance:

- AMI ID:   `ami-08dea6dfd1b09cc4a`
- AMI name: `nixos/26.05.590.ec942ba042da-aarch64-linux`

That's why the flake pins `system = "aarch64-linux"`. Launch on a Graviton
instance type (e.g. `t4g.*`, `c7g.*`). If you ever rebuild on an x86_64 box
instead, switch the flake back to `x86_64-linux`.

SSH in with the key you selected at launch:

```sh
ssh root@<instance-public-ip>
```

## 1. Make sure flakes are enabled

NixOS AMIs don't enable flakes by default. The flake's own `nix.nix` module
turns them on permanently, but you need flakes available *once* to do the first
rebuild. Easiest is to pass them as flags (no config edit needed):

```sh
--extra-experimental-features "nix-command flakes"
```

(Used inline in step 3.)

## 2. Get this repo onto the box

```sh
nix-shell -p git --run "git clone https://github.com/0x42697262/nixos-config.git /etc/nixos/nixos-config"
```

Or copy it up with `scp -r` / `rsync` from your local machine.

## 3. Rebuild against this flake

The flake output for this host is `ct-home`:

```sh
nixos-rebuild switch \
  --flake /etc/nixos/nixos-config#ct-home \
  --extra-experimental-features "nix-command flakes"
```

After this first switch, `nix.nix` has enabled flakes system-wide, so future
rebuilds can drop the `--extra-experimental-features` flag:

```sh
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home
```

## 4. Day-to-day

```sh
# edit config, then:
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home

# pull newer nixpkgs:
nix flake update /etc/nixos/nixos-config
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home

# test a build without making it the boot default:
nixos-rebuild test --flake /etc/nixos/nixos-config#ct-home
```

## Notes

- `ct-home` is the **flake output name** (what `#ct-home` selects). The
  machine's actual hostname comes from EC2 metadata, not from the config.
- SSH, root-key import, disk growth and the bootloader are all provided by
  `amazon-image.nix` — don't re-declare them in `configuration.nix`. Just make
  sure the instance's security group allows inbound TCP 22.
- `ec2.efi = true;` is set because the instance boots via UEFI.
- The default login user / fish shell come from the common modules.
- `system.stateVersion` is pinned in `configuration.nix` — leave it alone on
  upgrades.
