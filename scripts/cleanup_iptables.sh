#!/bin/bash

# Cleanup iptables for WireGuard interface
# Usage: cleanup_iptables.sh <interface_name> <subnet> [subnet_v6]

INTERFACE=$1
SUBNET=$2
SUBNET_V6=$3

if [ -z "$INTERFACE" ] || [ -z "$SUBNET" ]; then
    echo "Usage: $0 <interface_name> <subnet> [subnet_v6]"
    echo "Example: $0 wg0 10.8.1.0/24"
    exit 1
fi

echo "Cleaning up iptables for interface $INTERFACE with subnet $SUBNET"

# Remove rules in reverse order
iptables -t nat -D POSTROUTING -s $SUBNET -o eth+ -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -o eth+ -s $SUBNET -j ACCEPT 2>/dev/null || true
iptables -D OUTPUT -o $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D INPUT -i $INTERFACE -j ACCEPT 2>/dev/null || true

if [ -n "$SUBNET_V6" ]; then
    ip6tables -D FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
    ip6tables -D OUTPUT -o $INTERFACE -j ACCEPT 2>/dev/null || true
    ip6tables -D FORWARD -i $INTERFACE -j ACCEPT 2>/dev/null || true
    ip6tables -D INPUT -i $INTERFACE -j ACCEPT 2>/dev/null || true
fi

echo "iptables rules cleaned up successfully for $INTERFACE"
