#!/usr/bin/env bash
# ai_engines.sh — bibliothèque partagée : moteurs IA du panel (à sourcer)

AI_ENGINES_CONF="$HOME/.config/niri/scripts/ai-engines.conf"
AI_STATE_DIR="$HOME/.cache/claude-panel"
AI_LASTENGINE_FILE="$AI_STATE_DIR/lastengine"

ai_engines_available() {
    [ -f "$AI_ENGINES_CONF" ] || return 0
    local line name cmd first resolved
    while IFS= read -r line; do
        case "$line" in
            ''|'#'*) continue ;;
        esac
        case "$line" in
            *'|'*) name="${line%%|*}"; cmd="${line#*|}" ;;
            *)     name="$line";      cmd="$line" ;;
        esac
        first="${cmd%% *}"
        # Seuls les vrais binaires (chemin absolu) comptent : les alias,
        # builtins et mots-clés bash (ex : « continue ») sont ignorés.
        resolved="$(command -v "$first" 2>/dev/null || true)"
        case "$resolved" in
            */*) ;;
            *)   continue ;;
        esac
        printf '%s|%s\n' "$name" "$cmd"
    done < "$AI_ENGINES_CONF"
}

ai_engine_cmd() {
    ai_engines_available \
        | awk -F'|' -v n="$1" '$1 == n { print substr($0, index($0, "|") + 1); exit }'
}

ai_last_engine() {
    local e=""
    if [ -f "$AI_LASTENGINE_FILE" ]; then
        e="$(cat "$AI_LASTENGINE_FILE" 2>/dev/null)"
    fi
    if [ -n "$e" ] && [ -n "$(ai_engine_cmd "$e")" ]; then
        printf '%s' "$e"
        return 0
    fi
    ai_engines_available | head -n1 | cut -d'|' -f1
}

ai_set_engine() {
    mkdir -p "$AI_STATE_DIR"
    printf '%s\n' "$1" > "$AI_LASTENGINE_FILE"
}

ai_pick_engine_rofi() {
    local menu="" line name
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        name="${line%%|*}"
        menu+="${name}"$'\n'
    done <<EOF
$(ai_engines_available)
EOF
    [ -z "$menu" ] && return 1
    printf '%s' "${menu%$'\n'}" \
        | rofi -dmenu -i -p "🤖 IA" -theme-str 'window { width: 28%; } listview { lines: 12; }'
}
