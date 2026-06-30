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
instance into something managed by **this** flake, plus headscale.

## 0. Launch the instance

This host runs on an **aarch64 / Graviton** instance:

- AMI ID:   `ami-08dea6dfd1b09cc4a`
- AMI name: `nixos/26.05.590.ec942ba042da-aarch64-linux`

That's why the flake pins `system = "aarch64-linux"` for this host. Launch a
Graviton instance type (`t4g.*`, `c7g.*`). SSH in with your launch key:

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
  nixos-rebuild switch --flake "github:<owner>/nixos-config#ct-home"
```

After the first switch, flakes are permanent, so later rebuilds drop the env
var. To iterate on the box, clone it (the AMI may not have `git`):

```sh
nix-shell -p git --run "git clone https://github.com/<owner>/nixos-config /etc/nixos/nixos-config"
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home
```

> **Flake + git gotcha:** a flake only sees files that git *tracks*. After
> creating a new file, `git add` it before rebuilding.

## 2. Secrets: the domain (NOT committed)

The headscale domain is kept out of the repo. It lives in a file on the box and
is read at eval time via a local flake input (`inputs.ctSecrets`, declared in
`flake.nix`). Only the *path* is committed -- never the value.

Create it **before** rebuilding (eval fails if it's missing):

```sh
mkdir -p /etc/nixos/ct-secrets
printf '%s' '<your-domain>' > /etc/nixos/ct-secrets/domain   # e.g. headscale.example.com
```

> Don't run `nix flake update` / `nix flake check` on a machine that lacks
> `/etc/nixos/ct-secrets` (e.g. a WSL host) -- the `ctSecrets` input won't
> resolve there. Building other hosts is fine as long as `flake.lock` is present.

## 3. headscale + Let's Encrypt

`default.nix` runs headscale on `0.0.0.0:443` with headscale's **built-in**
Let's Encrypt (challenge type `TLS-ALPN-01`, so only port 443 is needed -- no
port 80). The firewall opens 443 and headscale gets `CAP_NET_BIND_SERVICE` to
bind the privileged port.

Prerequisites, all needed **before** the cert can issue:

- **Elastic IP** associated to the instance (so the public IP survives reboots).
- **Security group**: allow inbound **TCP 443** from `0.0.0.0/0`.
- **DNS A record**: `<your-domain>` -> the Elastic IP.

Then deploy and watch it come up:

```sh
nixos-rebuild switch --flake /etc/nixos/nixos-config#ct-home
journalctl -u headscale -f          # watch ACME issue the cert + headscale listen
curl -I https://<your-domain>       # from anywhere, once the cert is live
```

First-run, to join a client:

```sh
headscale users create me
headscale preauthkeys create --user me --reusable --expiration 24h
# client: tailscale up --login-server https://<your-domain> --authkey <key>
```

## Notes

- `ct-home` is the **flake output name** (what `#ct-home` selects). The
  machine's hostname comes from EC2 metadata.
- EC2 plumbing (SSH, root-key import, disk growth, bootloader, `ec2.efi`) lives
  in the shared role `modules/roles/ec2.nix`. headscale lives here in the host,
  not the role, so other EC2 hosts can front services with nginx instead.
- This host gets git + neovim/vim + fish/tide from the role (`shell`/`editors`
  profiles). The heavy `interactive` bundle stays off.
- MagicDNS is currently off (`dns.magic_dns = false`) to avoid needing a
  `base_domain`. Enable it later (the base domain should also come from a
  secret, not git).
- `system.stateVersion` is pinned in `default.nix` -- leave it alone on upgrades.
```
