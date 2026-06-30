# ct-home (Amazon EC2)

NixOS on an Amazon EC2 instance, managed by this flake. Reminder for how to get
a fresh box building from this repo, since I always forget.

## What's already handled

`hosts/ct-home/default.nix` imports the shared EC2 role
(`modules/roles/ec2.nix`), which pulls in nixpkgs' `amazon-image.nix`. That
module handles the EC2-specific plumbing:

- GRUB bootloader on the correct device
- growing the root partition to fill the EBS volume
- pulling the SSH key you picked at launch into the root user

So a stock NixOS AMI + SSH mostly just works. The steps below turn that stock
instance into something managed by **this** flake.

## 0. Launch the instance

This host runs on an **aarch64 / Graviton** instance:

- AMI ID:   `ami-08dea6dfd1b09cc4a`
- AMI name: `nixos/26.05.590.ec942ba042da-aarch64-linux`

That's why the flake pins `system = "aarch64-linux"` for this host. Launch a
Graviton instance type (`t4g.*`, `c7g.*`), and make sure the security group
allows inbound TCP 22. SSH in with your launch key:

```sh
ssh root@<instance-public-ip>
```

## 1. First rebuild (flakes not enabled yet)

A stock AMI doesn't have flakes on. This repo's `modules/common/nix.nix` turns
them on permanently, but the *first* rebuild needs them enabled manually.

> NOTE: NixOS 26.05 ships the rewritten `nixos-rebuild` (Python), which does
> **not** accept the old `--extra-experimental-features` flag. Enable flakes via
> the `NIX_CONFIG` env var (works in any shell) or `--option`:

```sh
env NIX_CONFIG="experimental-features = nix-command flakes" \
  nixos-rebuild switch --flake "github:0x42697262/nixos-config#ct-home"
```

`#ct-home` selects the flake output. Building straight from `github:` needs no
clone and uses your last pushed commit. (Equivalent: append
`--option experimental-features "nix-command flakes"` instead of the env var.)

## 2. Later rebuilds

After the first switch, flakes are permanent, so drop the env var entirely:

```sh
nixos-rebuild switch --flake "github:0x42697262/nixos-config#ct-home"
```

## 3. Editing on the box (optional)

To iterate locally instead of pushing every change, clone it (the AMI may not
have `git`, so use `nix-shell`):

```sh
nix-shell -p git --run "git clone https://github.com/0x42697262/nixos-config /etc/nixos/nixos-config"

nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home
```

Pull newer nixpkgs later:

```sh
nix flake update /etc/nixos/nixos-config
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home
```

> **Flake + git gotcha:** a flake only sees files that git *tracks*. After
> creating a new file, `git add` it before rebuilding or the build won't see it
> (`error: path ... does not exist`). Building from `github:` sidesteps this.

## Notes

- `ct-home` is the **flake output name** (what `#ct-home` selects). The
  machine's hostname comes from EC2 metadata.
- EC2 plumbing (SSH, root-key import, disk growth, bootloader, `ec2.efi`) lives
  in the shared role `modules/roles/ec2.nix` — don't re-declare it here.
- This host gets git + neovim/vim + fish/tide from the role (the `shell` and
  `editors` profiles). The heavy `interactive` bundle stays off.
- `system.stateVersion` is pinned in `default.nix` — leave it alone on upgrades.
```
