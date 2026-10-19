#!/bin/bash
# Sends a Telegram alert. Called by systemd OnFailure= as blackmagic-alert@<unit>.service
unit="$1"
TOKEN=$(cat /usr/bin/token 2>/dev/null)
CHATID=$(cat /usr/bin/idchat 2>/dev/null)
[ -z "$TOKEN" ] && exit 0
[ -z "$CHATID" ] && exit 0

domain=$(cat /etc/xray/domain 2>/dev/null || echo "?")
time=$(date '+%Y-%m-%d %H:%M:%S')
state=$(systemctl is-active "$unit" 2>/dev/null)

TEXT="🚨 <b>Service Alert</b>
━━━━━━━━━━━━━━━━━━
Domain  : <code>${domain}</code>
Service : <code>${unit}</code>
Waktu   : ${time} WIB
Status  : ${state} (systemd sudah auto-restart)
━━━━━━━━━━━━━━━━━━"

curl -s --max-time 10 -d "chat_id=${CHATID}&disable_web_page_preview=1&text=${TEXT}&parse_mode=html" \
  "https://api.telegram.org/bot${TOKEN}/sendMessage" >/dev/null
