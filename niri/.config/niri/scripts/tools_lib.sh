#!/usr/bin/env bash
# tools_lib.sh — Helpers partagés des menus « Outils » (rofi / notify / terminal).
# À sourcer :  . "$HOME/.config/niri/scripts/tools_lib.sh"
set -u

TOOLS_DIR="${TOOLS_DIR:-$HOME/.config/niri/scripts}"
ROFI_BASE="${ROFI_THEME:-$HOME/.config/rofi/config.rasi}"

have() { command -v "$1" >/dev/null 2>&1; }

tools_notify() { # tools_notify "Titre" "Corps" [icone]
    notify-send -a "Outils" "${1:-Outils}" "${2:-}" ${3:+-i "$3"} >/dev/null 2>&1 || true
}

tools_pick() { # stdin = entrées · $1 = prompt · $2 = message (optionnel)
    local prompt="$1" msg="${2:-}"
    if [ -n "$msg" ]; then
        rofi -dmenu -i -no-custom -p "$prompt" -mesg "$msg" -theme "$ROFI_BASE" \
            -theme-str 'window { width: 34%; border-radius: 14px; } listview { lines: 14; spacing: 6px; } element { padding: 10px 14px; border-radius: 8px; }'
    else
        rofi -dmenu -i -no-custom -p "$prompt" -theme "$ROFI_BASE" \
            -theme-str 'window { width: 34%; border-radius: 14px; } listview { lines: 14; spacing: 6px; } element { padding: 10px 14px; border-radius: 8px; }'
    fi
}

tools_ask() { # tools_ask "Prompt" [pré-remplissage] -> texte ou vide
    printf '%s' "${2:-}" | rofi -dmenu -i -p "$1" -theme "$ROFI_BASE" \
        -theme-str 'window { width: 34%; border-radius: 14px; } listview { lines: 6; }'
}

tools_confirm() { # tools_confirm "Question" -> 0 si Oui
    [ "$(printf 'Oui\nNon\n' | tools_pick "$1")" = "Oui" ]
}

tools_term() { # tools_term "Titre" "commande" — exécute dans alacritty, reste ouvert
    local title="$1" cmd="$2"
    alacritty -t "$title" -e bash -c "$cmd"' || true; echo; echo "── terminé ── Entrée pour fermer ──"; read -r _' >/dev/null 2>&1 &
}

tools_spawn() { # tools_spawn "commande" — arrière-plan silencieux
    setsid bash -c "$1" >/dev/null 2>&1 &
}

tools_last_screenshot() { # chemin de la dernière capture (dated folder ou racine)
    find "$HOME/Images/Screenshots" -type f -name '*.png' -printf '%T@ %p\n' 2>/dev/null \
        | sort -rn | head -n1 | cut -d' ' -f2-
}

tools_pick_file() { # tools_pick_file "filtre zenity" -> chemin ou vide
    zenity --file-selection --title="${2:-Choisir un fichier}" \
        --file-filter="$1" 2>/dev/null || true
}

tools_menu_hub() { # relance le hub
    exec "$TOOLS_DIR/tools_menu.sh"
}
