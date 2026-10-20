#!/bin/bash
# Checks distinct client IPs per account against its configured IP limit,
# using real client IPs now that xray trusts the X-Forwarded-For header
# set by nginx (see README changelog). Notification-only — never disables
# or deletes the account; admin decides what to do with a multi-login.
ACCESS="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"
TOKEN=$(cat /usr/bin/token 2>/dev/null)
CHATID=$(cat /usr/bin/idchat 2>/dev/null)
COOLDOWN_SECS=600  # don't re-notify the same user more than once per 10 min
NOW=$(date +%s)

[ -f "$ACCESS" ] || exit 0
mapfile -t RECENT < <(tail -n 3000 "$ACCESS" 2>/dev/null)

notify() {
    local user="$1" proto="$2" limit="$3" count="$4" ips="$5"
    [ -z "$TOKEN" ] && return
    [ -z "$CHATID" ] && return
    local marker="/tmp/.iplimit_notified_${proto}_${user}"
    if [ -f "$marker" ]; then
        last=$(cat "$marker")
        [ $(( NOW - last )) -lt "$COOLDOWN_SECS" ] && return
    fi
    echo "$NOW" > "$marker"
    local domain
    domain=$(cat /etc/xray/domain 2>/dev/null || echo "?")
    local text="⚠️ <b>Multi-Login Terdeteksi</b>
━━━━━━━━━━━━━━━━━━
Domain  : <code>${domain}</code>
Protokol: ${proto}
User    : <code>${user}</code>
Limit   : ${limit} device
Terpakai: ${count} IP berbeda
IP list : <code>${ips}</code>
━━━━━━━━━━━━━━━━━━
(Notif saja, akun tidak diubah otomatis)"
    curl -s --max-time 10 -d "chat_id=${CHATID}&disable_web_page_preview=1&text=${text}&parse_mode=html" \
        "https://api.telegram.org/bot${TOKEN}/sendMessage" >/dev/null
}

check_proto() {
    local mark="$1" dir="$2" proto="$3"
    local users
    users=$(grep -E "^${mark} " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)
    for user in $users; do
        [ -z "$user" ] && continue
        local limit_file="${dir}/${user}IP"
        [ -f "$limit_file" ] || continue
        local limit
        limit=$(cat "$limit_file")
        [[ "$limit" =~ ^[0-9]+$ ]] || continue
        [ "$limit" -ge 9999 ] && continue  # unlimited

        local ips
        ips=$(printf '%s\n' "${RECENT[@]}" | grep -w "email: ${user}$" | awk '{print $4}' | cut -d: -f1 | sort -u)
        local count
        count=$(echo -n "$ips" | grep -c . || true)
        if [ "$count" -gt "$limit" ]; then
            notify "$user" "$proto" "$limit" "$count" "$(echo "$ips" | tr '\n' ' ')"
        fi
    done
}

check_proto "#vmg" "/etc/vmess" "vmess"
check_proto "#vlg" "/etc/vless" "vless"
check_proto "#trg" "/etc/trojan" "trojan"
