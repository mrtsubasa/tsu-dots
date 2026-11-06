#!/bin/bash
# =============================================================================
# Security Packages - BlackArch repository for the Arsenal / Ops panels
# =============================================================================
# Optional. Adds the BlackArch repo (if missing) and a few base tools.
# Arsenal lets you browse and install the ~2800 other tools one by one.
# =============================================================================

SECURITY_PACKAGES=(
    "nmap"
    "wireshark-qt"
    "tcpdump"
    "openbsd-netcat"
    "proxychains-ng"
)

SECURITY_AUR_PACKAGES=(
)

# Setup - add the BlackArch repo with its official strap.sh, after confirmation
setup_security_repo() {
    if grep -qE '^\s*\[blackarch\]' /etc/pacman.conf; then
        echo -e "\033[0;32m[INFO]\033[0m BlackArch repo already enabled."
        return 0
    fi
    local tmp
    tmp="$(mktemp -d)"
    echo -e "\033[0;36m[>>]\033[0m Downloading https://blackarch.org/strap.sh ..."
    if ! curl -fsSL https://blackarch.org/strap.sh -o "$tmp/strap.sh"; then
        echo -e "\033[0;31m[ERROR]\033[0m Download failed, BlackArch skipped."
        rm -rf "$tmp"
        return 1
    fi
    echo "SHA1 of strap.sh: $(sha1sum "$tmp/strap.sh" | cut -d' ' -f1)"
    echo "Compare it with the one listed on https://blackarch.org/downloads.html"
    read -rp "Run strap.sh as root to add the BlackArch repo? [y/N] " ans
    if [[ "$ans" =~ ^[yYoO]$ ]]; then
        sudo bash "$tmp/strap.sh"
    else
        echo "BlackArch skipped."
    fi
    rm -rf "$tmp"
}
