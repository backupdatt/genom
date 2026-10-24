#!/bin/bash
# Fast-path expiry enforcement for VMess/VLess/Trojan, run every 5 minutes.
# Unlike /usr/bin/xp (runs once daily at 00:00, leaving up to ~24h of access
# past the expiry date), this closes the window to ~5 minutes. Only restarts
# Xray if an account was actually removed, to avoid disrupting active users
# on every run.
#
# Before deleting, each account's uuid/password is archived to ARCHIVE_LOG
# so account.sh restore can bring it back within the grace period — without
# this, an expired account's secret is gone for good the moment this script
# removes it (see the "alya" incident: a later full-config restore wiped an
# account created after the backup it restored from, with no way back).
CONFIG="/etc/xray/config.json"
ARCHIVE_LOG="/etc/xray-archive/archive.log"
GRACE_DAYS=7
now_epoch=$(date +%s)
changed=0

remove_expired() {
    local mark1="$1" mark2="$2" dir="$3" proto="$4"
    local users
    users=$(grep -E "^${mark2} " "$CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)
    for user in $users; do
        exp=$(grep -E "^${mark2} ${user} " "$CONFIG" | awk '{print $3}' | head -1)
        [ -z "$exp" ] && continue
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null) || continue
        if [ "$exp_epoch" -le "$now_epoch" ]; then
            local secret
            secret=$(grep -E "^${mark1} ${user} ${exp} " "$CONFIG" | awk '{print $4}' | head -1)
            [ -z "$secret" ] && secret=$(grep -E "^${mark2} ${user} ${exp} " "$CONFIG" | awk '{print $4}' | head -1)
            if [ -n "$secret" ]; then
                mkdir -p "$(dirname "$ARCHIVE_LOG")"
                echo "${proto} ${user} ${secret} ${exp} $(date '+%Y-%m-%dT%H:%M:%S')" >> "$ARCHIVE_LOG"
            fi
            sed -i "/^${mark1} ${user} ${exp}/,/^},{/d" "$CONFIG"
            sed -i "/^${mark2} ${user} ${exp}/,/^},{/d" "$CONFIG"
            rm -f "/home/vps/public_html/${proto}-${user}.txt" "${dir}/${user}IP" "${dir}/${user}" "${dir}/${user}login"
            rm -f "/etc/cron.d/trial${proto}${user}"
            changed=1
        fi
    done
}

remove_expired "#vm" "#vmg" "/etc/vmess" "vmess"
remove_expired "#vl" "#vlg" "/etc/vless" "vless"
remove_expired "#tr" "#trg" "/etc/trojan" "trojan"

if [ "$changed" -eq 1 ]; then
    systemctl restart xray >/dev/null 2>&1
    echo "$(date '+%Y-%m-%d %H:%M:%S') expired account(s) removed, xray restarted"
fi

# Drop archive entries past the grace period — they're gone for good after
# this, same as before the archive existed. Runs every pass regardless of
# $changed since it's independent of this run's own deletions.
if [ -s "$ARCHIVE_LOG" ]; then
    tmp_archive=$(mktemp)
    while read -r aproto auser asecret aexp adeleted; do
        [ -z "$auser" ] && continue
        del_epoch=$(date -d "$adeleted" +%s 2>/dev/null) || continue
        age_days=$(( (now_epoch - del_epoch) / 86400 ))
        [ "$age_days" -lt "$GRACE_DAYS" ] && echo "${aproto} ${auser} ${asecret} ${aexp} ${adeleted}" >> "$tmp_archive"
    done < "$ARCHIVE_LOG"
    mv "$tmp_archive" "$ARCHIVE_LOG"
fi
