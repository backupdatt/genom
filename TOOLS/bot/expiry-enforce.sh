#!/bin/bash
# Fast-path expiry enforcement for VMess/VLess/Trojan, run every 5 minutes.
# Unlike /usr/bin/xp (runs once daily at 00:00, leaving up to ~24h of access
# past the expiry date), this closes the window to ~5 minutes. Only restarts
# Xray if an account was actually removed, to avoid disrupting active users
# on every run.
CONFIG="/etc/xray/config.json"
now_epoch=$(date +%s)
changed=0

remove_expired() {
    local mark1="$1" mark2="$2" dir="$3" proto="$4"
    local users
    users=$(grep -E "^${mark2} " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)
    for user in $users; do
        exp=$(grep -E "^${mark2} ${user} " "$CONFIG" | awk '{print $3}' | head -1)
        [ -z "$exp" ] && continue
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null) || continue
        if [ "$exp_epoch" -le "$now_epoch" ]; then
            sed -i "/^${mark1} ${user} ${exp}/,/^},{/d" "$CONFIG"
            sed -i "/^${mark2} ${user} ${exp}/,/^},{/d" "$CONFIG"
            rm -f "/home/vps/public_html/${proto}-${user}.txt" "${dir}/${user}IP" "${dir}/${user}" "${dir}/${user}login"
            rm -f "/etc/cron.d/trial${proto}${user}"
            changed=1
        fi
    done
}

remove_expired "#vm" "#vmg" "/etc/vmess" "vmess"
remove_expired "#vl" "#vlg" "/etc/vless" "vless"
remove_expired "#tr" "#trg" "/etc/trojan" "trojan"

if [ "$changed" -eq 1 ]; then
    systemctl restart xray >/dev/null 2>&1
    echo "$(date '+%Y-%m-%d %H:%M:%S') expired account(s) removed, xray restarted"
fi
