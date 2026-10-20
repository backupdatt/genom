#!/bin/bash
# Generates a static JSON snapshot for the monitoring dashboard.
# Run via cron every minute; the dashboard page polls this file directly.
OUT_DIR="/var/www/blackmagic-dashboard"
OUT_FILE="${OUT_DIR}/data.json"
mkdir -p "$OUT_DIR"

IP=$(curl -sS --max-time 5 ipv4.icanhazip.com)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")
UPTIME=$(uptime -p 2>/dev/null)
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
DISK=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')

svc() { systemctl is-active --quiet "$1" && echo "true" || echo "false"; }

CONFIG="/etc/xray/config.json"
VMESS_COUNT=$(grep -c -E "^#vmg " "$CONFIG" 2>/dev/null); VMESS_COUNT=${VMESS_COUNT:-0}
VLESS_COUNT=$(grep -c -E "^#vlg " "$CONFIG" 2>/dev/null); VLESS_COUNT=${VLESS_COUNT:-0}
TROJAN_COUNT=$(grep -c -E "^#trg " "$CONFIG" 2>/dev/null); TROJAN_COUNT=${TROJAN_COUNT:-0}

cat > "$OUT_FILE" <<EOF
{
  "generated_at": "$(date '+%Y-%m-%d %H:%M:%S')",
  "ip": "${IP}",
  "domain": "${DOMAIN}",
  "uptime": "${UPTIME}",
  "ram_used_mb": ${RAM_USED:-0},
  "ram_total_mb": ${RAM_TOTAL:-0},
  "cpu_percent": "${CPU}",
  "disk": "${DISK}",
  "services": {
    "xray": $(svc xray),
    "nginx": $(svc nginx),
    "dropbear": $(svc dropbear),
    "fail2ban": $(svc fail2ban),
    "ws_stunnel": $(svc ws-stunnel),
    "blackmagic_bot": $(svc blackmagic-bot)
  },
  "accounts": {
    "vmess": ${VMESS_COUNT},
    "vless": ${VLESS_COUNT},
    "trojan": ${TROJAN_COUNT}
  }
}
EOF
