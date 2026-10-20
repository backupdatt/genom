#!/bin/bash
# Non-interactive trial VLess creator for the Telegram bot.
# Usage: trial-vless.sh <minutes>
set -e
timer="${1:-5}"
[[ "$timer" =~ ^[0-9]+$ ]] || timer=5

domain=$(cat /etc/xray/domain)
user=Trial-$(</dev/urandom tr -dc A-Z0-9 | head -c4)
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "0 days" +"%Y-%m-%d")

mkdir -p /etc/vless
echo "1" > "/etc/vless/${user}IP"

sed -i '/#vless$/a\#vl '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vlessgrpc$/a\#vlg '"$user $exp"'\
},{"id": "'""$uuid""'","email": "'""$user""'"' /etc/xray/config.json

cat > "/etc/cron.d/trialvless${user}" <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/$timer * * * * root /usr/bin/trial vless $user $uuid $exp
EOF

systemctl restart xray >/dev/null 2>&1

echo "USER=${user}"
echo "UUID=${uuid}"
echo "EXP=${exp}"
echo "TIMER=${timer}"
echo "DOMAIN=${domain}"
echo "LINK_TLS=vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"
echo "LINK_NTLS=vless://${uuid}@${domain}:80?path=/vless&security=none&encryption=none&host=${domain}&type=ws#${user}"
echo "LINK_GRPC=vless://${uuid}@${domain}:443?mode=gun&security=tls&encryption=none&type=grpc&serviceName=vless-grpc&sni=${domain}#${user}"
echo "LINK_UPGRADE=vless://${uuid}@${domain}:443?path=/vless-up&security=tls&encryption=none&host=${domain}&type=httpupgrade&sni=${domain}&alpn=http/1.1#${user}"
echo "LINK_XHTTP=vless://${uuid}@${domain}:443?path=/vless-xhttp&security=tls&encryption=none&host=${domain}&type=xhttp&sni=${domain}&alpn=h2,http/1.1#${user}"
