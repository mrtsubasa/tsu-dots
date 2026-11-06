#!/usr/bin/env bash
# translate_sel.sh — Traduire le presse-papiers (trans / translate-shell) → presse-papiers.
# Bind: Mod+Shift+Y
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

SRC_TEXT="$(wl-paste -n 2>/dev/null || true)"
[ -z "$SRC_TEXT" ] && { tools_notify "Traduction" "Presse-papiers vide — copie un texte d'abord"; exit 1; }
[ "${#SRC_TEXT}" -gt 8000 ] && SRC_TEXT="${SRC_TEXT:0:8000}"

if ! have trans; then
    tools_notify "Traduction" "translate-shell (trans) non installé" dialog-warning
    exit 1
fi

TO="$(printf '%s\n' \
    "anglais (en)" "français (fr)" "espagnol (es)" "allemand (de)" \
    "italien (it)" "portugais (pt)" "japonais (ja)" "coréen (ko)" \
    "chinois (zh)" "russe (ru)" "arabe (ar)" "néerlandais (nl)" \
    | tools_pick "Traduire vers" "Source : presse-papiers (${#SRC_TEXT} car.)")"
[ -z "$TO" ] && exit 0
TO="$(printf '%s' "$TO" | grep -oE '\([a-z]{2}\)' | tr -d '()')"
[ -z "$TO" ] && TO="en"

OUT="$(trans -b ":$TO" -- "$SRC_TEXT" 2>/dev/null || true)"
if [ -z "$OUT" ]; then
    tools_notify "Traduction" "Échec de la traduction" dialog-error
    exit 1
fi

printf '%s' "$OUT" | wl-copy

CHOICE="$(
    printf '%s\n' \
        "✔  Copier la traduction (puis coller)" \
        "󰜖  Copier original + traduction" \
        "󰎆  Afficher dans le terminal" \
    | tools_pick "Traduction → $TO"
)"
case "$CHOICE" in
    *"original"*)
        { printf '%s\n\n' "── ${SRC_TEXT:0:400}"; printf '%s\n\n' "── $OUT"; } | wl-copy
        tools_notify "Traduction" "Texte + traduction copiés"
        ;;
    *"terminal"*)
        tools_term "Traduction $TO" "wl-paste -n | ${PAGER:-less} -R"
        tools_notify "Traduction" "Copiée + affichée"
        ;;
    *)
        tools_notify "Traduction" "$(printf '%s' "$OUT" | head -c 300)"
        ;;
esac
