#!/usr/bin/env bash
set -euo pipefail

read -rp "Enter the last digits of the IP address (1–254): " LAST_OCTET

# Validate numeric range
if ! [[ "$LAST_OCTET" =~ ^[0-9]+$ ]] || [ "$LAST_OCTET" -lt 1 ] || [ "$LAST_OCTET" -gt 254 ]; then
  echo "❌ Invalid IP number. Must be between 1 and 254."
  exit 1
fi

IP_ADDR="192.168.1.$LAST_OCTET"
GATEWAY="192.168.1.1"
DNS="1.1.1.1"
echo "➡️  Setting static IP to $IP_ADDR"

# Detect primary active interface
IFACE=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
if [ -z "$IFACE" ]; then
  echo "❌ Could not detect active network interface."
  exit 1
fi

# Check if NetworkManager connection exists
CON_NAME=$(nmcli -t -f NAME,DEVICE connection show | awk -F: -v iface="$IFACE" '$2==iface{print $1}')
if [ -z "$CON_NAME" ]; then
  CON_NAME="$IFACE"
  echo "ℹ️  No existing NM connection for $IFACE — creating new one..."
  nmcli con add type ethernet ifname "$IFACE" con-name "$CON_NAME" autoconnect yes || true
fi

# Apply static IP settings
nmcli con mod "$CON_NAME" ipv4.method manual ipv4.addresses "$IP_ADDR/24" ipv4.gateway "$GATEWAY" ipv4.dns "$DNS" ipv6.method ignore

# Bring connection down/up to apply
nmcli con down "$CON_NAME" || true
nmcli con up "$CON_NAME" || true

echo "✅ Static IP successfully set to $IP_ADDR on interface $IFACE"
