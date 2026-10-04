#!/usr/bin/env bash
# Find the Pixel's wireless-debugging address and connect, without asking for the port.
#
# The connect port changes every time wireless debugging is switched on, but the phone
# advertises it over mDNS as the service _adb-tls-connect._tcp, which adb lists with
# `adb mdns services`. That is passive discovery of what the phone announces, not a LAN scan.
#
# When mDNS shows nothing (WSL2 in NAT mode, multicast filtered), it falls back to an nmap
# port scan of ONE host — the phone's IP, never a subnet. That IP is the argument / ADB_HOST,
# else the one remembered from the last successful connect (~/.cache/countscore/pixel_adb_ip),
# else a stale offline <ip>:<port> still in `adb devices`.
#
# Usage: adb_connect.sh [<ip>]      # <ip> (or ADB_HOST) picks one phone when several answer
# Prints the device id (<ip>:<port>) alone on stdout, so:  export DEV=$(adb_connect.sh)
# Everything else goes to stderr. Exit 1: nothing found, ask the user for <ip>:<port>.
set -euo pipefail

host="${1:-${ADB_HOST:-}}"
ip_cache="${XDG_CACHE_HOME:-$HOME/.cache}/countscore/pixel_adb_ip"
log() { printf '%s\n' "$*" >&2; }

# Remember the phone's IP (outside the repo: a LAN address does not belong in git).
remember() {
    mkdir -p "$(dirname "$ip_cache")" 2> /dev/null && printf '%s\n' "${1%:*}" > "$ip_cache" || true
}

command -v adb > /dev/null || { log "adb not found (Android SDK Platform Tools)"; exit 1; }

# 1. Already connected over Wi-Fi? Its id is <ip>:<port> in the first column.
connected=$(adb devices | awk 'NR > 1 && $2 == "device" && $1 ~ /:[0-9]+$/ { print $1 }')
if [ -n "$host" ]; then connected=$(grep -F "$host:" <<< "$connected" || true); fi
if [ -n "$connected" ]; then
    remember "$(printf '%s\n' "$connected" | head -n 1)"
    printf '%s\n' "$connected" | head -n 1
    exit 0
fi

# 2. Ask mDNS. A line reads: <name> _adb-tls-connect._tcp <ip>:<port>
services=$(timeout 15 adb mdns services 2> /dev/null || true)
candidates=$(awk '$2 ~ /^_adb-tls-connect\._tcp/ { print $3 }' <<< "$services")
if [ -n "$host" ]; then candidates=$(grep -F "$host:" <<< "$candidates" || true); fi

# A stale <ip>:<old-port> shows as offline and confuses flutter: note its IP, then drop it.
stale=$(adb devices | awk 'NR > 1 && $2 == "offline" { print $1 }')
stale_ip=$(head -n 1 <<< "$stale" | sed 's/:[0-9]*$//')
if [ -n "$stale" ]; then xargs -r -n1 adb disconnect <<< "$stale" > /dev/null 2>&1 || true; fi

try_connect() {   # $1 = <ip>:<port>; prints it and exits 0 on success
    local out
    out=$(timeout 15 adb connect "$1" 2>&1 || true)
    if grep -qE '^(connected|already connected) to' <<< "$out"; then
        remember "$1"
        printf '%s\n' "$1"
        exit 0
    fi
    log "adb connect $1: $out"
}

for addr in $candidates; do try_connect "$addr"; done

# 3. mDNS gave nothing usable: scan the phone's own port range with nmap. Android picks the
#    wireless-debugging port at random in the dynamic range; the scan is one host only.
if [ -z "$host" ] && [ -r "$ip_cache" ]; then host=$(head -n 1 "$ip_cache"); fi
scan_ip="${host:-$stale_ip}"
if [ -n "$scan_ip" ] && command -v nmap > /dev/null; then
    log "mDNS found nothing; scanning $scan_ip for an open wireless-debugging port (nmap)..."
    ports=$(timeout 180 nmap -Pn -n -p 30000-65535 --open -T4 -oG - "$scan_ip" 2> /dev/null \
        | grep -oE '[0-9]+/open' | cut -d/ -f1 || true)
    for port in $ports; do try_connect "$scan_ip:$port"; done
    if [ -n "$ports" ]; then
        log "nmap saw open port(s) $(tr '\n' ' ' <<< "$ports")but none accepted adb connect."
    else
        log "nmap saw no open port in 30000-65535 on $scan_ip."
    fi
elif [ -z "$scan_ip" ]; then
    log "No IP to scan: pass the phone's IP (adb_connect.sh <ip>, or ADB_HOST)."
else
    log "nmap is not installed (sudo apt install nmap), so no port-scan fallback."
fi

# 4. Nothing usable. Say why, so the next step is the right one.
if [ -n "$candidates" ]; then
    log "The phone advertises a connect port but adb connect failed: the pairing was dropped."
    log "Ask the user for the pairing port and 6-digit code (Wireless debugging -> Pair device"
    log "with pairing code), then: adb pair <ip>:<pairing-port> <code>, and run this again."
elif grep -q '_adb-tls-pairing' <<< "$services"; then
    log "The phone is on the pairing screen: ask the user for the pairing code, then:"
    log "  adb pair $(awk '$2 ~ /^_adb-tls-pairing/ { print $3; exit }' <<< "$services") <code>"
else
    log "No wireless-debugging service over mDNS or nmap. Either wireless debugging is off, the"
    log "phone is on another network or has another IP. Ask the user for <ip>:<port> from the phone."
    log "Never scan more than the phone's one IP."
fi
exit 1
