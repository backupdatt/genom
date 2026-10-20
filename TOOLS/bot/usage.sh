#!/bin/bash
# Computes today/yesterday/this-month bandwidth usage from the daily
# snapshots usage-snapshot.sh writes, plus the live cumulative counter
# in /etc/xray-usage/total/<proto>/<user> (uplink+downlink, maintained
# by usage-collect.sh).
#
# Usage:
#   usage.sh account <vmess|vless|trojan> <user>   -> TODAY/YESTERDAY/MONTH bytes for one account
#   usage.sh server                                -> same, summed across every account
set -e
SNAP_DIR="/etc/xray-usage/snapshots"
action="$1"

today_file="${SNAP_DIR}/$(date +%F).txt"
yesterday_file="${SNAP_DIR}/$(date -d yesterday +%F).txt"

# The earliest snapshot dated this month — not literally the 1st,
# since this feature may have only started mid-month. Falls back to
# today's own snapshot so "this month" still works from day one
# instead of reading 0 until next month's 1st actually happens.
month_start_file=$(ls "${SNAP_DIR}/$(date +%Y-%m)"-*.txt 2>/dev/null | sort | head -1)
[ -z "$month_start_file" ] && month_start_file="$today_file"

# Prints the snapshotted byte count for proto+user from a given
# snapshot file, or 0 if that file/entry doesn't exist yet.
snap_value() {
  local file="$1" proto="$2" user="$3"
  [ -f "$file" ] || { echo 0; return; }
  awk -v p="$proto" -v u="$user" '$1==p && $2==u {print $3; found=1} END{if(!found) print 0}' "$file"
}

live_value() {
  local proto="$1" user="$2"
  cat "/etc/xray-usage/total/${proto}/${user}" 2>/dev/null | grep -qE '^[0-9]+$' \
    && cat "/etc/xray-usage/total/${proto}/${user}" || echo 0
}

clamp() { local v="$1"; [ "$v" -lt 0 ] 2>/dev/null && echo 0 || echo "$v"; }

# A delta against a baseline snapshot is only meaningful once that
# snapshot file actually exists on disk — without it, subtracting an
# implicit 0 would misreport the whole lifetime total as "yesterday"
# or "this month" the first day/month this feature runs.
delta_or_zero() {
  local file="$1" newer="$2" older="$3"
  [ -f "$file" ] && clamp $(( newer - older )) || echo 0
}

case "$action" in

account)
  proto="$2"; user="$3"
  live=$(live_value "$proto" "$user")
  mid_today=$(snap_value "$today_file" "$proto" "$user")
  mid_yesterday=$(snap_value "$yesterday_file" "$proto" "$user")
  mid_month=$(snap_value "$month_start_file" "$proto" "$user")

  echo "TODAY_BYTES=$(clamp $(( live - mid_today )))"
  echo "YESTERDAY_BYTES=$(delta_or_zero "$yesterday_file" "$mid_today" "$mid_yesterday")"
  echo "MONTH_BYTES=$(delta_or_zero "$month_start_file" "$live" "$mid_month")"
  ;;

server)
  total_today=0; total_yesterday=0; total_month=0

  for proto in vmess vless trojan; do
    dir="/etc/xray-usage/total/${proto}"
    [ -d "$dir" ] || continue
    for f in "$dir"/*; do
      [ -f "$f" ] || continue
      user=$(basename "$f")
      live=$(live_value "$proto" "$user")
      mid_today=$(snap_value "$today_file" "$proto" "$user")
      mid_yesterday=$(snap_value "$yesterday_file" "$proto" "$user")
      mid_month=$(snap_value "$month_start_file" "$proto" "$user")

      t=$(clamp $(( live - mid_today )))
      y=$(delta_or_zero "$yesterday_file" "$mid_today" "$mid_yesterday")
      m=$(delta_or_zero "$month_start_file" "$live" "$mid_month")

      total_today=$(( total_today + t ))
      total_yesterday=$(( total_yesterday + y ))
      total_month=$(( total_month + m ))
    done
  done

  echo "TODAY_BYTES=${total_today}"
  echo "YESTERDAY_BYTES=${total_yesterday}"
  echo "MONTH_BYTES=${total_month}"
  ;;

*)
  echo "Usage: usage.sh account <proto> <user> | usage.sh server"
  exit 1
  ;;
esac
