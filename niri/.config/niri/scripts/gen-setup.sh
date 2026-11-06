#!/usr/bin/env bash
# Bootstrap NixOS-like generations: snapper + snap-pac + rEFInd-btrfs.
# Run via:  gen setup   (asks sudo)
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "relance en root :  sudo $0"
    exit 1
fi

USER_NAME="${SUDO_USER:-tsu}"

echo "==> paquets"
pacman -S --needed --noconfirm cachyos-snapper-support snap-pac

echo "==> configs snapper"
if ! snapper list-configs 2>/dev/null | grep -qE '(^|[[:space:]])root([[:space:]]|$)'; then
    snapper -c root create-config /
    echo "    created root -> /"
else
    echo "    root existe déjà"
fi
if ! snapper list-configs 2>/dev/null | grep -qE '(^|[[:space:]])home([[:space:]]|$)'; then
    snapper -c home create-config /home
    echo "    created home -> /home"
else
    echo "    home existe déjà"
fi

echo "==> quotas / ACL / rétention (10 gens, comme CachyOS wiki)"
for cfg in root home; do
    snapper -c "$cfg" set-config "ALLOW_USERS=$USER_NAME"
    snapper -c "$cfg" set-config "SYNC_ACL=yes"
    snapper -c "$cfg" set-config "NUMBER_CLEANUP=yes"
    snapper -c "$cfg" set-config "NUMBER_LIMIT=10"
    snapper -c "$cfg" set-config "NUMBER_LIMIT_IMPORTANT=10"
    snapper -c "$cfg" set-config "NUMBER_MIN_AGE=3600"
    snapper -c "$cfg" set-config "EMPTY_PRE_POST_CLEANUP=yes"
done
# root : snapshots = pacman (snap-pac), pas de timeline
snapper -c root set-config "TIMELINE_CREATE=no"
# home : 3 daily + 2 weekly
snapper -c home set-config "TIMELINE_CREATE=yes"
snapper -c home set-config "TIMELINE_LIMIT_HOURLY=0"
snapper -c home set-config "TIMELINE_LIMIT_DAILY=3"
snapper -c home set-config "TIMELINE_LIMIT_WEEKLY=2"
snapper -c home set-config "TIMELINE_LIMIT_MONTHLY=0"
snapper -c home set-config "TIMELINE_LIMIT_YEARLY=0"

echo "==> timers"
systemctl enable --now snapper-cleanup.timer
systemctl enable --now snapper-timeline.timer

echo "==> rEFInd ↔ snapshots"
systemctl enable --now refind-btrfs.service
# kick a first generate
systemctl restart refind-btrfs.service || true

echo "==> génération zéro"
snapper -c root create --type single --description "gen setup $(date '+%Y-%m-%d %H:%M')" || true
snapper -c home create --type single --description "gen setup home $(date '+%Y-%m-%d %H:%M')" || true

echo
echo "OK. Équivalent NixOS :"
echo "  pacman -Syu          → pre/post auto (snap-pac)  ≃  nixos-rebuild switch"
echo "  gen list             → générations root"
echo "  gen rollback N       → rollback + reboot"
echo "  boot rEFInd          → menu Snapshots (refind-btrfs, 5 dernières)"
echo
echo "GUI :  btrfs-assistant-launcher"
echo
snapper list-configs
echo
snapper -c root list || true
