#!/bin/bash
# Logs viewer for the dashboard/bot.
# Usage: logs.sh list
#        logs.sh tail <name> [lines]
declare -A LOGS=(
  [autobackup]="/var/log/blackmagic-autobackup.log"
  [expiry-warn]="/var/log/blackmagic-expiry.log"
  [expiry-enforce]="/var/log/blackmagic-expiry-enforce.log"
  [xray-access]="/var/log/xray/access.log"
  [xray-error]="/var/log/xray/error.log"
)

action="$1"

case "$action" in
  list)
    for name in "${!LOGS[@]}"; do
      path="${LOGS[$name]}"
      size=$(du -h "$path" 2>/dev/null | cut -f1)
      [ -z "$size" ] && size="0"
      echo "${name}|${size}"
    done
    ;;
  tail)
    name="$2"; lines="${3:-80}"
    path="${LOGS[$name]}"
    if [ -z "$path" ]; then
      echo "Unknown log: $name"
      exit 1
    fi
    if [ ! -f "$path" ]; then
      echo "(log belum ada / masih kosong)"
      exit 0
    fi
    tail -n "$lines" "$path" 2>/dev/null
    ;;
  journal)
    unit="$2"; lines="${3:-80}"
    case "$unit" in
      bot) svc="blackmagic-bot.service" ;;
      webapi) svc="blackmagic-webapi.service" ;;
      xray) svc="xray.service" ;;
      nginx) svc="nginx.service" ;;
      *) echo "Unknown unit: $unit"; exit 1 ;;
    esac
    journalctl -u "$svc" -n "$lines" --no-pager 2>/dev/null
    ;;
  *)
    echo "Unknown action: $action"
    exit 1
    ;;
esac
