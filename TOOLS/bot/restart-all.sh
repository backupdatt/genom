#!/bin/bash
# Restart all core VPN services and report status.
for svc in xray nginx dropbear ws-stunnel fail2ban; do
    systemctl restart "$svc" >/dev/null 2>&1
done
sleep 2
for svc in xray nginx dropbear ws-stunnel fail2ban; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    echo "${svc}=${state}"
done
