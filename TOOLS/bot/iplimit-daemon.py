#!/usr/bin/env python3
"""Real-time IP/device-limit watcher — streams xray's access.log (tail -f
style) instead of polling on a cron interval, so a multi-login is detected
within ~1 second instead of up to 2 minutes. Notification-only, same as
the cron-based iplimit-check.sh it replaces — never touches the account.

Runs as a long-lived systemd service (blackmagic-iplimit-daemon.service).
"""
import os
import re
import threading
import time
import urllib.parse
import urllib.request

ACCESS_LOG = "/var/log/xray/access.log"
CONFIG = "/etc/xray/config.json"
TOKEN_FILE = "/usr/bin/token"
CHATID_FILE = "/usr/bin/idchat"
DOMAIN_FILE = "/etc/xray/domain"

WINDOW_SECS = 300    # an IP counts as "in use" if seen in the last 5 minutes
COOLDOWN_SECS = 600  # don't re-notify the same user more than once per 10 min
REFRESH_SECS = 60    # how often to re-read config.json for new/removed accounts

PROTO_DIRS = {
    "vmess": ("#vmg", "/etc/vmess"),
    "vless": ("#vlg", "/etc/vless"),
    "trojan": ("#trg", "/etc/trojan"),
}

LINE_RE = re.compile(r"^\S+ \S+ from (\d+\.\d+\.\d+\.\d+):\d+ \S+ .*email: (\S+)$")

user_map = {}      # user -> (proto, limit)
ip_history = {}     # user -> {ip: last_seen_epoch}
last_notify = {}    # user -> epoch
lock = threading.Lock()


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


def send_notify(user, proto, limit, ips):
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

    text = (
        "⚠️ <b>Multi-Login Terdeteksi (realtime)</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"Domain  : <code>{domain}</code>\n"
        f"Protokol: {proto}\n"
        f"User    : <code>{user}</code>\n"
        f"Limit   : {limit} device\n"
        f"Terpakai: {len(ips)} IP berbeda\n"
        f"IP list : <code>{' '.join(ips)}</code>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        "(Notif saja, akun tidak diubah otomatis)"
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

    hist = ip_history.setdefault(user, {})
    hist[ip] = now
    for k in [k for k, t in hist.items() if now - t > WINDOW_SECS]:
        del hist[k]

    count = len(hist)
    if count > limit:
        if now - last_notify.get(user, 0) >= COOLDOWN_SECS:
            last_notify[user] = now
            send_notify(user, proto, limit, list(hist.keys()))


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
    refresh_user_map()
    threading.Thread(target=refresher_loop, daemon=True).start()
    for line in tail_f(ACCESS_LOG):
        try:
            process_line(line)
        except Exception as e:
            print(f"[process_line] error: {e}")


if __name__ == "__main__":
    main()
