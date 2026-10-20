#!/usr/bin/env python3
"""Real-time IP/device-limit watcher — streams xray's access.log (tail -f
style) instead of polling on a cron interval, so a multi-login is detected
within ~1 second instead of up to 2 minutes.

When an account exceeds its IP limit, the *newest* IP (the one that just
pushed it over) gets firewalled off on the public ports for BLOCK_SECS,
then auto-unblocked — the earlier device(s) are left alone. Blocking
uses a single ipset (hash:ip, native per-entry timeout) plus one static
iptables rule per port referencing it — O(1) add/remove, no per-block
rule churn, and expiry is handled by the kernel, not a Python timer.

Blocking is IP-based, and some mobile carriers share one public IP
across many unrelated customers (CGNAT). To limit collateral damage: if
the same IP is seen for more than one DISTINCT account at the same
time, it's treated as a shared/CGNAT IP and is never blocked — only
notified. Accepted trade-off per explicit user decision (2026-10-20).

Runs as a long-lived systemd service (blackmagic-iplimit-daemon.service).
"""
import os
import re
import subprocess
import threading
import time
import urllib.parse
import urllib.request

ACCESS_LOG = "/var/log/xray/access.log"
CONFIG = "/etc/xray/config.json"
TOKEN_FILE = "/usr/bin/token"
CHATID_FILE = "/usr/bin/idchat"
DOMAIN_FILE = "/etc/xray/domain"

WINDOW_SECS = 300    # an IP (or user-on-IP) counts as "in use" if seen in the last 5 minutes
COOLDOWN_SECS = 600  # don't re-notify the same user more than once per 10 min
REFRESH_SECS = 60    # how often to re-read config.json for new/removed accounts
BLOCK_SECS = 600     # how long a blocked IP stays firewalled (ipset native timeout)
BLOCK_PORTS = [80, 443, 8080]  # nginx's public listen ports (see xray.conf)
IPSET_NAME = "blackmagic_blocked"

PROTO_DIRS = {
    "vmess": ("#vmg", "/etc/vmess"),
    "vless": ("#vlg", "/etc/vless"),
    "trojan": ("#trg", "/etc/trojan"),
}

LINE_RE = re.compile(r"^\S+ \S+ from (\d+\.\d+\.\d+\.\d+):\d+ \S+ .*email: (\S+)$")

user_map = {}       # user -> (proto, limit)
ip_history = {}     # user -> {ip: last_seen_epoch}
ip_owners = {}      # ip -> {user: last_seen_epoch}  — for the CGNAT shared-IP check
last_notify = {}    # user -> epoch
known_blocked = {}  # ip -> block_started_at_epoch (soft local mirror of the ipset's own timeout)
lock = threading.Lock()


def setup_firewall():
    """Idempotent: creates the ipset and the iptables rules pointing at it
    if they don't already exist, and clears any stale entries from a
    previous run (we don't persist block state across restarts)."""
    subprocess.run(["modprobe", "ip_set"], capture_output=True)
    subprocess.run(["modprobe", "ip_set_hash_ip"], capture_output=True)
    subprocess.run(
        ["ipset", "create", IPSET_NAME, "hash:ip", "timeout", str(BLOCK_SECS), "-exist"],
        capture_output=True,
    )
    subprocess.run(["ipset", "flush", IPSET_NAME], capture_output=True)
    for port in BLOCK_PORTS:
        check = subprocess.run(
            ["iptables", "-C", "INPUT", "-p", "tcp", "--dport", str(port),
             "-m", "set", "--match-set", IPSET_NAME, "src", "-j", "DROP"],
            capture_output=True,
        )
        if check.returncode != 0:
            subprocess.run(
                ["iptables", "-I", "INPUT", "-p", "tcp", "--dport", str(port),
                 "-m", "set", "--match-set", IPSET_NAME, "src", "-j", "DROP"],
                capture_output=True,
            )
    print(f"[firewall] ipset '{IPSET_NAME}' ready, iptables rules in place for ports {BLOCK_PORTS}")


def is_shared_ip(ip, current_user):
    """CGNAT heuristic: if this IP is simultaneously active for a DIFFERENT
    account, it's very likely a shared carrier IP, not one person's extra
    device — never block those, notify only."""
    now = time.time()
    owners = ip_owners.get(ip, {})
    others = [u for u, t in owners.items() if u != current_user and now - t <= WINDOW_SECS]
    return len(others) > 0


def block_ip(ip):
    subprocess.run(["ipset", "add", IPSET_NAME, ip, "timeout", str(BLOCK_SECS), "-exist"], capture_output=True)
    with lock:
        known_blocked[ip] = time.time()
    print(f"[block] {ip} added to {IPSET_NAME} for {BLOCK_SECS}s")


def is_locally_blocked(ip):
    with lock:
        started = known_blocked.get(ip)
    return started is not None and time.time() - started < BLOCK_SECS


