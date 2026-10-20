#!/usr/bin/env python3
"""BlackMagic VPN web control panel backend — stdlib only, no deps.

Mirrors the Telegram bot's capabilities (TOOLS/bot/bot.py) as a small
JSON API consumed by dashboard/index.html. Listens on 127.0.0.1 only;
nginx reverse-proxies /dashboard/api/ to this and enforces HTTP Basic
Auth before requests ever reach here (see /etc/nginx/conf.d/xray.conf),
so this process does its own auth-free routing.
"""
import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BACKUP_CRON_FILE = "/etc/cron.d/blackmagic-autobackup"
BACKUP_SCHEDULES = {"harian": "0 3 * * *", "mingguan": "0 3 * * 0"}


def run_script(name, *args, timeout=60):
    path = os.path.join(SCRIPT_DIR, name)
    try:
        result = subprocess.run(["bash", path, *map(str, args)], capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "Timeout.", 1


def run_cmd(args, timeout=120):
    try:
        result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "Timeout.", 1


def parse_kv(output):
    data = {}
    for line in output.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            data[k] = v
    return data


def days_left_of(exp):
    today = time.strftime("%Y-%m-%d")
    try:
        return int((time.mktime(time.strptime(exp, "%Y-%m-%d")) - time.mktime(time.strptime(today, "%Y-%m-%d"))) / 86400)
    except ValueError:
        return 99999


def parse_accounts(out):
    section = None
    rows = []
    for line in out.splitlines():
        if line.startswith("---") and line.endswith("---"):
            section = line.strip("-").lower()
            continue
        if section and "| exp:" in line:
            user, exp = line.split("| exp:")
            user, exp = user.strip(), exp.strip()
            rows.append({"proto": section, "user": user, "exp": exp, "days_left": days_left_of(exp)})
    rows.sort(key=lambda r: r["days_left"])
    return rows


def current_backup_schedule():
    try:
        with open(BACKUP_CRON_FILE) as f:
            content = f.read()
    except FileNotFoundError:
        return "off"
    for label, pattern in BACKUP_SCHEDULES.items():
        if pattern in content:
            return label
    return "custom"


# ===================== Route handlers =====================

def h_status(_req):
    out, _ = run_script("status.sh")
    return parse_kv(out)


def h_usage(_req):
    out, _ = run_script("usage.sh", "server", timeout=30)
    return parse_kv(out)


def h_accounts(_req):
    out, _ = run_script("accounts.sh")
    d = parse_kv(out)
    return {
        "counts": {"vmess": int(d.get("VMESS_COUNT", 0)), "vless": int(d.get("VLESS_COUNT", 0)), "trojan": int(d.get("TROJAN_COUNT", 0))},
        "accounts": parse_accounts(out),
    }


def h_account_create(req):
    b = req["body"]
    out, rc = run_script("account.sh", "create", b["proto"], b.get("days", 7), b.get("quota", 0), b.get("iplim", 0), b.get("name", ""))
    if "INVALID_NAME" in out:
        return {"ok": False, "error": "Nama cuma boleh huruf/angka/._- , tanpa spasi"}
    if "USER_EXISTS" in out:
        return {"ok": False, "error": "Nama sudah dipakai akun lain"}
    if rc != 0:
        return {"ok": False, "error": out}
    return {"ok": True, **parse_kv(out)}


def h_account_delete(req):
    b = req["body"]
    out, rc = run_script("account.sh", "delete", b["proto"], b["user"])
    if "DELETED" not in out:
        return {"ok": False, "error": out}
    return {"ok": True}


def h_account_renew(req):
    b = req["body"]
    out, rc = run_script("account.sh", "renew", b["proto"], b["user"], b.get("extra_days", 30))
    if "NOTFOUND" in out:
        return {"ok": False, "error": "not found"}
    return {"ok": True, **parse_kv(out)}


def h_account_limit(req):
    b = req["body"]
    out, rc = run_script("account.sh", "limit", b["proto"], b["user"], b.get("quota", 0), b.get("iplim", 0))
    if "NOTFOUND" in out:
        return {"ok": False, "error": "not found"}
    return {"ok": True, **parse_kv(out)}


def h_account_info(req):
    b = req["body"]
    out, rc = run_script("account.sh", "info", b["proto"], b["user"])
    if "NOTFOUND" in out:
        return {"ok": False, "error": "not found"}
    return {"ok": True, **parse_kv(out)}


TRIAL_SCRIPTS = {
    "vmess": "trial-vmess.sh",
    "vless": "trial-vless.sh",
    "trojan": "trial-trojan.sh",
}


def h_trial(req):
    b = req["body"]
    proto = b["proto"]
    script = TRIAL_SCRIPTS[proto]
    out, rc = run_script(script, b.get("minutes", 5), timeout=60)
    if rc != 0:
        return {"ok": False, "error": out}
    return {"ok": True, **parse_kv(out)}


def h_backup_now(_req):
    out, rc = run_cmd(["bash", "/usr/bin/backup"], timeout=240)
    return {"ok": rc == 0, "log": out[-500:]}


def h_backup_schedule_get(_req):
    return {"schedule": current_backup_schedule()}


def h_backup_schedule_set(req):
    mode = req["body"]["mode"]
    if mode == "off":
        try:
            os.remove(BACKUP_CRON_FILE)
        except FileNotFoundError:
            pass
        return {"ok": True, "schedule": "off"}
    pattern = BACKUP_SCHEDULES[mode]
    content = (
        "SHELL=/bin/bash\n"
        "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n"
        f"{pattern} root /usr/bin/backup >/var/log/blackmagic-autobackup.log 2>&1\n"
    )
    with open(BACKUP_CRON_FILE, "w") as f:
        f.write(content)
    return {"ok": True, "schedule": mode}


def h_restart_all(_req):
    out, _ = run_script("restart-all.sh", timeout=60)
    return {"ok": True, "services": parse_kv(out)}


def h_restart_xray(_req):
    run_cmd(["systemctl", "restart", "xray"])
    out, rc = run_cmd(["systemctl", "is-active", "xray"])
    return {"ok": rc == 0, "status": out}


def h_reboot(_req):
    subprocess.Popen(["shutdown", "-r", "+1"])
    return {"ok": True, "message": "Rebooting in 1 minute"}


def h_online(_req):
    out, rc = run_script("online.sh", timeout=30)
    try:
        return {"ok": True, "sessions": json.loads(out)}
    except json.JSONDecodeError:
        return {"ok": False, "error": out}


def h_logs_list(_req):
    out, _ = run_script("logs.sh", "list", timeout=15)
    items = []
    for line in out.splitlines():
        if "|" in line:
            name, size = line.split("|", 1)
            items.append({"name": name, "size": size})
    return {"logs": sorted(items, key=lambda i: i["name"])}


LOG_NAMES = {"autobackup", "expiry-warn", "expiry-enforce", "xray-access", "xray-error"}
JOURNAL_UNITS = {"bot", "webapi", "xray", "nginx"}


def h_logs_tail(req):
    name = req["body"].get("name", "")
    if name not in LOG_NAMES:
        return {"ok": False, "error": "unknown log"}
    out, rc = run_script("logs.sh", "tail", name, 150, timeout=15)
    return {"ok": True, "text": out}


def h_logs_journal(req):
    unit = req["body"].get("unit", "")
    if unit not in JOURNAL_UNITS:
        return {"ok": False, "error": "unknown unit"}
    out, rc = run_script("logs.sh", "journal", unit, 150, timeout=15)
    return {"ok": True, "text": out}


ROUTES = {
    ("GET", "/dashboard/api/status"): h_status,
    ("GET", "/dashboard/api/usage"): h_usage,
    ("GET", "/dashboard/api/accounts"): h_accounts,
    ("POST", "/dashboard/api/accounts/create"): h_account_create,
    ("POST", "/dashboard/api/accounts/delete"): h_account_delete,
    ("POST", "/dashboard/api/accounts/renew"): h_account_renew,
    ("POST", "/dashboard/api/accounts/limit"): h_account_limit,
    ("POST", "/dashboard/api/accounts/info"): h_account_info,
    ("POST", "/dashboard/api/trial"): h_trial,
    ("POST", "/dashboard/api/backup/now"): h_backup_now,
    ("GET", "/dashboard/api/backup/schedule"): h_backup_schedule_get,
    ("POST", "/dashboard/api/backup/schedule"): h_backup_schedule_set,
    ("POST", "/dashboard/api/restart-all"): h_restart_all,
    ("POST", "/dashboard/api/restart-xray"): h_restart_xray,
    ("POST", "/dashboard/api/reboot"): h_reboot,
    ("GET", "/dashboard/api/online"): h_online,
    ("GET", "/dashboard/api/logs"): h_logs_list,
    ("POST", "/dashboard/api/logs/tail"): h_logs_tail,
    ("POST", "/dashboard/api/logs/journal"): h_logs_journal,
}


class Handler(BaseHTTPRequestHandler):
    def _send_json(self, obj, status=200):
        body = json.dumps(obj).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _dispatch(self, method):
        path = self.path.split("?", 1)[0]
        handler = ROUTES.get((method, path))
        if not handler:
            self._send_json({"ok": False, "error": "not found"}, 404)
            return
        body = {}
        if method == "POST":
            length = int(self.headers.get("Content-Length", 0))
            raw = self.rfile.read(length) if length else b"{}"
            try:
                body = json.loads(raw)
            except json.JSONDecodeError:
                body = {}
        try:
            result = handler({"body": body})
            self._send_json(result)
        except Exception as e:
            self._send_json({"ok": False, "error": str(e)}, 500)

    def do_GET(self):
        self._dispatch("GET")

    def do_POST(self):
        self._dispatch("POST")

    def log_message(self, fmt, *args):
        print(f"[webapi] {self.address_string()} {fmt % args}")


def main():
    server = ThreadingHTTPServer(("127.0.0.1", 8099), Handler)
    print("BlackMagic webapi listening on 127.0.0.1:8099")
    server.serve_forever()


if __name__ == "__main__":
    main()
