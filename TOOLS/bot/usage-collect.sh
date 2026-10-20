#!/bin/bash
# Accumulates per-account bandwidth (uplink+downlink) from Xray's own
# native stats API into a persistent running total. Run frequently via
# cron (every 5 min) — reads each counter with -reset so nothing is
# double-counted between runs.
#
# This is intentionally independent of xraylimit.sh's own usage
# tracking (/etc/limit/<proto>/<user>), which gates on a fragile
# log-timestamp heuristic that doesn't reliably fire on this server.
# Querying Xray's stats API directly works regardless of that.
CONFIG="/etc/xray/config.json"
TOTAL_DIR="/etc/xray-usage/total"
mkdir -p "$TOTAL_DIR/vmess" "$TOTAL_DIR/vless" "$TOTAL_DIR/trojan"

stat_value() {
  local user="$1" dir="$2"
  xray api stats --server=127.0.0.1:10085 -name "user>>>${user}>>>traffic>>>${dir}" -reset 2>/dev/null \
    | grep -oP '"value":\s*\K[0-9]+'
}

collect_proto() {
  local proto="$1" mark="$2"
  local users
  users=$(grep -E "^${mark} " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)
  for user in $users; do
    [ -z "$user" ] && continue
    up=$(stat_value "$user" "uplink"); up=${up:-0}
    down=$(stat_value "$user" "downlink"); down=${down:-0}
    delta=$(( up + down ))
    [ "$delta" -eq 0 ] && continue

    local f="${TOTAL_DIR}/${proto}/${user}"
    local prev
    prev=$(cat "$f" 2>/dev/null)
    [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
    echo $(( prev + delta )) > "$f"
  done
}

collect_proto vmess "#vmg"
collect_proto vless "#vlg"
collect_proto trojan "#trg"
