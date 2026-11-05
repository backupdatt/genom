#!/bin/bash
# Server status snapshot for the Telegram bot and web panel.
# The dashboard polls this every 5s — IP and geolocation never change for
# a VPS between polls, so they're cached with a TTL instead of hitting
# icanhazip.com + ipinfo.io on every single call (that was slow enough,
# and frequent enough, to stack up outbound connections under polling).
CACHE="/tmp/.blackmagic-status-netinfo.cache"
CACHE_TTL=600

if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -lt "$CACHE_TTL" ]; then
    source "$CACHE"
else
    IP=$(curl -sS --max-time 5 ipv4.icanhazip.com)
    IPINFO_TOKEN=$(grep -oP 'IPINFO_TOKEN="\K[^"]+' /usr/bin/menu 2>/dev/null)
    if [ -n "$IPINFO_TOKEN" ] && [ "$IPINFO_TOKEN" != "Abc12345" ]; then
        IPINFO=$(curl -sS --max-time 5 "https://ipinfo.io/${IP}?token=${IPINFO_TOKEN}")
        CITY=$(echo "$IPINFO" | grep -oP '"city":\s*"\K[^"]+')
        ORG=$(echo "$IPINFO" | grep -oP '"org":\s*"\K[^"]+')
    else
        CITY=""
        ORG=""
    fi
    { echo "IP='${IP}'"; echo "CITY='${CITY}'"; echo "ORG='${ORG}'"; } > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"
fi

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
echo "CITY=${CITY}"
echo "ISP=${ORG}"
echo "UPTIME=${UPTIME}"
echo "RAM=${RAM}"
echo "CPU=${CPU}%"
echo "DISK=${DISK}"
echo "XRAY=$(svc xray)"
echo "NGINX=$(svc nginx)"
echo "DROPBEAR=$(svc dropbear)"
echo "FAIL2BAN=$(svc fail2ban)"
echo "WS_STUNNEL=$(svc ws-stunnel)"
