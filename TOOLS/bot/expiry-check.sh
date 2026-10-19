#!/bin/bash
# Daily check: notify via Telegram for any account expiring in exactly 3 days (H-3).
CONFIG="/etc/xray/config.json"
TOKEN=$(cat /usr/bin/token 2>/dev/null)
CHATID=$(cat /usr/bin/idchat 2>/dev/null)
[ -z "$TOKEN" ] && exit 0
[ -z "$CHATID" ] && exit 0

now_epoch=$(date +%s)
domain=$(cat /etc/xray/domain 2>/dev/null || echo "?")
report=""

check_marker() {
    local marker="$1" label="$2"
    while read -r user exp _; do
        [ -z "$user" ] && continue
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null) || continue
        days_left=$(( (exp_epoch - now_epoch) / 86400 ))
        if [ "$days_left" -eq 3 ]; then
            report="${report}• [${label}] <code>${user}</code> — exp ${exp} (3 hari lagi)\n"
        fi
    done < <(grep -E "^${marker} " "$CONFIG" 2>/dev/null | awk '{print $2, $3}')
}

check_marker "#vmg" "VMess"
check_marker "#vlg" "VLess"
check_marker "#trg" "Trojan"

# Also check the server's own VPN license (same file ssh-vpn.sh/m-vmess.sh reads).
if [ -f /etc/xray/license.conf ]; then
    source /etc/xray/license.conf
    lic=$(curl -s --connect-timeout 10 -H "Authorization: token $GH_TOKEN" \
        -H "Accept: application/vnd.github.v3.raw" \
        "https://api.github.com/repos/${GH_USER}/${GH_REPO}/contents/${GH_FILE}?ref=main" 2>/dev/null)
    ip_vps=$(curl -s --max-time 5 https://ipinfo.io/ip)
    lic_exp=$(echo "$lic" | awk -v ip="$ip_vps" '$4==ip {print $3}' | head -1)
    if [ -n "$lic_exp" ]; then
        lic_epoch=$(date -d "$lic_exp" +%s 2>/dev/null)
        if [ -n "$lic_epoch" ]; then
            lic_days=$(( (lic_epoch - now_epoch) / 86400 ))
            [ "$lic_days" -eq 3 ] && report="${report}• [LICENSE VPS] exp ${lic_exp} (3 hari lagi)\n"
        fi
    fi
fi

[ -z "$report" ] && exit 0

TEXT="⚠️ <b>Peringatan Expiry (H-3)</b>
━━━━━━━━━━━━━━━━━━
Domain: <code>${domain}</code>
━━━━━━━━━━━━━━━━━━
$(echo -e "$report")━━━━━━━━━━━━━━━━━━"

curl -s --max-time 10 -d "chat_id=${CHATID}&disable_web_page_preview=1&text=${TEXT}&parse_mode=html" \
  "https://api.telegram.org/bot${TOKEN}/sendMessage" >/dev/null
