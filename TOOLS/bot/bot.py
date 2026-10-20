#!/usr/bin/env python3
"""BlackMagic VPN Telegram bot — interactive menu, no external deps.

Long-polls the Telegram Bot API and drives the existing VPN management
scripts (TOOLS/bot/*.sh) so admins can manage the server from Telegram
instead of SSH-ing in and using the `menu` dashboard.
"""
import json
import os
import subprocess
import time
import urllib.request
import urllib.parse

BOT_TOKEN = os.environ.get("BOT_TOKEN") or open("/usr/bin/token").read().strip()
ADMIN_FILE = "/etc/xray/bot_admins"

# Per-chat state for "Custom" free-text input during the new-account flow.
# {chat_id_str: {"step": "days"|"quota"|"iplim", "proto": ..., "days": ..., "quota": ...}}
PENDING = {}
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
API = f"https://api.telegram.org/bot{BOT_TOKEN}"


def load_admins():
    try:
        with open(ADMIN_FILE) as f:
            return {line.strip() for line in f if line.strip()}
    except FileNotFoundError:
        return set()


def api_call(method, payload, timeout=20):
    url = f"{API}/{method}"
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read())


def send_message(chat_id, text, keyboard=None):
    payload = {"chat_id": chat_id, "text": text, "parse_mode": "HTML", "disable_web_page_preview": True}
    if keyboard:
        payload["reply_markup"] = {"inline_keyboard": keyboard}
    try:
        api_call("sendMessage", payload)
    except Exception as e:
        print(f"[send_message] error: {e}")


def answer_callback(callback_id, text=""):
    try:
        api_call("answerCallbackQuery", {"callback_query_id": callback_id, "text": text})
    except Exception as e:
        print(f"[answer_callback] error: {e}")


def run_script(name, *args, timeout=60):
    path = os.path.join(SCRIPT_DIR, name)
    try:
        result = subprocess.run(
            ["bash", path, *map(str, args)],
            capture_output=True, text=True, timeout=timeout,
        )
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


# ===================== Keyboards =====================

MAIN_MENU = [
    [{"text": "📊 Status Server", "callback_data": "status"},
     {"text": "👥 Akun Aktif", "callback_data": "accounts"}],
    [{"text": "🎁 Trial VMess", "callback_data": "trial_vmess"},
     {"text": "🎁 Trial VLess", "callback_data": "trial_vless"},
     {"text": "🎁 Trial Trojan", "callback_data": "trial_trojan"}],
    [{"text": "➕ Buat Akun Full", "callback_data": "newacc_proto"},
     {"text": "🔍 Cek Akun", "callback_data": "info_proto"}],
    [{"text": "🔁 Renew Akun", "callback_data": "renew_proto"},
     {"text": "🗑️ Hapus Akun", "callback_data": "del_proto"}],
    [{"text": "⚙️ Atur Limit Akun", "callback_data": "limit_proto"}],
    [{"text": "🔄 Restart Xray", "callback_data": "restart_xray"},
     {"text": "💾 Backup Sekarang", "callback_data": "backup_now"}],
    [{"text": "🛠️ Server Tools", "callback_data": "tools_menu"}],
]

TOOLS_MENU = [
    [{"text": "🔌 Cek Port", "callback_data": "check_port"},
     {"text": "🔁 Restart Semua Layanan", "callback_data": "restart_all"}],
    [{"text": "⚙️ Atur Backup", "callback_data": "backup_settings"},
     {"text": "♻️ Reboot VPS", "callback_data": "reboot_confirm"}],
    [{"text": "⬅️ Kembali", "callback_data": "back"}],
]

BACKUP_CRON_FILE = "/etc/cron.d/blackmagic-autobackup"
BACKUP_SCHEDULES = {
    "harian": "0 3 * * *",
    "mingguan": "0 3 * * 0",
}


def backup_settings_menu():
    return [
        [{"text": "📅 Harian (03:00)", "callback_data": "setbackup_harian"},
         {"text": "🗓️ Mingguan (Minggu 03:00)", "callback_data": "setbackup_mingguan"}],
        [{"text": "⛔ Matikan Auto-Backup", "callback_data": "setbackup_off"}],
        [{"text": "⬅️ Kembali", "callback_data": "tools_menu"}],
    ]


def current_backup_schedule():
    try:
        with open(BACKUP_CRON_FILE) as f:
            content = f.read()
    except FileNotFoundError:
        return "Nonaktif"
    for label, pattern in BACKUP_SCHEDULES.items():
        if pattern in content:
            return label.capitalize()
    return "Custom/Tidak dikenali"


