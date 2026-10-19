#!/bin/bash
# Active account counts/list per protocol, read from xray config.json markers.
CONFIG="/etc/xray/config.json"

count() { grep -c -E "^$1 " "$CONFIG" 2>/dev/null || echo 0; }

echo "VMESS_COUNT=$(count '#vmg')"
echo "VLESS_COUNT=$(count '#vlg')"
echo "TROJAN_COUNT=$(count '#trg')"

echo "---VMESS---"
grep -E "^#vmg " "$CONFIG" 2>/dev/null | awk '{print $2" | exp:"$3}'
echo "---VLESS---"
grep -E "^#vlg " "$CONFIG" 2>/dev/null | awk '{print $2" | exp:"$3}'
echo "---TROJAN---"
grep -E "^#trg " "$CONFIG" 2>/dev/null | awk '{print $2" | exp:"$3}'
