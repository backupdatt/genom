#!/bin/bash
# Server status snapshot for the Telegram bot.
IP=$(curl -sS --max-time 5 ipv4.icanhazip.com)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
UPTIME=$(uptime -p 2>/dev/null)
RAM=$(free -m | awk '/Mem:/ {printf "%d/%dMB (%.0f%%)", $3, $2, $3*100/$2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
DISK=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')

svc() {
    systemctl is-active --quiet "$1" && echo "ON" || echo "OFF"
}

echo "IP=${IP}"
echo "DOMAIN=${DOMAIN}"
echo "UPTIME=${UPTIME}"
echo "RAM=${RAM}"
echo "CPU=${CPU}%"
echo "DISK=${DISK}"
echo "XRAY=$(svc xray)"
echo "NGINX=$(svc nginx)"
echo "DROPBEAR=$(svc dropbear)"
echo "FAIL2BAN=$(svc fail2ban)"
echo "WS_STUNNEL=$(svc ws-stunnel)"
