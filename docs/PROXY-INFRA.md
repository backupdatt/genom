# Proxy front-door infra (103.127.139.62 → 139.190.103.98)

Infra-level setup living outside this repo's config-managed files (nginx
`stream`, WireGuard, netplan). Not deployed by any script here — this is a
record of what's live on the two servers, for anyone who needs to rebuild
or debug it.

## Purpose

`103.127.139.62` ("proxy") is a TLS-passthrough front door for the main VPN
server `139.190.103.98` ("main"). If the proxy IP gets blocked, only DNS
needs to change — `main` and its real IP stay hidden from clients.

## Topology

```
client --TLS(443)--> proxy (103.127.139.62)
                        | nginx stream, ssl_preread (SNI passthrough, no TLS termination)
                        v
                      main (139.190.103.98)  -- xray terminates TLS, serves vmess/vless/trojan

main's outbound internet traffic --WireGuard tunnel--> proxy --NAT masquerade--> internet
  (so egress IP for ALL accounts is 103.127.139.62, not main's own IP)
```

Both servers are Biznet Gio Neo Lite VPS in the same datacenter (Bogor),
connected over Biznet's private network in addition to their public IPs.

## DNS

`proxy-kino.praktikdeploy.my.id` → A record → `103.127.139.62`

This is the domain used in every `_VIA_PROXY` link variant that
`TOOLS/bot/account.sh` emits (see `/etc/xray/proxy_domain` below).

## Proxy server (103.127.139.62) — nginx stream passthrough

`/etc/nginx/nginx.conf`:
- Line 1: `load_module modules/ngx_stream_module.so;` (Ubuntu ships `stream`
  as a dynamic module; `/etc/nginx/nginx.conf` does not include
  `modules-enabled/*.conf`, so this has to be a literal line here).
- Appended at end of file:
  ```nginx
  stream {
      map $ssl_preread_server_name $backend {
          proxy-kino.praktikdeploy.my.id   kino_main;
          default                          kino_main;
      }

      upstream kino_main {
          server 139.190.103.98:443;
      }

      server {
          listen 443;
          listen [::]:443;
          proxy_pass $backend;
          ssl_preread on;
          proxy_protocol off;
          proxy_connect_timeout 5s;
          proxy_timeout 300s;
      }
  }
  ```
- Only port 443 is covered. Port 80 (`LINK_NTLS`) is NOT proxied — `ssl_preread`
  needs a TLS ClientHello to read the SNI from, so plain HTTP can't be routed
  this way without a separate fixed-target forwarder. Not implemented.
- Backup of the pre-edit file: `/etc/nginx/nginx.conf.bak-2026-10-21`.

This server previously ran its own VPN reseller business (menu-based xray
installer). That stack was fully uninstalled before turning it into a
proxy — see commit history / session notes for the teardown list. A backup
of that old business's data was kept at
`/root/backup-before-wipe-2026-10-21-1519.tar.gz` before deletion, in case
it's ever needed.

## WireGuard tunnel (egress masquerade)

Purpose: make `main`'s outbound internet traffic exit through `proxy`'s IP
instead of `main`'s own IP, so every account's egress IP matches the proxy
("full proxy" / double-hop, as opposed to just TLS passthrough on inbound).

- Subnet: `10.66.66.0/24` — proxy is `.1`, main is `.2`.
- Proxy is the WireGuard server (`ListenPort = 51820`), does NAT
  masquerade on `eth0` for `10.66.66.0/24`, has `net.ipv4.ip_forward=1`.
- Main is the WireGuard client. Its `wg0.conf` uses `Table = off` plus
  explicit `PostUp`/`PostDown` `ip rule`/`ip route` lines so **only**
  traffic sourced from `10.66.66.2` gets routed through the tunnel — the
  server's own default route (SSH, etc.) is untouched.
- **Endpoint uses the Biznet private IP, not the public IP**: main's
  `wg0.conf` has `Endpoint = 10.10.10.1:51820` (proxy's private IP), so the
  server-to-server tunnel traffic never touches the public internet or
  counts against public bandwidth. See "Private network" below.
- Both sides: `systemctl enable wg-quick@wg0` (persists across reboot).
- Config files: `/etc/wireguard/wg0.conf` on each server (contains the
  private key — never cat this over SSH into a chat/log; if it happens,
  rotate the key pair and re-exchange public keys).

### xray outbound binding

`/etc/xray/config.json` outbound (`"protocol": "freedom"`, the default
unnamed outbound) has `"sendThrough": "10.66.66.2"` added. This binds
**every** account's internet egress to the tunnel IP — there's no
per-account or per-port split between "proxy users" and "direct users",
because xray's inbound can't tell which path (via `proxy-kino` vs hitting
`main` directly) a connection arrived on; it's the same TCP destination
either way. Backup of the pre-edit config:
`/etc/xray/config.json.bak-2026-10-21`.

Decision made 2026-10-21: keep this mixed (don't try to split it). Splitting
would need a second port + duplicated xray inbound + a second client list
kept in sync by hand on every account create/delete — more maintenance
risk than the downside of everyone sharing one egress IP, especially now
that the tunnel runs over the free private network instead of public
bandwidth.

## Private network (Biznet Gio)

Both servers are Biznet Gio Neo Lite VPS in the same datacenter, with a
private NIC (`ens19`) that Biznet provisions but doesn't auto-configure.

- `ens19` static IPs: proxy `10.10.10.1/24`, main `10.10.10.2/24`.
- Configured via Netplan (`/etc/netplan/50-cloud-init.yaml` — DHCP doesn't
  work on this network, must be static). Backups:
  `/etc/netplan-backup-2026-10-21` on both servers.
- Measured latency over the private link: ~0.5ms (same datacenter, same
  as the public path — no latency win here, but no public bandwidth/quota
  usage, and the inter-server traffic never touches the public internet).
- WireGuard's `Endpoint` on main points at proxy's private IP
  (`10.10.10.1`), not its public IP, so the tunnel rides this link.

## Recommendation for future servers

Keep any new VPN/proxy server on the **same provider and same datacenter**
(Biznet Gio, Bogor) as the existing two. That's what makes the private
network (`ens19`) and the free/fast server-to-server tunnel possible in the
first place — cross-provider or cross-datacenter pairs can't use Biznet's
private network and would be stuck tunneling over public bandwidth, with
real latency/throughput cost instead of the ~0.5ms measured here.

## Operational notes

- `proxy_domain` toggle: `/etc/xray/proxy_domain` on `main` contains
  `proxy-kino.praktikdeploy.my.id`. If this file is empty/missing,
  `account.sh` stops emitting `_VIA_PROXY` links (see
  `TOOLS/bot/account.sh`, `TOOLS/bot/bot.py`, `TOOLS/bot/dashboard/index.html`
  in this repo for the application-level half of this feature).
- If `proxy-kino.praktikdeploy.my.id` ever needs to point at a different
  front-door IP (e.g. current one gets blocked), only the DNS A record
  needs to change — nothing on `main` needs touching.
- If WireGuard ever needs rebuilding from scratch, regenerate keys on
  both sides (`wg genkey | tee privatekey | wg pubkey > publickey`),
  exchange only the **public** keys, and never let a private key get
  printed to a terminal that's being logged/shared.
