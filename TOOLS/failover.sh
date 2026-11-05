#!/bin/bash
# Failover script: switch kino.praktikdeploy.my.id to Biznet or NevaCloud.
# Updates the Cloudflare A record, then starts the Telegram bot on the
# target server and stops it on the other one (avoids dual-polling).
#
# Usage:
#   CF_EMAIL=you@example.com CF_API_KEY=xxxx ./failover.sh biznet
#   CF_EMAIL=you@example.com CF_API_KEY=xxxx ./failover.sh nevacloud
#
# CF_EMAIL / CF_API_KEY are the Cloudflare account email + Global API Key.
# Never hardcode them in this file - pass as env vars each time, or export
# them in your own shell profile (not committed to this repo).
set -euo pipefail

ZONE_ID="f5ded499f6b5d686c5bcfd0e1eb78043"
RECORD_NAME="kino.praktikdeploy.my.id"
RECORD_ID="20e4275fdb8a7e84dc617ce84b7474fc"

BIZNET_IP="139.190.103.98"
BIZNET_SSH="akbar1@139.190.103.98"
NEVACLOUD_IP="116.212.75.254"
NEVACLOUD_SSH="root@116.212.75.254"

target="${1:-}"
if [ "$target" != "biznet" ] && [ "$target" != "nevacloud" ]; then
  echo "Usage: $0 biznet|nevacloud"
  exit 1
fi

if [ -z "${CF_EMAIL:-}" ] || [ -z "${CF_API_KEY:-}" ]; then
  echo "ERROR: set CF_EMAIL and CF_API_KEY env vars first." >&2
  exit 1
fi

if [ "$target" = "biznet" ]; then
  target_ip="$BIZNET_IP"
  start_ssh="$BIZNET_SSH"
  stop_ssh="$NEVACLOUD_SSH"
else
  target_ip="$NEVACLOUD_IP"
  start_ssh="$NEVACLOUD_SSH"
  stop_ssh="$BIZNET_SSH"
fi

echo "=== Switching DNS: ${RECORD_NAME} -> ${target_ip} (${target}) ==="
resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
  -H "X-Auth-Email: ${CF_EMAIL}" \
  -H "X-Auth-Key: ${CF_API_KEY}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${target_ip}\",\"ttl\":1,\"proxied\":false}")

success=$(echo "$resp" | grep -o '"success":[a-z]*' | head -1)
echo "Cloudflare response: ${success}"
if [[ "$success" != *true* ]]; then
  echo "DNS update FAILED, aborting bot swap. Raw response:" >&2
  echo "$resp" >&2
  exit 1
fi

echo "=== Starting bot on ${target} ==="
ssh -o ConnectTimeout=10 "$start_ssh" "sudo systemctl start blackmagic-bot 2>/dev/null || systemctl start blackmagic-bot" || echo "WARNING: could not start bot on ${target}"

echo "=== Stopping bot on the other server ==="
ssh -o ConnectTimeout=10 "$stop_ssh" "sudo systemctl stop blackmagic-bot 2>/dev/null || systemctl stop blackmagic-bot" || echo "WARNING: could not stop bot on the other server"

echo "=== Done. ${RECORD_NAME} now points to ${target} (${target_ip}). ==="
echo "Give DNS a minute to propagate, then verify with: nslookup ${RECORD_NAME} 1.1.1.1"
