#!/bin/bash
# Non-interactive trial Trojan creator for the Telegram bot.
# Usage: trial-trojan.sh <minutes>
set -e
timer="${1:-5}"
[[ "$timer" =~ ^[0-9]+$ ]] || timer=5

domain=$(cat /etc/xray/domain)
user=Trial-$(</dev/urandom tr -dc A-Z0-9 | head -c4)
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "1 days" +"%Y-%m-%d")

mkdir -p /etc/trojan
echo "1" > "/etc/trojan/${user}IP"

sed -i '/#trojanws$/a\#tr '"$user $exp $uuid"'\
},{"password": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#trojangrpc$/a\#trg '"$user $exp"'\
},{"password": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json

cat > "/etc/cron.d/trialtrojan${user}" <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/$timer * * * * root /usr/bin/trial trojan $user $uuid $exp
EOF

systemctl restart xray >/dev/null 2>&1

link_ws="trojan://${uuid}@${domain}:443?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"
link_grpc="trojan://${uuid}@${domain}:443?mode=gun&security=tls&type=grpc&serviceName=trojan-grpc&sni=${domain}#${user}"

echo "USER=${user}"
echo "UUID=${uuid}"
echo "EXP=${exp}"
echo "TIMER=${timer}"
echo "DOMAIN=${domain}"
echo "LINK_WS=${link_ws}"
echo "LINK_GRPC=${link_grpc}"
