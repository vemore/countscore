#!/usr/bin/env bash
# Find the Pixel's wireless-debugging address and connect, without asking for the port.
#
# The connect port changes every time wireless debugging is switched on, but the phone
# advertises it over mDNS as the service _adb-tls-connect._tcp, which adb lists with
# `adb mdns services`. That is passive discovery of what the phone announces, not a LAN scan.
#
# Usage: adb_connect.sh [<ip>]      # <ip> (or ADB_HOST) picks one phone when several answer
# Prints the device id (<ip>:<port>) alone on stdout, so:  export DEV=$(adb_connect.sh)
# Everything else goes to stderr. Exit 1: nothing found, ask the user for <ip>:<port>.
set -euo pipefail

host="${1:-${ADB_HOST:-}}"
log() { printf '%s\n' "$*" >&2; }

command -v adb > /dev/null || { log "adb not found (Android SDK Platform Tools)"; exit 1; }

# 1. Already connected over Wi-Fi? Its id is <ip>:<port> in the first column.
connected=$(adb devices | awk 'NR > 1 && $2 == "device" && $1 ~ /:[0-9]+$/ { print $1 }')
if [ -n "$host" ]; then connected=$(grep -F "$host:" <<< "$connected" || true); fi
if [ -n "$connected" ]; then
    printf '%s\n' "$connected" | head -n 1
    exit 0
fi

# 2. Ask mDNS. A line reads: <name> _adb-tls-connect._tcp <ip>:<port>
services=$(timeout 15 adb mdns services 2> /dev/null || true)
candidates=$(awk '$2 ~ /^_adb-tls-connect\._tcp/ { print $3 }' <<< "$services")
if [ -n "$host" ]; then candidates=$(grep -F "$host:" <<< "$candidates" || true); fi

# adb disconnect first: a stale <ip>:<old-port> shows as offline and confuses flutter.
adb devices | awk 'NR > 1 && $2 == "offline" { print $1 }' | xargs -r -n1 adb disconnect > /dev/null 2>&1 || true

for addr in $candidates; do
    out=$(timeout 15 adb connect "$addr" 2>&1 || true)
    if grep -qE '^(connected|already connected) to' <<< "$out"; then
        printf '%s\n' "$addr"
        exit 0
    fi
    log "adb connect $addr: $out"
done

# 3. Nothing usable. Say why, so the next step is the right one.
if [ -n "$candidates" ]; then
    log "The phone advertises a connect port but adb connect failed: the pairing was dropped."
    log "Ask the user for the pairing port and 6-digit code (Wireless debugging -> Pair device"
    log "with pairing code), then: adb pair <ip>:<pairing-port> <code>, and run this again."
elif grep -q '_adb-tls-pairing' <<< "$services"; then
    log "The phone is on the pairing screen: ask the user for the pairing code, then:"
    log "  adb pair $(awk '$2 ~ /^_adb-tls-pairing/ { print $3; exit }' <<< "$services") <code>"
else
    log "No wireless-debugging service seen over mDNS. Either wireless debugging is off, the"
    log "phone is on another network, or this host does not receive multicast (WSL2 in NAT mode;"
    log "mirrored mode usually does). Ask the user for <ip>:<port> from the phone. Never scan the LAN."
fi
exit 1