def handle_backup_settings(chat_id):
    status = current_backup_schedule()
    send_message(
        chat_id,
        f"⚙️ <b>Atur Auto-Backup</b>\n━━━━━━━━━━━━━━━━━━\nStatus saat ini: <b>{status}</b>\n\nPilih jadwal baru:",
        backup_settings_menu(),
    )


def handle_set_backup(chat_id, mode):
    if mode == "off":
        try:
            os.remove(BACKUP_CRON_FILE)
        except FileNotFoundError:
            pass
        send_message(chat_id, "⛔ Auto-backup dimatikan.", BACK_BTN)
        return
    pattern = BACKUP_SCHEDULES[mode]
    content = (
        "SHELL=/bin/bash\n"
        "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n"
        f"{pattern} root /usr/bin/backup >/var/log/blackmagic-autobackup.log 2>&1\n"
    )
    with open(BACKUP_CRON_FILE, "w") as f:
        f.write(content)
    label = "Harian (jam 03:00)" if mode == "harian" else "Mingguan (Minggu jam 03:00)"
    send_message(chat_id, f"✅ Auto-backup diatur: <b>{label}</b>", BACK_BTN)

REBOOT_CONFIRM_MENU = [
    [{"text": "✅ Ya, Reboot Sekarang", "callback_data": "reboot_do"},
     {"text": "❌ Batal", "callback_data": "tools_menu"}],
]

PORT_INFO = (
    "🔌 <b>Port Server VPS Aktif</b>\n"
    "━━━━━━━━━━━━━━━━━━\n"
    "OpenVPN              : 2086\n"
    "SSH WS Stunnel (alt) : 701\n"
    "SSH SSL Websocket    : 443\n"
    "SSH Websocket        : 80, 443\n"
    "Stunnel              : 8443, 8880\n"
    "VMess WS TLS         : 443\n"
    "VLess WS TLS         : 443\n"
    "Trojan WS TLS        : 443\n"
    "Shadowsocks WS TLS   : 443\n"
    "VMess/VLess/Trojan/SS gRPC : 443\n"
    "VMess/VLess/Trojan/SS WS (non-TLS) : 80\n"
)


def duration_menu(proto):
    return [
        [{"text": "5 Menit", "callback_data": f"do_{proto}_5"},
         {"text": "60 Menit", "callback_data": f"do_{proto}_60"},
         {"text": "1440 Menit (1 Hari)", "callback_data": f"do_{proto}_1440"}],
        [{"text": "⬅️ Kembali", "callback_data": "back"}],
    ]


BACK_BTN = [[{"text": "⬅️ Kembali", "callback_data": "back"}]]

PROTO_LABEL = {"vmess": "VMess", "vless": "VLess", "trojan": "Trojan"}


def proto_picker(prefix):
    return [
        [{"text": "VMess", "callback_data": f"{prefix}_vmess"},
         {"text": "VLess", "callback_data": f"{prefix}_vless"},
         {"text": "Trojan", "callback_data": f"{prefix}_trojan"}],
        [{"text": "⬅️ Kembali", "callback_data": "back"}],
    ]


