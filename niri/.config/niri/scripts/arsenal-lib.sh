#!/usr/bin/env bash
# Shared helpers for BlackArch HUD + OSINT menu.

TARGET_FILE="${TARGET_FILE:-$HOME/.config/waybar/target.txt}"
RECENTS_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/blackarch-recent"
TOOLS_CACHE="${XDG_RUNTIME_DIR:-/tmp}/ba-tools.cache"
ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/config.rasi}"

arsenal_rofi() {
    local prompt="$1"
    shift
    rofi -dmenu -i -p "$prompt" -theme "$ROFI_THEME" "$@"
}

arsenal_target() {
    local t=""
    t="$(tr -d '\r' <"$TARGET_FILE" 2>/dev/null | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    printf '%s' "$t"
}

arsenal_set_target() {
    local t="${1:-}"
    mkdir -p "$(dirname "$TARGET_FILE")"
    printf '%s\n' "$t" >"$TARGET_FILE"
}

arsenal_ask() {
    local prompt="$1"
    local pre="${2:-}"
    printf '%s' "$pre" | arsenal_rofi "$prompt"
}

arsenal_refresh_cache() {
    if [[ -f "$TOOLS_CACHE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$TOOLS_CACHE" 2>/dev/null || echo 0))) -lt 3600 ]]; then
        return 0
    fi
    pacman -Qg 2>/dev/null | awk '/^blackarch-/ {print $1 "\t" $2}' | sort -u >"$TOOLS_CACHE"
}

arsenal_categories() {
    arsenal_refresh_cache
    awk -F '\t' '{
        g=$1
        sub(/^blackarch-/,"",g)
        c[g]++
    } END {
        for (g in c) printf "%-22s  %4d\n", g, c[g]
    }' "$TOOLS_CACHE" | sort
}

arsenal_tools_in() {
    local cat="$1"
    arsenal_refresh_cache
    awk -F '\t' -v c="blackarch-$cat" '$1==c {print $2}' "$TOOLS_CACHE" | sort -u
}

arsenal_all_tools() {
    arsenal_refresh_cache
    awk -F '\t' '{print $2}' "$TOOLS_CACHE" | sort -u
}

arsenal_is_gui() {
    local tool="$1"
    case "$tool" in
        wireshark*|burpsuite*|maltego*|zaproxy*|zap|bloodhound*|ghidra*|spiderfoot*)
            return 0
            ;;
    esac
    if ls /usr/share/applications/*"$tool"* >/dev/null 2>&1; then
        return 0
    fi
    if pacman -Ql "$tool" 2>/dev/null | grep -q '/usr/share/applications/.*\.desktop$'; then
        return 0
    fi
    return 1
}

arsenal_remember() {
    local tool="$1"
    mkdir -p "$(dirname "$RECENTS_FILE")"
    {
        printf '%s\n' "$tool"
        grep -Fxv "$tool" "$RECENTS_FILE" 2>/dev/null || true
    } | head -n 12 >"$RECENTS_FILE.tmp"
    mv "$RECENTS_FILE.tmp" "$RECENTS_FILE"
}

arsenal_recents() {
    [[ -f "$RECENTS_FILE" ]] || return 0
    cat "$RECENTS_FILE"
}

arsenal_bin() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        printf '%s' "$tool"
        return
    fi
    # BlackArch sometimes prefixes desktop wrappers
    if command -v "ba-$tool" >/dev/null 2>&1; then
        printf '%s' "ba-$tool"
        return
    fi
    printf '%s' "$tool"
}

arsenal_launch() {
    local tool="$1"
    local extra="${2:-}"
    local target
    target="$(arsenal_target)"
    local bin
    bin="$(arsenal_bin "$tool")"
    arsenal_remember "$tool"

    if arsenal_is_gui "$tool" || arsenal_is_gui "$bin"; then
        if command -v "$bin" >/dev/null 2>&1; then
            "$bin" >/dev/null 2>&1 &
        else
            gtk-launch "$(basename "$(ls /usr/share/applications/*"$tool"* 2>/dev/null | head -n1)")" >/dev/null 2>&1 &
        fi
        return
    fi

    local title="BlackArch - $tool"
    local banner cmd
    if [[ -n "$target" ]]; then
        banner="echo -e '\\e[1;31m  cible : ${target}\\e[0m'; echo"
    else
        banner="echo -e '\\e[1;33m  pas de cible (Ops / HUD -> Définir la cible)\\e[0m'; echo"
    fi
    if [[ -n "$extra" ]]; then
        cmd="$banner; echo -e '\\e[1;36m  \$ ${extra}\\e[0m'; echo; ${extra}; echo; exec bash"
    else
        cmd="$banner; echo -e '\\e[1;36m  outil : ${bin}\\e[0m'; echo; ${bin} --help 2>/dev/null | head -n 40 || ${bin} -h 2>/dev/null | head -n 40 || true; echo; echo 'prêt — tape ta commande'; exec bash"
    fi
    alacritty -t "$title" -e bash -lc "$cmd" >/dev/null 2>&1 &
}

arsenal_pick_tool() {
    local prompt="$1"
    shift
    printf '%s\n' "$@" | arsenal_rofi "$prompt"
}
