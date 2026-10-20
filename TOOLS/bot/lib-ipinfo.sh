#!/bin/bash
# Shared ipinfo.io lookup helper, sourced by online.sh and account.sh (info).
# Caches per-IP results on disk for IPINFO_TTL seconds so looking up the same
# client IP repeatedly (every refresh of Online Now, every Info Akun check)
# doesn't hammer ipinfo.io's free-tier rate limit.
IPINFO_CACHE="/tmp/.blackmagic-ipinfo-cache"
IPINFO_TTL=3600

ipinfo_token() {
  grep -oP 'IPINFO_TOKEN="\K[^"]+' /usr/bin/menu 2>/dev/null
}

# Prints "CITY|ISP" for the given IP. Empty fields if the IP is private/local,
# no real token is configured, or the lookup fails.
ipinfo_lookup() {
  local ip="$1"
  case "$ip" in
    ""|127.*|10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*)
      echo "|"; return ;;
  esac

  local token; token=$(ipinfo_token)
  if [ -z "$token" ] || [ "$token" = "Abc12345" ]; then
    echo "|"; return
  fi

  touch "$IPINFO_CACHE" 2>/dev/null
  local now cached ts
  now=$(date +%s)
  cached=$(grep "^${ip}|" "$IPINFO_CACHE" 2>/dev/null | tail -1)
  if [ -n "$cached" ]; then
    ts=$(echo "$cached" | cut -d'|' -f2)
    if [ -n "$ts" ] && [ $(( now - ts )) -lt "$IPINFO_TTL" ]; then
      echo "$cached" | cut -d'|' -f3-
      return
    fi
  fi

  local resp city org
  resp=$(curl -sS --max-time 4 "https://ipinfo.io/${ip}?token=${token}" 2>/dev/null)
  city=$(echo "$resp" | grep -oP '"city":\s*"\K[^"]+')
  org=$(echo "$resp" | grep -oP '"org":\s*"\K[^"]+')

  { grep -v "^${ip}|" "$IPINFO_CACHE" 2>/dev/null; echo "${ip}|${now}|${city}|${org}"; } > "${IPINFO_CACHE}.tmp" \
    && mv "${IPINFO_CACHE}.tmp" "$IPINFO_CACHE"

  echo "${city}|${org}"
}
