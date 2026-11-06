#!/usr/bin/env bash
# tools_menu.sh — Hub central « Outils » : Informatique · Design · Musique · Divers.
# Bind: Mod+Shift+G
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

CHOICE="$(
    printf '%s\n' \
        "󰋃  Informatique / Système" \
        "󰏘  Design / Images" \
        "󰝚  Musique / Audio" \
        "󰊖  Divers / Productivité" \
    | tools_pick "󰄬 Outils" "Quel domaine ?"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Informatique*) exec "$TOOLS_DIR/sys_menu.sh" ;;
    *Design*)       exec "$TOOLS_DIR/img_menu.sh" ;;
    *Musique*)      exec "$TOOLS_DIR/music_menu.sh" ;;
    *Divers*)       exec "$TOOLS_DIR/misc_menu.sh" ;;
esac
