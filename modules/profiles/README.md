# Profiles

Feature-flag profiles. Each file declares a `myProfiles.<name>` option and
implements it behind a `lib.mkIf`. `default.nix` is imported by every host (via
`mkHost`), so the flags are always available; a host enables only the
capabilities it needs. All flags default to off.

## GitLab

`myProfiles.gitlab` runs a self-hosted GitLab server. It is a standalone
capability flag — no role enables it implicitly, so GitLab is present only on
hosts that explicitly set `myProfiles.gitlab.enable = true`.

The profile configures the GitLab service itself. TLS termination and the
reverse proxy are left to the host, since they depend on what else the host
runs; see [Reverse proxy and TLS](#reverse-proxy-and-tls).

### Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `enable` | bool | `false` | Whether to run GitLab on the host. |
| `host` | string | — | Public FQDN GitLab is served on. |
| `port` | port | `443` | External port GitLab is reached on. Used to build repo/clone URLs and emails, so it must match the port the reverse proxy serves on. |
| `secretsDir` | string | — | Directory holding GitLab's secret files (see [Secrets](#secrets)). A plain runtime path (`/etc/nixos/secrets/gitlab`) or one derived from a secrets flake input. |

Minimal configuration:

```nix
myProfiles.gitlab = {
  enable = true;
  host = "gitlab.example.com";
  secretsDir = "/etc/nixos/secrets/gitlab";
};
```

### Secrets

GitLab requires a number of secrets that must not be committed to git. The
directory referenced by `secretsDir` lives on the host (not in this repository)
and must contain the following files:

| File | Contents |
| --- | --- |
| `root_password` | Initial `root` account password |
| `db_password` | PostgreSQL password for the GitLab role |
| `secret` | Rails `secret_key_base` |
| `otp` | OTP secret |
| `db` | DB encryption secret |
| `jws` | JWS signing key |
| `active_record_primary_key` | Active Record encryption primary key |
| `active_record_deterministic_key` | Active Record deterministic key |
| `active_record_salt` | Active Record key-derivation salt |

Random values can be generated with `openssl rand -hex 32`, for example:

```sh
openssl rand -hex 32 > secret
```

### Reverse proxy and TLS

The profile runs GitLab only. The reverse proxy and TLS termination are supplied
by the host. The examples below use Caddy, which provisions and renews Let's
Encrypt certificates automatically.

All configurations assume the following are in place first:

- An **A/AAAA** record for the GitLab FQDN pointing at the host's public IP, set
  up *before* the first rebuild so the ACME challenge can succeed.
- The relevant ports reachable from the internet (cloud security group / router
  in addition to the NixOS firewall).

#### Dedicated host (port 443)

When no other service binds 80 or 443, GitLab is served on the standard HTTPS
port. `port` defaults to 443 and can be omitted.

```nix
{ ... }: {
  myProfiles.gitlab = {
    enable = true;
    host = "git.domain.com";
    secretsDir = "/etc/nixos/secrets/gitlab";
  };

  services.caddy = {
    enable = true;
    virtualHosts."git.domain.com".extraConfig = ''
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    '';
  };

  # Caddy runs as its own user and must be able to reach the workhorse socket,
  # which is owned by the gitlab group.
  users.users.caddy.extraGroups = [ "gitlab" ];

  # 80 for the ACME HTTP-01 challenge and redirect; 443 for HTTPS.
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

#### Shared host, non-standard port

When another service already binds 443, Caddy cannot bind it as well and the
rebuild fails with a bind conflict. In that case GitLab is served on a different
port, with `myProfiles.gitlab.port` set to match so that GitLab builds its URLs
with that port.

```nix
{ ... }: {
  myProfiles.gitlab = {
    enable = true;
    host = "git.domain.com";
    port = 6969;                         # any free port; must match Caddy below
    secretsDir = "/etc/nixos/secrets/gitlab";
  };

  services.caddy = {
    enable = true;
    # The explicit :6969 in the site address makes Caddy serve HTTPS there.
    virtualHosts."https://git.domain.com:6969".extraConfig = ''
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    '';
  };

  users.users.caddy.extraGroups = [ "gitlab" ];

  # 80 is still required for the ACME HTTP-01 challenge (it always runs on 80,
  # regardless of the port the site is served on); 6969 is the HTTPS port.
  networking.firewall.allowedTCPPorts = [ 80 6969 ];
}
```

GitLab is then reached at `https://git.domain.com:6969`, and clone URLs are
generated with the same port.

**Obtaining a certificate when 80 is also taken.** The HTTP-01 challenge requires
port 80 to be free for Caddy. When both 80 and 443 are occupied, no HTTP-based
challenge can complete, and Caddy must use the **DNS-01** challenge instead (a
`tls { dns <provider> ... }` block), which validates through a DNS TXT record and
requires no inbound port.

#### Multiple services on one port (443)

A non-standard port avoids the conflict but leaves an explicit port in every URL.
To keep port-less URLs while running GitLab alongside other HTTPS services on
443, requests are routed by **hostname** on a single listener — standard
name-based virtual hosting. This works at one of two layers.

**Layer 7 (recommended).** A single Caddy instance owns 443, terminates TLS, and
routes by `Host` header. Each service is given its own subdomain and one
`virtualHosts` entry:

```nix
{ ... }: {
  myProfiles.gitlab = {
    enable = true;
    host = "git.domain.com";           # port defaults to 443 — no port in URLs
    secretsDir = "/etc/nixos/secrets/gitlab";
  };

  services.caddy = {
    enable = true;
    virtualHosts."git.domain.com".extraConfig = ''
      reverse_proxy unix//run/gitlab/gitlab-workhorse.socket
    '';
    # ...one vhost per additional service, each on its own subdomain.
  };

  users.users.caddy.extraGroups = [ "gitlab" ];
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

Each subdomain requires its own DNS record, and Caddy obtains a separate Let's
Encrypt certificate per host. This approach requires every service to let Caddy
terminate its TLS. A service that terminates its own TLS on 443 must first be
placed behind Caddy — see
[Fronting a self-TLS service with Caddy](#fronting-a-self-tls-service-with-caddy).

**Layer 4.** When a service must keep its own TLS, a TCP/SNI router on 443 reads
the unencrypted SNI hostname from the TLS handshake and forwards the raw
connection without decrypting it — one hostname to the service's own TLS
listener, another to a Caddy instance that terminates TLS for GitLab. It can be
implemented with nginx `stream` + `ssl_preread`, HAProxy, or the `caddy-l4`
plugin. This involves more moving parts than Layer 7, which is preferred unless a
backend requires ownership of its TLS.

## Fronting a self-TLS service with Caddy

Some services can terminate their own TLS and bind 443 directly; headscale, for
example, can obtain a Let's Encrypt certificate itself via TLS-ALPN-01 on 443.
This is self-contained until another service also needs 443: only one process
can hold a port, so a self-TLS service prevents Caddy from serving anything
alongside it. This is the conflict encountered when adding [GitLab](#gitlab) to
such a host (see [Multiple services on one port](#multiple-services-on-one-port-443)).

The resolution is to move TLS termination to Caddy: the service listens on plain
HTTP on localhost, and Caddy owns 443 and reverse-proxies to it. Clients continue
to use HTTPS; only the owner of the certificate changes. Using headscale as an
example:

```nix
# Before — headscale terminates its own TLS and owns 443.
services.headscale = {
  enable = true;
  address = "0.0.0.0";
  port = 443;
  settings = {
    server_url = "https://headscale.domain.com";
    tls_letsencrypt_hostname = "headscale.domain.com";
    tls_letsencrypt_challenge_type = "TLS-ALPN-01";
  };
};
```

```nix
# After — headscale listens locally over plain HTTP; Caddy fronts it on 443.
services.headscale = {
  enable = true;
  address = "127.0.0.1";
  port = 8080;
  # server_url stays https:// — it is the public URL Caddy serves.
  settings.server_url = "https://headscale.domain.com";
  # The tls_letsencrypt_* settings are dropped; Caddy owns the certificate now.
};

services.caddy = {
  enable = true;
  virtualHosts."headscale.domain.com".extraConfig = ''
    reverse_proxy 127.0.0.1:8080
  '';
};

networking.firewall.allowedTCPPorts = [ 80 443 ];
```

Notes:

- Caddy's `reverse_proxy` handles the long-lived streaming connections headscale
  maintains, so no additional timeout or WebSocket configuration is required for
  a basic setup.
- Once Caddy owns 443, further subdomains can be served by adding more
  `virtualHosts` entries, which is what allows GitLab to run on the same port.
