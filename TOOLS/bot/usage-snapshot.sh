#!/bin/bash
# Daily snapshot of each account's cumulative usage counter
# (/etc/xray-usage/total/<proto>/<user>, maintained by
# usage-collect.sh — uplink+downlink bytes since account creation).
# Lets usage.sh compute today/yesterday/this-month deltas.
# Run via cron once a day, right after midnight.
OUT_DIR="/etc/xray-usage/snapshots"
mkdir -p "$OUT_DIR"
DATE=$(date +%F)

snapshot_proto() {
  local proto="$1" dir="$2"
  [ -d "$dir" ] || return
  for f in "$dir"/*; do
    [ -f "$f" ] || continue
    local user
    user=$(basename "$f")
    local bytes
    bytes=$(cat "$f" 2>/dev/null)
    [[ "$bytes" =~ ^[0-9]+$ ]] || continue
    echo "${proto} ${user} ${bytes}"
  done
}

{
  snapshot_proto vmess /etc/xray-usage/total/vmess
  snapshot_proto vless /etc/xray-usage/total/vless
  snapshot_proto trojan /etc/xray-usage/total/trojan
} > "${OUT_DIR}/${DATE}.txt"

# Keep 40 days — enough for "yesterday" and "this month" with margin.
find "$OUT_DIR" -name "*.txt" -mtime +40 -delete 2>/dev/null
