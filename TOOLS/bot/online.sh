#!/bin/bash
# Reports which accounts have been active recently, based on xray access.log,
# including distinct real client IPs (xray trusts nginx's X-Forwarded-For —
# see README changelog). "Online" = traffic seen within the last 2 minutes.
ACCESS="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"
NOW=$(date +%s)
source "$(dirname "$0")/lib-ipinfo.sh"

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
    ip_count=$(printf '%s\n' "${RECENT[@]}" | grep -w "email: ${user}$" | awk '{print $4}' | cut -d: -f1 \
        | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | grep -v '^127\.0\.0\.1$' | sort -u | grep -c . || true)
    last_ip=$(echo "$last_line" | awk '{print $4}' | cut -d: -f1)
    IFS='|' read -r city isp <<< "$(ipinfo_lookup "$last_ip")"
    [ "$first" -eq 0 ] && echo -n ","
    first=0
    echo -n "{\"proto\":\"${proto}\",\"user\":\"${user}\",\"online\":${online},\"last_seen_secs_ago\":${diff},\"recent_hits\":${hits},\"ip_count\":${ip_count},\"last_ip\":\"${last_ip}\",\"city\":\"${city}\",\"isp\":\"${isp}\"}"
  done
done
echo "]"
