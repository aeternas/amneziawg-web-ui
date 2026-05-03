#!/bin/bash

# Setup iptables for WireGuard interface
# Usage: setup_iptables.sh <interface_name> <subnet> [subnet_v6]

INTERFACE=$1
SUBNET=$2
SUBNET_V6=$3

if [ -z "$INTERFACE" ] || [ -z "$SUBNET" ]; then
    echo "Usage: $0 <interface_name> <subnet> [subnet_v6]"
    echo "Example: $0 wg0 10.8.1.0/24"
    exit 1
fi

echo "Setting up iptables for interface $INTERFACE with subnet $SUBNET"

# Remove any existing rules for this interface to avoid duplicates
iptables -D INPUT -i $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D OUTPUT -o $INTERFACE -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -o eth+ -s $SUBNET -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i $INTERFACE -o eth+ -s $SUBNET -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true
iptables -t nat -D POSTROUTING -s $SUBNET -o eth+ -j MASQUERADE 2>/dev/null || true

# Allow traffic on the TUN interface
iptables -A INPUT -i $INTERFACE -j ACCEPT
iptables -A FORWARD -i $INTERFACE -j ACCEPT
iptables -A OUTPUT -o $INTERFACE -j ACCEPT

# Allow forwarding traffic only from the VPN
# Match any eth* interface
iptables -A FORWARD -i $INTERFACE -o eth+ -s $SUBNET -j ACCEPT

# Allow established and related connections
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Enable NAT for VPN traffic
iptables -t nat -A POSTROUTING -s $SUBNET -o eth+ -j MASQUERADE

# Optional IPv6 forwarding rules (routed IPv6, no NAT66 by default)
if [ -n "$SUBNET_V6" ]; then
    ip6tables -D INPUT -i $INTERFACE -j ACCEPT 2>/dev/null || true
    ip6tables -D FORWARD -i $INTERFACE -j ACCEPT 2>/dev/null || true
    ip6tables -D OUTPUT -o $INTERFACE -j ACCEPT 2>/dev/null || true
    ip6tables -D FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || true

    ip6tables -A INPUT -i $INTERFACE -j ACCEPT
    ip6tables -A FORWARD -i $INTERFACE -j ACCEPT
    ip6tables -A OUTPUT -o $INTERFACE -j ACCEPT
    ip6tables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
fi

if [ $? -eq 0 ]; then
    echo "iptables rules set up successfully for $INTERFACE"
else
    echo "iptables set up failed for $INTERFACE"
    exit 1
fi
