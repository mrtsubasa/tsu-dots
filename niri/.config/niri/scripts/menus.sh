#!/bin/bash
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/spell-visible"
IPC="$HOME/.config/niri/scripts/spell-ipc.sh"
PANELS="dashboard ai vm scripts launcher chat bots ops omarchy blackarch"

hide_spells() {
    local keep="${1:-}"
    mkdir -p "$STATE_DIR"
    QS_PATH="$HOME/.config/quickshell/catalyst"
    if [ -n "$keep" ]; then
        timeout 2 qs ipc -p "$QS_PATH" call panels show "$keep" >/dev/null 2>&1 || true
    else
        timeout 2 qs ipc -p "$QS_PATH" call panels hide >/dev/null 2>&1 || true
    fi
    for p in $PANELS; do
        [ "$p" = "$keep" ] && continue
        "$IPC" "$p" hide 2>/dev/null || true
        rm -f "$STATE_DIR/$p"
    done
}

close_swaync() {
    pgrep -x swaync >/dev/null || return 0
    timeout 0.4 swaync-client -cp >/dev/null 2>&1 || true
}

case "${1:-}" in
    hide-spells)
        hide_spells "${2:-}"
        ;;
    close-swaync)
        close_swaync
        ;;
    exclusive-spell)
        close_swaync
        hide_spells "${2:-}"
        ;;
    exclusive-swaync)
        hide_spells
        ;;
esac
