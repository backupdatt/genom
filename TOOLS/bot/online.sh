#!/bin/bash
# Reports which accounts have been active recently, based on xray access.log,
# including distinct real client IPs (xray trusts nginx's X-Forwarded-For —
# see README changelog). "Online" = traffic seen within the last 2 minutes.
# Client addresses in the log are IPv4 "1.2.3.4:port" or bracketed IPv6
# "[2001:db8::1]:port" — extract_ip() below handles both.
#
# This scan (23 users x up to 2000 log lines, several passes each) can take
# 20-30s on a loaded server, but the dashboard polls this script every 5s —
# without a lock, each poll pile up its own full scan on top of the last,
# eating CPU faster than any of them finish. LOCK/CACHE below: if another
# scan is already running, serve its last finished result instead of
# starting a redundant one.
LOCK="/tmp/.blackmagic-online.lock"
CACHE="/tmp/.blackmagic-online.cache"
exec 9>"$LOCK"
if ! flock -n 9; then
  cat "$CACHE" 2>/dev/null || echo "[]"
  exit 0
fi

ACCESS="/var/log/xray/access.log"
CONFIG="/etc/xray/config.json"
NOW=$(date +%s)
source "$(dirname "$0")/lib-ipinfo.sh"

[ -f "$ACCESS" ] || { echo "[]"; exit 0; }

mapfile -t RECENT < <(tail -n 2000 "$ACCESS" 2>/dev/null)

get_proto_users() {
  grep -E "^$1 " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u
}

# Pulls the client address out of a "from ... accepted ..." log line and
# strips it down to a bare IP (no port, no brackets), or empty if it's
# loopback/private/unparseable.
extract_ip() {
  local raw ip
  raw=$(grep -oP '(?<=from )(\[[0-9a-fA-F:]+\]|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)(?=:)' <<< "$1" | head -1)
  ip="${raw#[}"; ip="${ip%]}"
  case "$ip" in
    ""|127.*|10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*|::1|fe80:*|fc00:*|fd00:*) echo "" ;;
    *) echo "$ip" ;;
  esac
}

json_escape() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' <<< "$1"
}

{
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
    ip_count=$(printf '%s\n' "${RECENT[@]}" | grep -w "email: ${user}$" | while read -r l; do extract_ip "$l"; done \
        | grep -v '^$' | sort -u | grep -c . || true)
    last_ip=$(extract_ip "$last_line")
    IFS='|' read -r city isp <<< "$(ipinfo_lookup "$last_ip")"
    city=$(json_escape "$city"); isp=$(json_escape "$isp")
    [ "$first" -eq 0 ] && echo -n ","
    first=0
    echo -n "{\"proto\":\"${proto}\",\"user\":\"${user}\",\"online\":${online},\"last_seen_secs_ago\":${diff},\"recent_hits\":${hits},\"ip_count\":${ip_count},\"last_ip\":\"${last_ip}\",\"city\":\"${city}\",\"isp\":\"${isp}\"}"
  done
done
echo "]"
} > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE" && cat "$CACHE"
