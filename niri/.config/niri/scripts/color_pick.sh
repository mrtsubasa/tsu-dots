#!/usr/bin/env bash
# color_pick.sh — Pipette couleur : niri pick-color → #hex + presse-papiers (+ matugen optionnel).
# Bind: Mod+Alt+C
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    RAW="$(hyprpicker -f hex -b -q 2>/dev/null | head -n1)"
else
    RAW="$(niri msg pick-color 2>/dev/null | head -n1)"
fi
[ -z "$RAW" ] && exit 0

# Formats attendus : "Picked color: rgb(r, g, b)" ou "#rrggbb"
if printf '%s' "$RAW" | grep -qoE '#[0-9a-fA-F]{6}'; then
    HEX="$(printf '%s' "$RAW" | grep -oE '#[0-9a-fA-F]{6}' | head -n1)"
else
    RGB="$(printf '%s' "$RAW" | grep -oE '[0-9]+' | head -n3 | tr '\n' ' ')"
    set -- $RGB
    [ $# -lt 3 ] && { tools_notify "Couleur" "Format inconnu : $RAW" dialog-error; exit 1; }
    HEX="$(printf '#%02x%02x%02x' "$1" "$2" "$3")"
fi

HEX_LC="$(printf '%s' "$HEX" | tr 'A-F' 'a-f')"
printf '%s' "$HEX_LC" | wl-copy

CHOICE="$(
    printf '%s\n' \
        "✔  Copier seulement" \
        "󰏘  Copier + appliquer la palette (matugen)" \
    | tools_pick "󰀼 $HEX_LC"
)"
[ -z "$CHOICE" ] && CHOICE="✔  Copier seulement"

case "$CHOICE" in
    *matugen*)
        tools_notify "Couleur" "$HEX_LC copiée — génération de la palette…"
        if have matugen; then
            (cd "$HOME" && matugen color hex "$HEX_LC" -t scheme-content) >/dev/null 2>&1 &
            tools_notify "Couleur" "$HEX_LC copiée + palette matugen en cours"
        else
            tools_notify "Couleur" "$HEX_LC copiée (matugen absent)" dialog-warning
        fi
        ;;
    *)
        tools_notify "Couleur" "$HEX_LC copiée"
        ;;
esac
