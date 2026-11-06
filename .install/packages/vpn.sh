#!/bin/bash
# =============================================================================
# VPN Packages - VPN panel (WireGuard, OpenVPN, ProtonVPN)
# =============================================================================
# Optional: needed by the VPN panel (scripts/vpn.py, scripts/pvpn.py)
# =============================================================================

VPN_PACKAGES=(
    "wireguard-tools"
    "openvpn"
    "networkmanager-openvpn"
    "networkmanager-vpnc"
    "proton-vpn-gtk-app"         # ProtonVPN login (pvpn.py reuses its session)
    "python-proton-vpn-api-core"
)

VPN_AUR_PACKAGES=(
)
