#!/usr/bin/env bash
# Toggle between classic rice (catalyst+waybar+dock+swaync) and SekaiPop
set -euo pipefail

STATE_FILE="$HOME/.cache/sekaipop-active"
LOG_FILE="$HOME/.cache/sekaipop/switch.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"; }

stop_classic() {
    log "Stopping classic shell components..."
    # catalyst quickshell
    pkill -f "qs -p .*quickshell/catalyst" 2>/dev/null || true
    # waybar
    pkill -x waybar 2>/dev/null || true
    # custom dock
    pkill -f "dock/launch" 2>/dev/null || true
    pkill -x dock 2>/dev/null || true
    # swaync
    pkill -x swaync 2>/dev/null || true
    # polkit-kde (sekaipop provides its own)
    pkill -f "polkit-kde-authentication-agent" 2>/dev/null || true
    # hypridle (sekaipop has its own lock)
    pkill -x hypridle 2>/dev/null || true
    sleep 1
}

start_sekaipop() {
    log "Starting SekaiPop..."
    qs -c sekaipop -d &
    echo $! > "$STATE_FILE"
    log "SekaiPop started (pid $!)"
}

stop_sekaipop() {
    log "Stopping SekaiPop..."
    pkill -f "qs -c sekaipop" 2>/dev/null || true
    rm -f "$STATE_FILE"
    sleep 1
}

start_classic() {
    log "Restarting classic shell..."
    # Re-launch the same way autostart.conf does
    qs -p "$HOME/.config/quickshell/catalyst" -n -d &
    "$HOME/.config/waybar/launch.sh" &
    "$HOME/.config/dock/launch.sh" &
    swaync &
    /usr/lib/polkit-kde-authentication-agent-1 &
    hypridle &
    log "Classic shell restarted"
}

if [ -f "$STATE_FILE" ]; then
    # SekaiPop is active -> go back to classic
    stop_sekaipop
    start_classic
    notify-send "Rice" "Classic rice restored" -i preferences-desktop-theme 2>/dev/null || true
else
    # Classic is active -> switch to SekaiPop
    stop_classic
    start_sekaipop
    notify-send "Rice" "SekaiPop activated — Super+/ for cheatsheet" -i preferences-desktop-theme 2>/dev/null || true
fi
