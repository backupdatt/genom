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
     {"text": "🔍 Cek Akun", "callback_data": "info_proto"},
     {"text": "🗑️ Hapus Akun", "callback_data": "del_proto"}],
    [{"text": "🔄 Restart Xray", "callback_data": "restart_xray"},
     {"text": "💾 Backup Sekarang", "callback_data": "backup_now"}],
    [{"text": "🛠️ Server Tools", "callback_data": "tools_menu"}],
]

TOOLS_MENU = [
    [{"text": "🔌 Cek Port", "callback_data": "check_port"},
     {"text": "🔁 Restart Semua Layanan", "callback_data": "restart_all"}],
    [{"text": "♻️ Reboot VPS", "callback_data": "reboot_confirm"}],
    [{"text": "⬅️ Kembali", "callback_data": "back"}],
]

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
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


def quota_picker(proto, days):
    return [
        [{"text": "Unlimited", "callback_data": f"nq_{proto}_{days}_0"},
         {"text": "50 GB", "callback_data": f"nq_{proto}_{days}_50"},
         {"text": "100 GB", "callback_data": f"nq_{proto}_{days}_100"}],
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


def iplim_picker(proto, days, quota):
    return [
        [{"text": "1 IP", "callback_data": f"ni_{proto}_{days}_{quota}_1"},
         {"text": "2 IP", "callback_data": f"ni_{proto}_{days}_{quota}_2"},
         {"text": "Unlimited", "callback_data": f"ni_{proto}_{days}_{quota}_0"}],
        [{"text": "⬅️ Kembali", "callback_data": "newacc_proto"}],
    ]


def account_list_menu(chat_id, proto, action):
    out, rc = run_script("accounts.sh")
    section = {"vmess": "VMESS", "vless": "VLESS", "trojan": "TROJAN"}[proto]
    users = []
    capture = False
    for line in out.splitlines():
        if line == f"---{section}---":
            capture = True
            continue
        if line.startswith("---"):
            capture = False
            continue
        if capture and "|" in line:
            users.append(line.split("|")[0].strip())
    if not users:
        send_message(chat_id, f"Tidak ada akun {PROTO_LABEL[proto]} aktif.", BACK_BTN)
        return
    rows = [[{"text": u, "callback_data": f"{action}_{proto}_{u}"}] for u in users[:30]]
    rows.append([{"text": "⬅️ Kembali", "callback_data": "back"}])
    verb = {"del": "Hapus", "info": "Cek"}[action]
    send_message(chat_id, f"{verb} Akun {PROTO_LABEL[proto]} — pilih user:", rows)


# ===================== Handlers =====================

def handle_status(chat_id):
    out, rc = run_script("status.sh")
    d = parse_kv(out)
    text = (
        "📊 <b>Status Server</b>\n"
        "━━━━━━━━━━━━━━━━━━\n"
        f"🌐 IP        : <code>{d.get('IP','?')}</code>\n"
        f"🏷️ Domain    : <code>{d.get('DOMAIN','?')}</code>\n"
        f"⏱️ Uptime    : {d.get('UPTIME','?')}\n"
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


def handle_accounts(chat_id):
    out, rc = run_script("accounts.sh")
    d = parse_kv(out)
    today = time.strftime("%Y-%m-%d")
    lines = ["👥 <b>Akun Aktif</b>", "━━━━━━━━━━━━━━━━━━"]
    lines.append(f"VMess  : {d.get('VMESS_COUNT','0')} akun")
    lines.append(f"VLess  : {d.get('VLESS_COUNT','0')} akun")
    lines.append(f"Trojan : {d.get('TROJAN_COUNT','0')} akun")
    lines.append("━━━━━━━━━━━━━━━━━━")

    section = None
    emoji = {"VMESS": "📦", "VLESS": "📦", "TROJAN": "📦"}
    for line in out.splitlines():
        if line.startswith("---") and line.endswith("---"):
            section = line.strip("-")
            lines.append(f"\n{emoji.get(section,'📦')} <b>{section}</b>")
            continue
        if section and "| exp:" in line:
            user, exp = line.split("| exp:")
            user, exp = user.strip(), exp.strip()
            try:
                days_left = (time.mktime(time.strptime(exp, "%Y-%m-%d")) - time.mktime(time.strptime(today, "%Y-%m-%d"))) / 86400
                days_left = int(days_left)
                if days_left < 0:
                    tag = "🔴 expired"
                elif days_left <= 3:
                    tag = f"🟡 {days_left}d left"
                else:
                    tag = f"🟢 {days_left}d left"
            except ValueError:
                tag = ""
            lines.append(f"• <code>{user}</code> — exp {exp} ({tag})")

    send_message(chat_id, "\n".join(lines), BACK_BTN)


def handle_trial(chat_id, proto, label):
    send_message(chat_id, f"🎁 <b>Trial {label}</b>\nPilih durasi trial:", duration_menu(proto))


def handle_create_trial(chat_id, proto, minutes, label, script, user_field="LINK_TLS", alt_field="LINK_NTLS"):
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
        f"🔗 Link 1:\n<code>{d.get(user_field,'-')}</code>\n"
        f"🔗 Link 2:\n<code>{d.get(alt_field,'-')}</code>"
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
        f"🔗 Link:\n<code>{d.get('LINK1','-')}</code>"
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
        "━━━━━━━━━━━━━━━━━━\n"
        f"🔗 Link:\n<code>{d.get('LINK1','-')}</code>"
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
    "💾 <b>Backup</b> — backup config + upload ke Drive + kirim ke sini\n"
    "🛠️ <b>Server Tools</b> — cek port, restart layanan, reboot VPS\n\n"
    "Ketik /start atau /menu kapan saja buat balik ke menu utama.\n"
    "━━━━━━━━━━━━━━━━━━"
)


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
                    send_main_menu(chat_id, with_onboarding=True)
                elif text == "/menu":
                    send_main_menu(chat_id)

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
                    handle_create_trial(chat_id, "vmess", minutes, "VMess", "trial-vmess.sh", "LINK_TLS", "LINK_NTLS")
                elif data.startswith("do_vless_"):
                    minutes = data.split("_")[-1]
                    handle_create_trial(chat_id, "vless", minutes, "VLess", "trial-vless.sh", "LINK_TLS", "LINK_NTLS")
                elif data.startswith("do_trojan_"):
                    minutes = data.split("_")[-1]
                    handle_create_trial(chat_id, "trojan", minutes, "Trojan", "trial-trojan.sh", "LINK_WS", "LINK_GRPC")
                elif data == "newacc_proto":
                    send_message(chat_id, "➕ <b>Buat Akun Full</b>\nPilih protokol:", proto_picker("newacc"))
                elif data.startswith("newacc_"):
                    proto = data.split("_", 1)[1]
                    send_message(chat_id, f"⏳ Durasi akun {PROTO_LABEL[proto]}:", days_picker(proto))
                elif data.startswith("nd_"):
                    _, proto, days = data.split("_")
                    send_message(chat_id, f"📦 Quota akun {PROTO_LABEL[proto]}:", quota_picker(proto, days))
                elif data.startswith("nq_"):
                    _, proto, days, quota = data.split("_")
                    send_message(chat_id, f"🔢 Limit IP akun {PROTO_LABEL[proto]}:", iplim_picker(proto, days, quota))
                elif data.startswith("ni_"):
                    _, proto, days, quota, iplim = data.split("_")
                    handle_create_account(chat_id, proto, days, quota, iplim)
                elif data == "del_proto":
                    send_message(chat_id, "🗑️ <b>Hapus Akun</b>\nPilih protokol:", proto_picker("dellist"))
                elif data.startswith("dellist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "del")
                elif data.startswith("del_") and not data.startswith("del_proto"):
                    _, proto, user = data.split("_", 2)
                    handle_delete_account(chat_id, proto, user)
                elif data == "info_proto":
                    send_message(chat_id, "🔍 <b>Cek Akun</b>\nPilih protokol:", proto_picker("infolist"))
                elif data.startswith("infolist_"):
                    proto = data.split("_", 1)[1]
                    account_list_menu(chat_id, proto, "info")
                elif data.startswith("info_") and not data.startswith("info_proto"):
                    _, proto, user = data.split("_", 2)
                    handle_info_account(chat_id, proto, user)


if __name__ == "__main__":
    main()
