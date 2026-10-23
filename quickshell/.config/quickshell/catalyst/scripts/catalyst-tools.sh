#!/usr/bin/env bash
# Tsubasa Catalyst — outils développeur locaux (rien n'est envoyé en ligne).
#   catalyst-tools.sh ocr        zone -> texte (tesseract) -> presse-papiers
#   catalyst-tools.sh pick       pipette -> #hex -> presse-papiers
#   catalyst-tools.sh shot       zone -> PNG + presse-papiers (quick_shot.sh)
#   catalyst-tools.sh shot-full  écran complet
set -u

notify() { notify-send -a "$(cat ~/.cache/catalyst/brand 2>/dev/null || echo catalyst)" "$@" 2>/dev/null || true; }

case "${1:-}" in
ocr)
    G="$(slurp)" || exit 0
    [ -z "$G" ] && exit 0
    TMP="$(mktemp --suffix=.png)"
    trap 'rm -f "$TMP"' EXIT
    grim -g "$G" "$TMP" || exit 1
    # langues installées parmi fra/eng
    LANGS="$(tesseract --list-langs 2>/dev/null | grep -xE 'fra|eng' | paste -sd+)"
    TEXT="$(tesseract "$TMP" - -l "${LANGS:-eng}" 2>/dev/null | sed -e 's/[[:space:]]*$//' | sed -e '/./,$!d')"
    if [ -z "$TEXT" ]; then
        notify -i edit-find "OCR" "Aucun texte reconnu."
        exit 0
    fi
    printf '%s' "$TEXT" | wl-copy
    notify -i edit-copy "Texte copié" "$(printf '%s' "$TEXT" | head -c 160)"
    ;;
pick)
    HEX="$(hyprpicker -f hex -a -q 2>/dev/null | grep -oE '#[0-9a-fA-F]{6}' | head -n1)"
    [ -z "$HEX" ] && exit 0
    printf '%s' "$HEX" | wl-copy
    notify -i color-picker "Couleur copiée" "$HEX"
    ;;
shot)
    exec "$HOME/.config/niri/scripts/quick_shot.sh" region
    ;;
shot-full)
    exec "$HOME/.config/niri/scripts/quick_shot.sh" full
    ;;
*)
    sed -n '2,7p' "$0"
    exit 2
    ;;
esac
