#!/bin/bash
# claude_panel_bg.sh — Sélecteur d'image de fond (rofi) pour le panel Claude Code.
#
# Navigue dans tes fichiers (📁 dossiers, 🖼 images avec aperçu miniature),
# ou recherche floue. L'image choisie devient le fond du panel wezterm,
# appliquée À CHAUD (touch de la config -> reload, sans couper Claude).
#
#   ✅ pick image -> ~/.cache/claude-panel/bg
#   🚫 aucune     -> fond uni Silver Wolf

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

STATE_DIR="$HOME/.cache/claude-panel"
BG_FILE="$STATE_DIR/bg"
WEZ_CONF="$HOME/.config/wezterm/claude-panel.lua"
mkdir -p "$STATE_DIR"

ROFI=(rofi -dmenu -i -show-icons -theme-str 'window { width: 48%; } listview { lines: 14; }')

GO_UP="📂  ..  (remonter)"
NO_BG="🚫  Aucune image (fond uni Silver Wolf)"
FUZZY="🔎  Recherche floue (images du HOME)"
IMG_FIND=(-iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp')

# Point de départ : ~/Pictures si présent, sinon dernier dossier, sinon HOME
if [ -d "$HOME/Pictures" ]; then cur="$HOME/Pictures"
elif [ -d "$HOME/Images" ]; then cur="$HOME/Images"
else cur="$(cat "$STATE_DIR/lastdir" 2>/dev/null)"; [ -d "$cur" ] || cur="$HOME"; fi

apply() {  # $1 = chemin image ('' => fond uni)
    printf '%s\n' "$1" > "$BG_FILE"
    touch "$WEZ_CONF"          # déclenche le reload à chaud de wezterm
    exit 0
}

# Génère les lignes rofi avec icônes (format: texte\0icon\x1f<icône>)
emit_rows() {
    printf '%s\0icon\x1f%s\n' "$GO_UP"  'go-up'
    printf '%s\0icon\x1f%s\n' "$NO_BG"  'edit-delete'
    printf '%s\0icon\x1f%s\n' "$FUZZY"  'system-search'
    # Dossiers
    find "$cur" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -printf '%f\n' 2>/dev/null \
        | sort -f | while IFS= read -r d; do
            printf '%s\0icon\x1f%s\n' "📁  $d" 'folder'
        done
    # Images (icône = l'image elle-même => miniature)
    find "$cur" -mindepth 1 -maxdepth 1 -type f \( "${IMG_FIND[@]}" \) -printf '%f\n' 2>/dev/null \
        | sort -f | while IFS= read -r f; do
            printf '%s\0icon\x1f%s\n' "🖼  $f" "$cur/$f"
        done
}

while true; do
    sel="$(emit_rows | "${ROFI[@]}" -p "🖼 ${cur/#$HOME/\~}")"
    [ -z "$sel" ] && exit 0

    case "$sel" in
        "$GO_UP")  cur="$(dirname "$cur")" ;;
        "$NO_BG")  apply "" ;;
        "$FUZZY")
            pick="$(fd --type f \
                        -e jpg -e jpeg -e png -e webp -e gif -e bmp \
                        --exclude .cache . "$HOME" 2>/dev/null \
                    | sort | while IFS= read -r p; do
                        printf '%s\0icon\x1f%s\n' "${p/#$HOME/\~}" "$p"
                      done \
                    | "${ROFI[@]}" -p '🔎 image')"
            [ -z "$pick" ] && continue
            apply "${pick/#\~/$HOME}" ;;
        "📁  "*)   cur="$cur/${sel#📁  }" ;;
        "🖼  "*)   apply "$cur/${sel#🖼  }" ;;
    esac
done
