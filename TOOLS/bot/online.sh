#!/bin/bash
# Reports which accounts have been active recently, based on xray access.log.
# Note: xray sits behind a local reverse proxy, so source IPs in the log are
# all 127.0.0.1 — this can't count distinct client IPs reliably. What it CAN
# do reliably is tell you the last time each account's traffic was seen,
# which is used here as an "online now" signal (seen within the last 2 min).
ACCESS="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"
NOW=$(date +%s)

[ -f "$ACCESS" ] || { echo "[]"; exit 0; }

mapfile -t RECENT < <(tail -n 2000 "$ACCESS" 2>/dev/null)

get_proto_users() {
  grep -E "^$1 " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u
}

first=1
echo -n "["
for proto_mark in "#vmg:vmess" "#vlg:vless" "#trg:trojan"; do
  mark="${proto_mark%%:*}"; proto="${proto_mark##*:}"
  for user in $(get_proto_users "$mark"); do
    [ -z "$user" ] && continue
    last_line=$(printf '%s\n' "${RECENT[@]}" | grep -w "email: ${user}$" | tail -1)
    [ -z "$last_line" ] && continue
    ts=$(echo "$last_line" | awk '{print $1, $2}' | cut -d'.' -f1)
    ts_epoch=$(date -d "$ts" +%s 2>/dev/null)
    [ -z "$ts_epoch" ] && continue
    diff=$(( NOW - ts_epoch ))
    online="false"
    [ "$diff" -le 120 ] && online="true"
    hits=$(printf '%s\n' "${RECENT[@]}" | grep -c -w "email: ${user}$")
    [ "$first" -eq 0 ] && echo -n ","
    first=0
    echo -n "{\"proto\":\"${proto}\",\"user\":\"${user}\",\"online\":${online},\"last_seen_secs_ago\":${diff},\"recent_hits\":${hits}}"
  done
done
echo "]"
