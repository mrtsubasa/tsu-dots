#!/bin/bash
set -euo pipefail

WALL_DIR="$HOME/.config/quickshell/catalyst/wallpapers"
CORRUPT_DIR="$WALL_DIR/_corrupted"
CACHE="$HOME/.cache/matugen"
CURRENT="$CACHE/current-wallpaper"
VIDEO_FRAME="$CACHE/video-frame.png"
LOCK="$CACHE/wallpaper.lock"
LOG="$CACHE/wallpaper.log"
mkdir -p "$CORRUPT_DIR" "$CACHE"

WALL=""
DAEMON=""

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }

is_video() {
    local mime f="${1,,}"
    mime=$(file -b --mime-type "$1" 2>/dev/null || true)
    case "$mime" in
        video/*) return 0 ;;
    esac
    case "$f" in
        *.mp4|*.webm|*.mkv|*.mov|*.avi|*.m4v) return 0 ;;
    esac
    return 1
}

is_image() {
    local mime f="${1,,}"
    mime=$(file -b --mime-type "$1" 2>/dev/null || true)
    case "$mime" in
        image/*) return 0 ;;
    esac
    case "$f" in
        *.jpg|*.jpeg|*.png|*.webp|*.gif|*.bmp|*.avif) return 0 ;;
    esac
    return 1
}

list_outputs() {
    mpvpaper -d 2>/dev/null | awk '/Output:/{print $3}'
}

nvidia_ok() {
    nvidia-smi >/dev/null 2>&1
}

pick_image_backend() {
    if pgrep -x awww-daemon >/dev/null && command -v awww >/dev/null; then
        WALL=awww
        DAEMON=awww-daemon
    elif pgrep -x swww-daemon >/dev/null && command -v swww >/dev/null; then
        WALL=swww
        DAEMON=swww-daemon
    elif command -v awww >/dev/null; then
        WALL=awww
        DAEMON=awww-daemon
    elif command -v swww >/dev/null; then
        WALL=swww
        DAEMON=swww-daemon
    else
        notify-send "Wallpaper" "awww/swww introuvable"
        return 1
    fi
}

stop_video() {
    pkill -x mpvpaper >/dev/null 2>&1 || true
    sleep 0.15
}

stop_image() {
    if command -v awww >/dev/null && pgrep -x awww-daemon >/dev/null; then
        awww kill >/dev/null 2>&1 || true
    fi
    if command -v swww >/dev/null && pgrep -x swww-daemon >/dev/null; then
        swww kill >/dev/null 2>&1 || true
    fi
    sleep 0.1
}

start_daemon() {
    local bin="$1"
    # 9>&- : ne pas hériter du flock, sinon le daemon garde le lock.
    if command -v setsid >/dev/null; then
        setsid -f "$bin" 9>&- >/dev/null 2>&1 || setsid "$bin" 9>&- >/dev/null 2>&1 &
    else
        "$bin" 9>&- >/dev/null 2>&1 &
        disown $! 2>/dev/null || true
    fi
}

ensure_image_daemon() {
    pick_image_backend || return 1
    if ! pgrep -x "$DAEMON" >/dev/null; then
        log "start $DAEMON"
        start_daemon "$DAEMON"
    fi
    local i
    for i in $(seq 1 25); do
        if $WALL query >/dev/null 2>&1; then
            stop_video
            return 0
        fi
        sleep 0.2
    done
    log "$DAEMON ne répond pas"
    notify-send "Wallpaper" "$DAEMON ne répond pas"
    return 1
}

grow_effect() {
    echo "--transition-type fade --transition-duration 0.85 --transition-fps 60 --transition-bezier .22,1,.36,1 --transition-step 8"
}

random_effect() {
    local types=(fade wipe grow outer wave)
    local t=${types[RANDOM % ${#types[@]}]}
    case "$t" in
        fade) grow_effect ;;
        wipe) echo "--transition-type wipe --transition-angle 0 --transition-duration 0.9 --transition-fps 60 --transition-bezier .22,1,.36,1 --transition-step 12" ;;
        grow) echo "--transition-type grow --transition-pos 0.5,0.5 --transition-duration 1.1 --transition-fps 60 --transition-bezier .22,1,.36,1 --transition-step 12" ;;
        outer) echo "--transition-type outer --transition-pos 0.5,0.5 --transition-duration 1.0 --transition-fps 60 --transition-bezier .22,1,.36,1 --transition-step 12" ;;
        *) echo "--transition-type wave --transition-angle 135 --transition-duration 1.1 --transition-fps 60 --transition-bezier .22,1,.36,1 --transition-step 12" ;;
    esac
}

apply_palette() {
    local src="$1"
    local for_matugen="${2:-$1}"
    matugen image "$for_matugen" -t scheme-content --prefer saturation >/dev/null 2>&1 9>&- || true
    printf '$bg = "%s"\n' "$for_matugen" >"$CACHE/hyprlock-bg.conf"
    local face=""
    if [ -f "/var/lib/AccountsService/icons/${USER}" ]; then
        face="/var/lib/AccountsService/icons/${USER}"
    elif [ -f "$HOME/.face" ]; then
        face="$HOME/.face"
    fi
    if [ -n "$face" ]; then
        magick "$face" "$CACHE/lock-avatar.png" 2>/dev/null 9>&- || cp -f "$face" "$CACHE/lock-avatar.png" 2>/dev/null || true
    fi
    printf '%s\n' "$src" >"$CURRENT"
    ~/.config/niri/scripts/waybar-palette.sh >/dev/null 2>&1 9>&- || true
    if pgrep -x swaync >/dev/null; then
        timeout 1 swaync-client -rs >/dev/null 2>&1 9>&- || true
    fi
    if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl reload >/dev/null 2>&1 9>&- || true
    fi
    timeout 1 sp -l shell update refresh-colors true >/dev/null 2>&1 9>&- || true
    timeout 1 sp -l shell update refresh-colors false >/dev/null 2>&1 9>&- || true
}

extract_frame() {
    local vid="$1" out="$2"
    ffmpeg -y -ss 1 -i "$vid" -frames:v 1 -q:v 2 "$out" >/dev/null 2>&1 \
        || ffmpeg -y -i "$vid" -frames:v 1 -q:v 2 "$out" >/dev/null 2>&1
}

mpv_opts() {
    if [ "${1:-}" = "sw" ]; then
        echo "no-audio --loop --panscan=1.0 --hwdec=no --gpu-api=opengl --vo=gpu --vf=scale=1920:1080 --profile=fast"
    else
        echo "no-audio --loop --panscan=1.0 --hwdec=auto-copy --gpu-api=opengl --vo=gpu --vf=scale=1920:1080 --profile=fast"
    fi
}

start_mpvpaper() {
    local vid="$1" opts="$2"
    : >"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log"
    local outs o
    mapfile -t outs < <(list_outputs)
    if [ "${#outs[@]}" -eq 0 ]; then
        log "mpvpaper ALL"
        mpvpaper -f -o "$opts" ALL "$vid" 9>&- >>"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 || true
        return
    fi
    for o in "${outs[@]}"; do
        log "mpvpaper $o"
        mpvpaper -f -o "$opts" "$o" "$vid" 9>&- >>"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 || true
    done
}

wait_mpv() {
    local i
    for i in $(seq 1 20); do
        pgrep -x mpvpaper >/dev/null && return 0
        sleep 0.15
    done
    return 1
}

set_image() {
    local img="$1"
    local mode="${2:-pick}"
    ensure_image_daemon || return 1
    local effect
    if [ "$mode" = "random" ]; then
        effect=$(random_effect)
    else
        effect=$(grow_effect)
    fi
    # shellcheck disable=SC2086
    if $WALL img "$img" $effect 9>&-; then
        apply_palette "$img"
        log "image ok $img"
        return 0
    fi
    log "image fail $img"
    return 1
}

set_video() {
    local vid="$1"
    if ! command -v mpvpaper >/dev/null; then
        notify-send "Wallpaper" "mpvpaper introuvable (nécessaire pour les vidéos)"
        return 1
    fi
    stop_video
    stop_image
    sleep 0.2
    local mode=hw
    nvidia_ok || mode=sw
    log "video $mode $vid"
    start_mpvpaper "$vid" "$(mpv_opts "$mode")"
    if ! wait_mpv && [ "$mode" = "hw" ]; then
        log "video hw fail, retry sw"
        stop_video
        start_mpvpaper "$vid" "$(mpv_opts sw)"
        wait_mpv || true
    fi
    if ! pgrep -x mpvpaper >/dev/null; then
        notify-send "Wallpaper" "mpvpaper n'a pas démarré — voir ${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log"
        log "video fail"
        # récupère un fond image pour pas laisser le bureau gris
        if [ -f "$CURRENT" ]; then
            local prev
            prev=$(cat "$CURRENT")
            if [ -f "$prev" ] && is_image "$prev"; then
                set_image "$prev" pick || true
            fi
        fi
        return 1
    fi
    if extract_frame "$vid" "$VIDEO_FRAME" && [ -f "$VIDEO_FRAME" ]; then
        apply_palette "$vid" "$VIDEO_FRAME"
    else
        printf '%s\n' "$vid" >"$CURRENT"
    fi
    log "video ok"
}

set_wall() {
    local img="$1"
    local mode="${2:-pick}"
    [ -f "$img" ] || { notify-send "Wallpaper" "Fichier introuvable : $img"; return 1; }
    if is_video "$img"; then
        set_video "$img"
        return
    fi
    if is_image "$img"; then
        set_image "$img" "$mode"
        return
    fi
    mv "$img" "$CORRUPT_DIR/" 2>/dev/null || true
    notify-send "Wallpaper" "Fichier non-image déplacé dans _corrupted/"
    return 1
}

list_walls() {
    # aléatoire : uniquement la bibliothèque SFW
    find "$WALL_DIR/sfw" -type f -not -path "*_corrupted*" -not -iname "preview.*" \( \
        -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \
    \)
}

alive() {
    local img=""
    [ -f "$CURRENT" ] && img=$(cat "$CURRENT")
    if [ -n "$img" ] && [ -f "$img" ] && is_video "$img"; then
        pgrep -x mpvpaper >/dev/null
    else
        pgrep -x awww-daemon >/dev/null || pgrep -x swww-daemon >/dev/null
    fi
}

restore_inner() {
    if [ -f "$CURRENT" ]; then
        local img
        img=$(cat "$CURRENT")
        if [ -f "$img" ] && set_wall "$img" pick; then
            return 0
        fi
    fi
    if pick_image_backend && pgrep -x "$DAEMON" >/dev/null; then
        $WALL restore >/dev/null 2>&1 || $WALL query >/dev/null 2>&1 || true
        return 0
    fi
    if pick_image_backend; then
        ensure_image_daemon || true
        $WALL restore >/dev/null 2>&1 || true
    fi
}

take_lock() {
    exec 9>"$LOCK"
    flock -w 20 9 || {
        log "lock timeout"
        notify-send "Wallpaper" "Occupé — réessaie"
        exit 1
    }
}

cmd_watch() {
    exec 9>"$LOCK"
    log "watch start"
    restore_inner || true
    flock -u 9 2>/dev/null || true
    while true; do
        sleep 4
        if flock -n 9; then
            if ! alive; then
                log "daemon mort — restore"
                restore_inner || true
            fi
            flock -u 9 2>/dev/null || true
        fi
    done
}

case "${1:-}" in
set)
    take_lock
    set_wall "${2:?usage: wallpaper.sh set <fichier>}" pick
    ;;
random)
    take_lock
    mapfile -t WALLS < <(list_walls | shuf)
    for w in "${WALLS[@]:0:8}"; do
        if set_wall "$w" random; then
            notify-send "Wallpaper" "$(basename "$w")"
            exit 0
        fi
    done
    notify-send "Wallpaper" "Aucun wallpaper valide dans $WALL_DIR"
    exit 1
    ;;
restore)
    take_lock
    restore_inner
    ;;
watch)
    cmd_watch
    ;;
dir)
    exec thunar "$WALL_DIR"
    ;;
*)
    echo "Usage: wallpaper.sh {set <fichier> | random | restore | watch | dir}"
    exit 1
    ;;
esac
