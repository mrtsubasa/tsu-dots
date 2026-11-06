#!/bin/bash
# claude_panel_pick.sh — Navigateur de dossiers (rofi) pour le panel IA.
#
# Permet de choisir le dossier ET l'IA du panel :
#   - 🤖 changer de moteur IA (opencode, claude, codex, grok…)
#   - 📁 entrer dans un sous-dossier
#   - 📂 .. remonter
#   - 🔎 recherche floue (fd) dans tout le HOME
#   - ✅ ouvrir l'IA dans le dossier courant
# Le choix bascule le panel via claude_panel.sh --switch --dir <choix>.

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/ai_engines.sh"

ENGINE="$HOME/.config/niri/scripts/claude_panel.sh"
STATE_DIR="$HOME/.cache/claude-panel"
LASTDIR_FILE="$STATE_DIR/lastdir"
ROFI=(rofi -dmenu -i -theme-str 'window { width: 45%; } listview { lines: 14; }')

refresh_labels() {
    CUR_ENGINE="$(ai_last_engine)"
    OPEN_HERE="✅  Ouvrir ${CUR_ENGINE:-claude} ici"
    AI_ROW="🤖  IA : ${CUR_ENGINE:-?}   (changer)"
}
refresh_labels
GO_UP="📂  ..  (remonter)"
FUZZY="🔎  Recherche floue (tout le HOME)"

# Point de départ : dernier dossier utilisé, sinon $HOME
cur="$(cat "$LASTDIR_FILE" 2>/dev/null)"
[ -d "$cur" ] || cur="$HOME"

launch() {  # $1 = dossier choisi
    setsid -f "$ENGINE" --switch --dir "$1" >/dev/null 2>&1
    exit 0
}

while true; do
    refresh_labels

    # Sous-dossiers (non cachés) du dossier courant
    mapfile -t subs < <(find "$cur" -mindepth 1 -maxdepth 1 -type d \
        -not -name '.*' -printf '%f\n' 2>/dev/null | sort -f)

    menu="$OPEN_HERE"$'\n'"$AI_ROW"$'\n'"$GO_UP"$'\n'"$FUZZY"
    for d in "${subs[@]}"; do menu+=$'\n'"📁  $d"; done

    sel="$(printf '%s' "$menu" | "${ROFI[@]}" -p "📂 ${cur/#$HOME/\~}")"
    [ -z "$sel" ] && exit 0   # Échap -> on annule

    case "$sel" in
        "$OPEN_HERE")
            launch "$cur" ;;
        "$AI_ROW")
            new_engine="$(ai_pick_engine_rofi)"
            [ -n "$new_engine" ] && ai_set_engine "$new_engine" ;;
        "$GO_UP")
            cur="$(dirname "$cur")" ;;
        "$FUZZY")
            pick="$(fd --type d --exclude .git --exclude node_modules --exclude .cache \
                . "$HOME" 2>/dev/null \
                | sed "s|^$HOME|~|" \
                | "${ROFI[@]}" -p '🔎 dossier')"
            [ -z "$pick" ] && continue
            launch "${pick/#\~/$HOME}" ;;
        "📁  "*)
            name="${sel#📁  }"
            cur="$cur/$name" ;;
    esac
done
