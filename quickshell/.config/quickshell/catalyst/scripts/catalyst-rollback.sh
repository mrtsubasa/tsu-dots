#!/usr/bin/env bash
# Tsubasa Catalyst — retour à l'état d'avant la refonte v3.
#
#   catalyst-rollback.sh status     affiche ce qui serait restauré
#   catalyst-rollback.sh shell      remet le shell Quickshell d'avant v3 (git 95e295e)
#   catalyst-rollback.sh hypr       remet conf.d Hyprland + hyprlock d'avant v3
#   catalyst-rollback.sh all        les deux
#
# Rien n'est supprimé : l'état v3 reste disponible sur la branche
# `tsubasa-catalyst` (git log) et peut être réappliqué avec `git checkout`.
set -euo pipefail

REPO="$HOME/.tsu-dots"
BASE="95e295e"                        # snapshot « avant v3 »
SHELL_DIR="quickshell/.config/quickshell/catalyst"
BK="$REPO/quickshell/.config/quickshell/backups"
HYPR_TGZ="$(ls -1 "$BK"/pre-v3-hypr-*.tar.gz 2>/dev/null | head -1 || true)"
LOCK_BAK="$BK/hyprlock.conf.pre-v3"

status() {
    echo "Dépôt        : $REPO (branche $(git -C "$REPO" branch --show-current))"
    echo "Shell avant  : commit $BASE ($(git -C "$REPO" log -1 --format=%s "$BASE"))"
    echo "Hypr avant   : ${HYPR_TGZ:-introuvable}"
    echo "hyprlock     : $([ -f "$LOCK_BAK" ] && echo "$LOCK_BAK" || echo introuvable)"
}

restore_shell() {
    git -C "$REPO" checkout "$BASE" -- "$SHELL_DIR"
    echo "Shell restauré depuis $BASE. Relance : ~/.config/quickshell/catalyst/scripts/catalyst-session.sh restart"
}

restore_hypr() {
    [ -n "$HYPR_TGZ" ] || { echo "archive Hyprland introuvable"; exit 1; }
    tar -xzf "$HYPR_TGZ" -C "$HOME" .config/hypr/conf.d
    [ -f "$LOCK_BAK" ] && cp "$LOCK_BAK" "$HOME/.config/hypr/hyprlock.conf"
    hyprctl reload >/dev/null 2>&1 || true
    echo "Hyprland restauré depuis $HYPR_TGZ"
}

case "${1:-status}" in
status) status ;;
shell) restore_shell ;;
hypr) restore_hypr ;;
all) restore_shell; restore_hypr ;;
*) sed -n '2,10p' "$0"; exit 2 ;;
esac
