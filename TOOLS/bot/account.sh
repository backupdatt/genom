#!/bin/bash
# Unified account manager for the Telegram bot: create / delete / info / renew.
# Usage:
#   account.sh create <vmess|vless|trojan> <days> <quota_gb> <ip_limit>
#   account.sh delete <vmess|vless|trojan> <user>
#   account.sh info   <vmess|vless|trojan> <user>
#   account.sh renew  <vmess|vless|trojan> <user> <extra_days>
set -e
CONFIG="/etc/xray/config.json"
action="$1"; proto="$2"
domain=$(cat /etc/xray/domain 2>/dev/null || echo "N/A")

case "$proto" in
  vmess)  mark1="#vm"; mark2="#vmg"; dir="/etc/vmess"; field="id" ;;
  vless)  mark1="#vl"; mark2="#vlg"; dir="/etc/vless"; field="id" ;;
  trojan) mark1="#tr"; mark2="#trg"; dir="/etc/trojan"; field="password" ;;
  *) echo "Unknown protocol: $proto"; exit 1 ;;
esac

case "$action" in

create)
  days="${3:-7}"; quota="${4:-0}"; iplim="${5:-0}"
  [[ "$days" =~ ^[0-9]+$ ]] || days=7
  [[ "$quota" =~ ^[0-9]+$ ]] || quota=0
  [[ "$iplim" =~ ^[0-9]+$ ]] || iplim=0

  user="${proto^}-$(</dev/urandom tr -dc A-Z0-9 | head -c5)"
  uuid=$(cat /proc/sys/kernel/random/uuid)
  exp=$(date -d "$days days" +"%Y-%m-%d")

  mkdir -p "$dir"
  realiplim=$iplim; [ "$realiplim" = "0" ] && realiplim=9999
  echo "$realiplim" > "${dir}/${user}IP"
  if [ "$quota" != "0" ]; then
    bytes=$(( quota * 1024 * 1024 * 1024 ))
    echo "$bytes" > "${dir}/${user}"
  fi

  if [ "$field" = "password" ]; then
    sed -i "/#trojanws\$/a\\${mark1} ${user} ${exp} ${uuid}\\
},{\"password\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG"
    sed -i "/#trojangrpc\$/a\\${mark2} ${user} ${exp}\\
},{\"password\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG"
  elif [ "$proto" = "vless" ]; then
    sed -i "/#vless\$/a\\${mark1} ${user} ${exp} ${uuid}\\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG"
    sed -i "/#vlessgrpc\$/a\\${mark2} ${user} ${exp}\\
},{\"id\": \"${uuid}\",\"email\": \"${user}\"" "$CONFIG"
  else
    sed -i "/#vmess\$/a\\${mark1} ${user} ${exp}\\
},{\"id\": \"${uuid}\",\"alterId\": 0,\"email\": \"${user}\"" "$CONFIG"
    sed -i "/#vmessgrpc\$/a\\${mark2} ${user} ${exp} ${uuid}\\
},{\"id\": \"${uuid}\",\"alterId\": 0,\"email\": \"${user}\"" "$CONFIG"
  fi

  systemctl restart xray >/dev/null 2>&1

  echo "USER=${user}"
  echo "SECRET=${uuid}"
  echo "EXP=${exp}"
  echo "QUOTA=${quota}"
  echo "IPLIM=${iplim}"
  echo "DOMAIN=${domain}"
  if [ "$proto" = "trojan" ]; then
    echo "LINK1=trojan://${uuid}@${domain}:443?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"
  elif [ "$proto" = "vless" ]; then
    echo "LINK1=vless://${uuid}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"
  else
    json="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\"}"
    echo "LINK1=vmess://$(echo -n "$json" | base64 -w0)"
  fi
  ;;

delete)
  user="$3"
  exp=$(grep -E "^${mark2} ${user} " "$CONFIG" | awk '{print $3}' | head -1)
  if [ -z "$exp" ]; then
    echo "NOTFOUND"
    exit 2
  fi
  sed -i "/^${mark1} ${user} ${exp}/,/^},{/d" "$CONFIG"
  sed -i "/^${mark2} ${user} ${exp}/,/^},{/d" "$CONFIG"
  rm -f "/home/vps/public_html/${proto}-${user}.txt" "${dir}/${user}IP" "${dir}/${user}" "${dir}/${user}login"
  rm -f "/etc/cron.d/trial${proto}${user}"
  systemctl restart xray >/dev/null 2>&1
  echo "DELETED=${user}"
  ;;

info)
  user="$3"
  line=$(grep -E "^${mark2} ${user} " "$CONFIG" | head -1)
  if [ -z "$line" ]; then
    echo "NOTFOUND"
    exit 2
  fi
  exp=$(echo "$line" | awk '{print $3}')
  secret=$(echo "$line" | awk '{print $4}')
  if [ "$proto" != "vmess" ]; then
    secret=$(grep -E "^${mark1} ${user} " "$CONFIG" | awk '{print $4}' | head -1)
  else
    secret=$(grep -A1 "^${mark2} ${user} " "$CONFIG" | grep -oE '"id": *"[^"]+"' | head -1 | grep -oE '[0-9a-f-]{36}')
  fi
  iplim=$(cat "${dir}/${user}IP" 2>/dev/null || echo "?")
  echo "USER=${user}"
  echo "SECRET=${secret}"
  echo "EXP=${exp}"
  echo "IPLIM=${iplim}"
  echo "DOMAIN=${domain}"
  if [ "$proto" = "trojan" ]; then
    echo "LINK1=trojan://${secret}@${domain}:443?path=%2Ftrojan-ws&security=tls&host=${domain}&type=ws&sni=${domain}#${user}"
  elif [ "$proto" = "vless" ]; then
    echo "LINK1=vless://${secret}@${domain}:443?path=/vless&security=tls&encryption=none&host=${domain}&type=ws&sni=${domain}#${user}"
  else
    json="{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${secret}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"${domain}\",\"tls\":\"tls\"}"
    echo "LINK1=vmess://$(echo -n "$json" | base64 -w0)"
  fi
  ;;

renew)
  user="$3"; extra_days="${4:-30}"
  [[ "$extra_days" =~ ^[0-9]+$ ]] || extra_days=30
  exp=$(grep -E "^${mark2} ${user} " "$CONFIG" | awk '{print $3}' | head -1)
  if [ -z "$exp" ]; then
    echo "NOTFOUND"
    exit 2
  fi
  now_epoch=$(date +%s)
  exp_epoch=$(date -d "$exp" +%s)
  days_left=$(( (exp_epoch - now_epoch) / 86400 ))
  [ "$days_left" -lt 0 ] && days_left=0
  new_days=$(( days_left + extra_days ))
  new_exp=$(date -d "$new_days days" +"%Y-%m-%d")

  sed -i "s/^${mark1} ${user} ${exp}/${mark1} ${user} ${new_exp}/g" "$CONFIG"
  sed -i "s/^${mark2} ${user} ${exp}/${mark2} ${user} ${new_exp}/g" "$CONFIG"
  systemctl restart xray >/dev/null 2>&1

  echo "USER=${user}"
  echo "OLD_EXP=${exp}"
  echo "NEW_EXP=${new_exp}"
  echo "EXTRA_DAYS=${extra_days}"
  ;;

*)
  echo "Unknown action: $action"
  exit 1
  ;;
esac
