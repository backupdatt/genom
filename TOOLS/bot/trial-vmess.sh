#!/bin/bash
# Non-interactive trial VMess creator for the Telegram bot.
# Usage: trial-vmess.sh <minutes>
set -e
timer="${1:-5}"
[[ "$timer" =~ ^[0-9]+$ ]] || timer=5

domain=$(cat /etc/xray/domain)
user=Trial-$(</dev/urandom tr -dc A-Z0-9 | head -c4)
uuid=$(cat /proc/sys/kernel/random/uuid)
exp=$(date -d "0 days" +"%Y-%m-%d")

mkdir -p /etc/vmess
echo "1" > "/etc/vmess/${user}IP"

sed -i '/#vmess$/a\#vm '"$user $exp"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json
sed -i '/#vmessgrpc$/a\#vmg '"$user $exp $uuid"'\
},{"id": "'""$uuid""'","alterId": '"0"',"email": "'""$user""'"' /etc/xray/config.json

cat > "/etc/cron.d/trialvmess${user}" <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
*/$timer * * * * root /usr/bin/trial vmess $user $uuid $exp
EOF

systemctl restart xray >/dev/null 2>&1

j_tls="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\"}"
j_ntls="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"none\"}"
j_grpc="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"grpc\",\"path\":\"vmess-grpc\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\"}"
j_up="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"httpupgrade\",\"path\":\"/vmess-up\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\",\"sni\":\"${domain}\",\"alpn\":\"http/1.1\"}"
j_xh="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"xhttp\",\"path\":\"/vmess-xhttp\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\",\"sni\":\"${domain}\",\"alpn\":\"h2,http/1.1\"}"

echo "USER=${user}"
echo "UUID=${uuid}"
echo "EXP=${exp}"
echo "TIMER=${timer}"
echo "DOMAIN=${domain}"
echo "LINK_TLS=vmess://$(echo -n "$j_tls" | base64 -w0)"
echo "LINK_NTLS=vmess://$(echo -n "$j_ntls" | base64 -w0)"
echo "LINK_GRPC=vmess://$(echo -n "$j_grpc" | base64 -w0)"
echo "LINK_UPGRADE=vmess://$(echo -n "$j_up" | base64 -w0)"
echo "LINK_XHTTP=vmess://$(echo -n "$j_xh" | base64 -w0)"