def refresh_user_map():
    global user_map
    try:
        with open(CONFIG) as f:
            content = f.read()
    except FileNotFoundError:
        return
    new_map = {}
    for proto, (mark, dir_) in PROTO_DIRS.items():
        for m in re.finditer(rf"^{re.escape(mark)} (\S+) ", content, re.MULTILINE):
            user = m.group(1)
            limit_file = os.path.join(dir_, user + "IP")
            try:
                limit = int(open(limit_file).read().strip())
            except Exception:
                limit = 9999
            new_map[user] = (proto, limit)
    with lock:
        user_map.clear()
        user_map.update(new_map)


def refresher_loop():
    while True:
        refresh_user_map()
        time.sleep(REFRESH_SECS)


def send_notify(user, proto, limit, ips, newest_ip, blocked):
    try:
        token = open(TOKEN_FILE).read().strip()
        chatid = open(CHATID_FILE).read().strip()
    except Exception:
        return
    if not token or not chatid:
        return
    try:
        domain = open(DOMAIN_FILE).read().strip()
    except Exception:
        domain = "?"

    if blocked:
        action_line = f"Diblokir: <code>{newest_ip}</code> (device terbaru, {BLOCK_SECS//60} menit)\n"
        footer = "Auto-unblock otomatis kalau udah gak over-limit lagi."
        title = "⛔ <b>Multi-Login — IP Diblokir (realtime)</b>"
    else:
        action_line = f"IP <code>{newest_ip}</code> kemungkinan shared/CGNAT (dipakai akun lain juga) — TIDAK diblokir.\n"
        footer = "(Notif saja, gak ada aksi — biar aman buat pelanggan lain di IP yang sama)"
        title = "⚠️ <b>Multi-Login Terdeteksi — IP Shared, Skip Block</b>"

    text = (
        f"{title}\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"Domain  : <code>{domain}</code>\n"
        f"Protokol: {proto}\n"
        f"User    : <code>{user}</code>\n"
        f"Limit   : {limit} device\n"
        f"Terpakai: {len(ips)} IP berbeda\n"
        f"IP list : <code>{' '.join(ips)}</code>\n"
        f"{action_line}"
        "━━━━━━━━━━━━━━━━━━\n"
        f"{footer}"
    )
    data = urllib.parse.urlencode({
        "chat_id": chatid, "text": text, "parse_mode": "html", "disable_web_page_preview": 1,
    }).encode()
    try:
        urllib.request.urlopen(f"https://api.telegram.org/bot{token}/sendMessage", data=data, timeout=10)
    except Exception as e:
        print(f"[notify] error: {e}")


def process_line(line):
    m = LINE_RE.match(line.strip())
    if not m:
        return
    ip, user = m.group(1), m.group(2)
    if ip == "127.0.0.1":
        return

    now = time.time()
    with lock:
        proto_limit = user_map.get(user)
    if not proto_limit:
        return
    proto, limit = proto_limit
    if limit >= 9999:
        return

    if is_locally_blocked(ip):
        return  # already firewalled, ignore stray/lingering packets

    hist = ip_history.setdefault(user, {})
    hist[ip] = now
    for k in [k for k, t in hist.items() if now - t > WINDOW_SECS]:
        del hist[k]

    owners = ip_owners.setdefault(ip, {})
    owners[user] = now
    for u in [u for u, t in owners.items() if now - t > WINDOW_SECS]:
        del owners[u]

    count = len(hist)
    if count > limit:
        shared = is_shared_ip(ip, user)
        if not shared:
            block_ip(ip)  # block the newest IP (this line's) — earlier ones stay up
        if now - last_notify.get(user, 0) >= COOLDOWN_SECS:
            last_notify[user] = now
            send_notify(user, proto, limit, list(hist.keys()), ip, blocked=not shared)


def tail_f(path):
    """Yields new lines as they're appended, surviving logrotate's
    copytruncate (file shrinks in place) and normal rename-based rotation
    (inode changes)."""
    f = None
    inode = None
    while True:
        if f is None:
            try:
                f = open(path, "r")
                f.seek(0, os.SEEK_END)
                inode = os.fstat(f.fileno()).st_ino
            except FileNotFoundError:
                time.sleep(2)
                continue
        line = f.readline()
        if line:
            yield line
            continue
        time.sleep(0.3)
        try:
            st = os.stat(path)
            if st.st_ino != inode or st.st_size < f.tell():
                f.close()
                f = None
        except FileNotFoundError:
            f.close()
            f = None


def main():
    print("BlackMagic IP-limit daemon starting (realtime log streaming)...")
    setup_firewall()
    refresh_user_map()
    threading.Thread(target=refresher_loop, daemon=True).start()
    for line in tail_f(ACCESS_LOG):
        try:
            process_line(line)
        except Exception as e:
            print(f"[process_line] error: {e}")


if __name__ == "__main__":
    main()