def days_picker(proto):
    return [
        [{"text": "7 Hari", "callback_data": f"nd_{proto}_7"},
         {"text": "30 Hari", "callback_data": f"nd_{proto}_30"},
         {"text": "90 Hari", "callback_data": f"nd_{proto}_90"}],
        [{"text": "✏️ Custom", "callback_data": f"nd_{proto}_custom"}],
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


def quota_picker(proto, days):
    return [
        [{"text": "Unlimited", "callback_data": f"nq_{proto}_{days}_0"},
         {"text": "50 GB", "callback_data": f"nq_{proto}_{days}_50"},
         {"text": "100 GB", "callback_data": f"nq_{proto}_{days}_100"}],
        [{"text": "✏️ Custom", "callback_data": f"nq_{proto}_{days}_custom"}],
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


def renew_days_picker(proto, user):
    return [
        [{"text": "7 Hari", "callback_data": f"rd_{proto}_{user}_7"},
         {"text": "30 Hari", "callback_data": f"rd_{proto}_{user}_30"},
         {"text": "90 Hari", "callback_data": f"rd_{proto}_{user}_90"}],
        [{"text": "⬅️ Kembali", "callback_data": f"renewlist_{proto}"}],
    ]


def limit_quota_picker(proto, user):
    return [
        [{"text": "Unlimited", "callback_data": f"lq_{proto}_{user}_0"},
         {"text": "50 GB", "callback_data": f"lq_{proto}_{user}_50"},
         {"text": "100 GB", "callback_data": f"lq_{proto}_{user}_100"}],
        [{"text": "⬅️ Kembali", "callback_data": f"limitlist_{proto}"}],
    ]


def limit_iplim_picker(proto, user, quota):
    return [
        [{"text": "1 IP", "callback_data": f"li_{proto}_{user}_{quota}_1"},
         {"text": "2 IP", "callback_data": f"li_{proto}_{user}_{quota}_2"},
         {"text": "Unlimited", "callback_data": f"li_{proto}_{user}_{quota}_0"}],
        [{"text": "⬅️ Kembali", "callback_data": f"limitlist_{proto}"}],
    ]


def iplim_picker(proto, days, quota):
    return [
        [{"text": "1 IP", "callback_data": f"ni_{proto}_{days}_{quota}_1"},
         {"text": "2 IP", "callback_data": f"ni_{proto}_{days}_{quota}_2"},
         {"text": "Unlimited", "callback_data": f"ni_{proto}_{days}_{quota}_0"}],
        [{"text": "✏️ Custom", "callback_data": f"ni_{proto}_{days}_{quota}_custom"}],
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


LIST_PAGE_SIZE = 10


def account_list_menu(chat_id, proto, action, page=0):
    out, rc = run_script("accounts.sh")
    section = {"vmess": "VMESS", "vless": "VLESS", "trojan": "TROJAN"}[proto]
    entries = []  # (user, exp, days_left)
    capture = False
    for line in out.splitlines():
        if line == f"---{section}---":
            capture = True
            continue
        if line.startswith("---"):
            capture = False
            continue
        if capture and "| exp:" in line:
            user, exp = line.split("| exp:")
            user, exp = user.strip(), exp.strip()
            entries.append((user, exp, days_left_of(exp)))

    if not entries:
        send_message(chat_id, f"Tidak ada akun {PROTO_LABEL[proto]} aktif.", BACK_BTN)
        return

    entries.sort(key=lambda e: e[2])
    total_pages = max(1, (len(entries) + LIST_PAGE_SIZE - 1) // LIST_PAGE_SIZE)
    page = max(0, min(page, total_pages - 1))
    chunk = entries[page * LIST_PAGE_SIZE:(page + 1) * LIST_PAGE_SIZE]

    verb = {"del": "Hapus", "info": "Cek", "renew": "Renew", "limit": "Atur Limit"}[action]
    rows = [[{"text": f"{u} (exp {e}, {tag_for(dl)})", "callback_data": f"{action}_{proto}_{u}"}] for u, e, dl in chunk]
    nav = []
    if page > 0:
        nav.append({"text": "⬅️ Prev", "callback_data": f"{action}page_{proto}_{page-1}"})
    if page < total_pages - 1:
        nav.append({"text": "Next ➡️", "callback_data": f"{action}page_{proto}_{page+1}"})
    if nav:
        rows.append(nav)
    rows.append([{"text": "⬅️ Kembali", "callback_data": "back"}])
    send_message(
        chat_id,
        f"{verb} Akun {PROTO_LABEL[proto]} — {len(entries)} total, halaman {page+1}/{total_pages}:",
        rows,
    )


# ===================== Handlers =====================

def handle_status(chat_id):
    out, rc = run_script("status.sh")
    d = parse_kv(out)
    text = (
        "📊 <b>Status Server</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"🌐 IP        : <code>{d.get('IP','?')}</code>\n"
        f"🏷️ Domain    : <code>{d.get('DOMAIN','?')}</code>\n"
        + (f"📍 Lokasi    : {d.get('CITY')} · {d.get('ISP')}\n" if d.get('CITY') or d.get('ISP') else "")
        + f"⏱️ Uptime    : {d.get('UPTIME','?')}\n"
        f"🧠 RAM       : {d.get('RAM','?')}\n"
        f"⚙️ CPU       : {d.get('CPU','?')}\n"
        f"💽 Disk      : {d.get('DISK','?')}\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"Xray      : {'🟢 ON' if d.get('XRAY')=='ON' else '🔴 OFF'}\n"
        f"Nginx     : {'🟢 ON' if d.get('NGINX')=='ON' else '🔴 OFF'}\n"
        f"Dropbear  : {'🟢 ON' if d.get('DROPBEAR')=='ON' else '🔴 OFF'}\n"
        f"Fail2ban  : {'🟢 ON' if d.get('FAIL2BAN')=='ON' else '🔴 OFF'}\n"
        f"SSH-WS    : {'🟢 ON' if d.get('WS_STUNNEL')=='ON' else '🔴 OFF'}\n"
    )
    send_message(chat_id, text, BACK_BTN)


PAGE_SIZE = 15


def days_left_of(exp):
    today = time.strftime("%Y-%m-%d")
    try:
        return int((time.mktime(time.strptime(exp, "%Y-%m-%d")) - time.mktime(time.strptime(today, "%Y-%m-%d"))) / 86400)
    except ValueError:
        return 99999


def tag_for(days_left):
    if days_left < 0:
        return "🔴 expired"
    if days_left <= 3:
        return f"🟡 {days_left}d left"
    return f"🟢 {days_left}d left"


def parse_accounts(out):
    """Returns list of (proto, user, exp, days_left), sorted soonest-expiring first."""
    section = None
    rows = []
    for line in out.splitlines():
        if line.startswith("---") and line.endswith("---"):
            section = line.strip("-")
            continue
        if section and "| exp:" in line:
            user, exp = line.split("| exp:")
            user, exp = user.strip(), exp.strip()
            rows.append((section, user, exp, days_left_of(exp)))
    rows.sort(key=lambda r: r[3])
    return rows


def handle_accounts(chat_id, page=0):
    out, rc = run_script("accounts.sh")
    d = parse_kv(out)
    rows = parse_accounts(out)
    total = len(rows)
    total_pages = max(1, (total + PAGE_SIZE - 1) // PAGE_SIZE)
    page = max(0, min(page, total_pages - 1))
    chunk = rows[page * PAGE_SIZE:(page + 1) * PAGE_SIZE]

    lines = ["👥 <b>Akun Aktif</b>", "━━━━━━━━━━━━━━━━━━"]
    lines.append(f"VMess  : {d.get('VMESS_COUNT','0')} akun")
    lines.append(f"VLess  : {d.get('VLESS_COUNT','0')} akun")
    lines.append(f"Trojan : {d.get('TROJAN_COUNT','0')} akun")
    lines.append(f"Total  : {total} akun — diurut dari yang paling cepat expired")
    lines.append(f"Halaman {page+1}/{total_pages}")
    lines.append("━━━━━━━━━━━━━━━━━━")
    for proto, user, exp, dl in chunk:
        lines.append(f"[{proto}] <code>{user}</code> — exp {exp} ({tag_for(dl)})")
    if not chunk:
        lines.append("Tidak ada akun aktif.")

    nav = []
    if page > 0:
        nav.append({"text": "⬅️ Prev", "callback_data": f"accpage_{page-1}"})
    if page < total_pages - 1:
        nav.append({"text": "Next ➡️", "callback_data": f"accpage_{page+1}"})
    keyboard = ([nav] if nav else []) + BACK_BTN
    send_message(chat_id, "\n".join(lines), keyboard)


def handle_trial(chat_id, proto, label):
    send_message(chat_id, f"🎁 <b>Trial {label}</b>\nPilih durasi trial:", duration_menu(proto))


def handle_create_trial(chat_id, proto, minutes, label, script):
    send_message(chat_id, f"⌛ Membuat trial {label} ({minutes} menit)...")
    out, rc = run_script(script, minutes, timeout=60)
    if rc != 0:
        send_message(chat_id, f"❌ Gagal membuat trial {label}.\n<code>{out}</code>", BACK_BTN)
        return
    d = parse_kv(out)
    text = (
        f"✅ <b>Trial {label} Berhasil Dibuat</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 User    : <code>{d.get('USER','?')}</code>\n"
        f"🔑 UUID    : <code>{d.get('UUID','?')}</code>\n"
        f"🌐 Domain  : <code>{d.get('DOMAIN','?')}</code>\n"
        f"⏳ Durasi  : {d.get('TIMER','?')} menit\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"🔗 <b>Link ({label})</b>\n\n{format_links(d)}"
    )
    send_message(chat_id, text, BACK_BTN)


def handle_restart(chat_id):
    send_message(chat_id, "🔄 Me-restart layanan Xray...")
    run_cmd(["systemctl", "restart", "xray"])
    out, rc = run_cmd(["systemctl", "is-active", "xray"])
    status = "✅ Xray berhasil di-restart." if rc == 0 else f"❌ Gagal restart Xray.\n<code>{out}</code>"
    send_message(chat_id, status, BACK_BTN)


def handle_backup(chat_id):
    send_message(chat_id, "💾 Memproses backup... (bisa beberapa menit, hasil & file akan dikirim otomatis)")
    out, rc = run_cmd(["bash", "/usr/bin/backup"], timeout=240)
    if rc == 0:
        send_message(chat_id, "✅ Backup selesai. Cek pesan/file yang baru masuk di atas.", BACK_BTN)
    else:
        send_message(chat_id, f"❌ Backup gagal.\n<code>{out[-500:]}</code>", BACK_BTN)


LINK_LABELS = [
    ("LINK_TLS", "TLS (WS)"), ("LINK_NTLS", "NTLS (WS)"), ("LINK_GRPC", "gRPC"),
    ("LINK_UPGRADE", "HTTPUpgrade"), ("LINK_XHTTP", "XHTTP"), ("LINK_WS", "WS"),
]


def format_links(d):
    lines = []
    for key, label in LINK_LABELS:
        if key in d:
            lines.append(f"<b>{label}</b>\n<code>{d[key]}</code>")
    return "\n\n".join(lines) if lines else "-"


def handle_create_account(chat_id, proto, days, quota, iplim):
    send_message(chat_id, f"⌛ Membuat akun {PROTO_LABEL[proto]} ({days} hari, quota {quota or 'unlimited'} GB, {iplim or 'unlimited'} IP)...")
    out, rc = run_script("account.sh", "create", proto, days, quota, iplim, timeout=60)
    if rc != 0:
        send_message(chat_id, f"❌ Gagal membuat akun.\n<code>{out}</code>", BACK_BTN)
        return
    d = parse_kv(out)
    text = (
        f"✅ <b>Akun {PROTO_LABEL[proto]} Dibuat</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 User   : <code>{d.get('USER','?')}</code>\n"
        f"🔑 Secret : <code>{d.get('SECRET','?')}</code>\n"
        f"🌐 Domain : <code>{d.get('DOMAIN','?')}</code>\n"
        f"⏳ Exp    : {d.get('EXP','?')}\n"
        f"📦 Quota  : {d.get('QUOTA','0')} GB ({'unlimited' if d.get('QUOTA')=='0' else 'limited'})\n"
        f"🔢 IP     : {d.get('IPLIM','0')} ({'unlimited' if d.get('IPLIM')=='0' else 'limited'})\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"🔗 <b>Link ({PROTO_LABEL[proto]})</b>\n\n{format_links(d)}"
    )
    send_message(chat_id, text, BACK_BTN)


def handle_delete_account(chat_id, proto, user):
    out, rc = run_script("account.sh", "delete", proto, user, timeout=30)
    if "DELETED" in out:
        send_message(chat_id, f"🗑️ Akun <code>{user}</code> ({PROTO_LABEL[proto]}) berhasil dihapus.", BACK_BTN)
    else:
        send_message(chat_id, f"❌ Gagal hapus akun.\n<code>{out}</code>", BACK_BTN)


def handle_info_account(chat_id, proto, user):
    out, rc = run_script("account.sh", "info", proto, user, timeout=30)
    if "NOTFOUND" in out:
        send_message(chat_id, "❌ Akun tidak ditemukan.", BACK_BTN)
        return
    d = parse_kv(out)
    text = (
        f"🔍 <b>Detail Akun {PROTO_LABEL[proto]}</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 User   : <code>{d.get('USER','?')}</code>\n"
        f"🔑 Secret : <code>{d.get('SECRET','?')}</code>\n"
        f"🌐 Domain : <code>{d.get('DOMAIN','?')}</code>\n"
        f"⏳ Exp    : {d.get('EXP','?')}\n"
        f"🔢 IP Limit : {d.get('IPLIM','?')}\n"
        + (f"📍 Last IP  : <code>{d.get('LAST_IP')}</code> ({d.get('CITY') or '?'} · {d.get('ISP') or '?'})\n" if d.get('LAST_IP') else "")
        + "━━━━━━━━━━━━━━━━━━\n"
        f"🔗 <b>Link ({PROTO_LABEL[proto]})</b>\n\n{format_links(d)}"
    )
    send_message(chat_id, text, BACK_BTN)


def handle_renew_account(chat_id, proto, user, extra_days):
    out, rc = run_script("account.sh", "renew", proto, user, extra_days, timeout=30)
    if "NOTFOUND" in out:
        send_message(chat_id, "❌ Akun tidak ditemukan.", BACK_BTN)
        return
    d = parse_kv(out)
    text = (
        f"✅ <b>Akun {PROTO_LABEL[proto]} Diperpanjang</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 User     : <code>{d.get('USER','?')}</code>\n"
        f"📅 Exp Lama : {d.get('OLD_EXP','?')}\n"
        f"📅 Exp Baru : {d.get('NEW_EXP','?')}\n"
        f"➕ Tambahan : {d.get('EXTRA_DAYS','?')} hari"
    )
    send_message(chat_id, text, BACK_BTN)


def handle_set_limit(chat_id, proto, user, quota, iplim):
    out, rc = run_script("account.sh", "limit", proto, user, quota, iplim, timeout=30)
    if "NOTFOUND" in out:
        send_message(chat_id, "❌ Akun tidak ditemukan.", BACK_BTN)
        return
    d = parse_kv(out)
    text = (
        f"✅ <b>Limit Akun Diperbarui</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"👤 User  : <code>{d.get('USER','?')}</code>\n"
        f"📦 Quota : {d.get('QUOTA','0')} GB ({'unlimited' if d.get('QUOTA')=='0' else 'limited'})\n"
        f"🔢 IP    : {d.get('IPLIM','0')} ({'unlimited' if d.get('IPLIM')=='0' else 'limited'})"
    )
    send_message(chat_id, text, BACK_BTN)


def handle_restart_all(chat_id):
    send_message(chat_id, "🔁 Me-restart semua layanan (xray, nginx, dropbear, ws-stunnel, fail2ban)...")
    out, rc = run_script("restart-all.sh", timeout=60)
    lines = ["🔁 <b>Hasil Restart Layanan</b>", "━━━━━━━━━━━━━━━━━━"]
    for line in out.splitlines():
        if "=" in line:
            svc, state = line.split("=", 1)
            lines.append(f"{svc:<12}: {'🟢 ON' if state == 'active' else '🔴 ' + state}")
    send_message(chat_id, "\n".join(lines), BACK_BTN)


def handle_reboot(chat_id):
    send_message(chat_id, "♻️ VPS akan reboot sekarang. Bot akan offline sebentar, tunggu ~1 menit lalu /start lagi.")
    subprocess.Popen(["shutdown", "-r", "+1"])


ONBOARDING_TEXT = (
    "🔮 <b>BLACK MAGIC VPN BOT</b>\n"
    "━━━━━━━━━━━━━━━━━━\n"
    "Halo! Bot ini bantu kelola VPS kamu tanpa perlu SSH.\n"
    "Semua interaksi pakai <b>tombol</b> — gak perlu ngetik command.\n\n"
    "📊 <b>Status Server</b> — cek RAM/CPU/uptime & status service\n"
    "👥 <b>Akun Aktif</b> — jumlah akun VMess/VLess/Trojan aktif\n"
    "🎁 <b>Trial</b> — bikin akun trial, pilih durasi lewat tombol\n"
    "🔁 <b>Renew Akun</b> — perpanjang expired akun yang udah ada\n"
    "💾 <b>Backup</b> — backup config + upload ke Drive + kirim ke sini\n"
    "🛠️ <b>Server Tools</b> — cek port, restart layanan, reboot VPS\n\n"
    "Ketik /start atau /menu kapan saja buat balik ke menu utama.\n"
    "━━━━━━━━━━━━━━━━━━"
)


def handle_custom_input(chat_id, text):
    state = PENDING.get(str(chat_id))
    if not state:
        return
    try:
        value = int(text)
        if value < 0:
            raise ValueError
    except ValueError:
        send_message(chat_id, "❌ Harus angka (≥0). Coba ketik lagi:")
        return

    step = state["step"]
    proto = state["proto"]
    if step == "days":
        if value < 1:
            send_message(chat_id, "❌ Jumlah hari minimal 1. Coba ketik lagi:")
            return
        PENDING.pop(str(chat_id), None)
        send_message(chat_id, f"📦 Quota akun {PROTO_LABEL[proto]}:", quota_picker(proto, value))
    elif step == "quota":
        PENDING.pop(str(chat_id), None)
        send_message(chat_id, f"🔢 Limit IP akun {PROTO_LABEL[proto]}:", iplim_picker(proto, state["days"], value))
    elif step == "iplim":
        PENDING.pop(str(chat_id), None)
        handle_create_account(chat_id, proto, state["days"], state["quota"], value)


def send_main_menu(chat_id, with_onboarding=False):
    text = ONBOARDING_TEXT if with_onboarding else "🔮 <b>BLACK MAGIC VPN BOT</b>\n━━━━━━━━━━━━━━━━━━\nPilih menu di bawah:"
    send_message(chat_id, text, MAIN_MENU)


# ===================== Main loop =====================

def main():
    print("BlackMagic bot starting (long polling)...")
    offset = 0
    while True:
        try:
            resp = api_call("getUpdates", {"offset": offset, "timeout": 30}, timeout=40)
        except Exception as e:
            print(f"[poll] error: {e}")
            time.sleep(5)
            continue

        for update in resp.get("result", []):
            offset = update["update_id"] + 1
            admins = load_admins()

            if "message" in update:
                msg = update["message"]
                chat_id = msg["chat"]["id"]
                text = msg.get("text", "")
                if str(chat_id) not in admins:
                    send_message(chat_id, "⛔ Akses ditolak. Bot ini khusus admin.")
                    continue
                if text == "/start":
                    PENDING.pop(str(chat_id), None)
                    send_main_menu(chat_id, with_onboarding=True)
                elif text == "/menu":
                    PENDING.pop(str(chat_id), None)
                    send_main_menu(chat_id)
                elif str(chat_id) in PENDING:
                    handle_custom_input(chat_id, text.strip())

            elif "callback_query" in update:
                cq = update["callback_query"]
                chat_id = cq["message"]["chat"]["id"]
                data = cq["data"]
                answer_callback(cq["id"])
                if str(chat_id) not in admins:
                    send_message(chat_id, "⛔ Akses ditolak. Bot ini khusus admin.")
                    continue

                if data == "back":
                    send_main_menu(chat_id)
                elif data == "status":
                    handle_status(chat_id)
                elif data == "accounts":
                    handle_accounts(chat_id)
                elif data.startswith("accpage_"):
                    handle_accounts(chat_id, page=int(data.split("_", 1)[1]))
                elif data == "trial_vmess":
                    handle_trial(chat_id, "vmess", "VMess")
                elif data == "trial_vless":
                    handle_trial(chat_id, "vless", "VLess")
                elif data == "trial_trojan":
                    handle_trial(chat_id, "trojan", "Trojan")
                elif data == "restart_xray":
                    handle_restart(chat_id)
                elif data == "backup_now":
                    handle_backup(chat_id)
                elif data == "tools_menu":
                    send_message(chat_id, "🛠️ <b>Server Tools</b>\n━━━━━━━━━━━━━━━━━━", TOOLS_MENU)
                elif data == "backup_settings":
                    handle_backup_settings(chat_id)
                elif data.startswith("setbackup_"):
                    handle_set_backup(chat_id, data.split("_", 1)[1])
                elif data == "check_port":
                    send_message(chat_id, PORT_INFO, BACK_BTN)
                elif data == "restart_all":
                    handle_restart_all(chat_id)
                elif data == "reboot_confirm":
                    send_message(chat_id, "♻️ Yakin mau reboot VPS sekarang? Semua koneksi aktif akan putus sebentar.", REBOOT_CONFIRM_MENU)
                elif data == "reboot_do":
                    handle_reboot(chat_id)
                elif data.startswith("do_vmess_"):
                    minutes = data.split("_")[-1]
                    handle_create_trial(chat_id, "vmess", minutes, "VMess", "trial-vmess.sh")
                elif data.startswith("do_vless_"):
                    minutes = data.split("_")[-1]
                    handle_create_trial(chat_id, "vless", minutes, "VLess", "trial-vless.sh")
                elif data.startswith("do_trojan_"):
                    minutes = data.split("_")[-1]
                    handle_create_trial(chat_id, "trojan", minutes, "Trojan", "trial-trojan.sh")
                elif data == "newacc_proto":
                    send_message(chat_id, "➕ <b>Buat Akun Full</b>\nPilih protokol:", proto_picker("newacc"))
                elif data.startswith("newacc_"):
                    proto = data.split("_", 1)[1]
                    send_message(chat_id, f"⏳ Durasi akun {PROTO_LABEL[proto]}:", days_picker(proto))
                elif data.startswith("nd_"):
                    _, proto, days = data.split("_")
                    if days == "custom":
                        PENDING[str(chat_id)] = {"step": "days", "proto": proto}
                        send_message(chat_id, "✏️ Ketik jumlah hari (angka), misal <code>45</code>:")
                    else:
                        send_message(chat_id, f"📦 Quota akun {PROTO_LABEL[proto]}:", quota_picker(proto, days))
                elif data.startswith("nq_"):
                    _, proto, days, quota = data.split("_")
                    if quota == "custom":
                        PENDING[str(chat_id)] = {"step": "quota", "proto": proto, "days": days}
                        send_message(chat_id, "✏️ Ketik quota dalam GB (angka, 0 = unlimited):")
                    else:
                        send_message(chat_id, f"🔢 Limit IP akun {PROTO_LABEL[proto]}:", iplim_picker(proto, days, quota))
                elif data.startswith("ni_"):
                    _, proto, days, quota, iplim = data.split("_")
                    if iplim == "custom":
                        PENDING[str(chat_id)] = {"step": "iplim", "proto": proto, "days": days, "quota": quota}
                        send_message(chat_id, "✏️ Ketik limit IP/device (angka, 0 = unlimited):")
                    else:
                        handle_create_account(chat_id, proto, days, quota, iplim)
                elif data == "del_proto":
                    send_message(chat_id, "🗑️ <b>Hapus Akun</b>\nPilih protokol:", proto_picker("dellist"))
                elif data.startswith("dellist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "del")
                elif data.startswith("delpage_"):
                    _, proto, page = data.split("_")
                    account_list_menu(chat_id, proto, "del", page=int(page))
                elif data.startswith("del_") and not data.startswith("del_proto"):
                    _, proto, user = data.split("_", 2)
                    handle_delete_account(chat_id, proto, user)
                elif data == "info_proto":
                    send_message(chat_id, "🔍 <b>Cek Akun</b>\nPilih protokol:", proto_picker("infolist"))
                elif data.startswith("infolist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "info")
                elif data.startswith("infopage_"):
                    _, proto, page = data.split("_")
                    account_list_menu(chat_id, proto, "info", page=int(page))
                elif data.startswith("info_") and not data.startswith("info_proto"):
                    _, proto, user = data.split("_", 2)
                    handle_info_account(chat_id, proto, user)
                elif data == "renew_proto":
                    send_message(chat_id, "🔁 <b>Renew Akun</b>\nPilih protokol:", proto_picker("renewlist"))
                elif data.startswith("renewlist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "renew")
                elif data.startswith("renewpage_"):
                    _, proto, page = data.split("_")
                    account_list_menu(chat_id, proto, "renew", page=int(page))
                elif data.startswith("renew_") and not data.startswith("renew_proto"):
                    _, proto, user = data.split("_", 2)
                    send_message(chat_id, f"⏳ Tambah berapa hari buat <code>{user}</code>?", renew_days_picker(proto, user))
                elif data.startswith("rd_"):
                    parts = data.split("_")
                    proto = parts[1]
                    extra_days = parts[-1]
                    user = "_".join(parts[2:-1])
                    handle_renew_account(chat_id, proto, user, extra_days)
                elif data == "limit_proto":
                    send_message(chat_id, "⚙️ <b>Atur Limit Akun</b>\nPilih protokol:", proto_picker("limitlist"))
                elif data.startswith("limitlist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "limit")
                elif data.startswith("limitpage_"):
                    _, proto, page = data.split("_")
                    account_list_menu(chat_id, proto, "limit", page=int(page))
                elif data.startswith("limit_") and not data.startswith("limit_proto"):
                    _, proto, user = data.split("_", 2)
                    send_message(chat_id, f"📦 Quota buat <code>{user}</code>?", limit_quota_picker(proto, user))
                elif data.startswith("lq_"):
                    parts = data.split("_")
                    proto = parts[1]
                    quota = parts[-1]
                    user = "_".join(parts[2:-1])
                    send_message(chat_id, f"🔢 Limit IP buat <code>{user}</code>?", limit_iplim_picker(proto, user, quota))
                elif data.startswith("li_"):
                    parts = data.split("_")
                    proto = parts[1]
                    iplim = parts[-1]
                    quota = parts[-2]
                    user = "_".join(parts[2:-2])
                    handle_set_limit(chat_id, proto, user, quota, iplim)


if __name__ == "__main__":
    main()
