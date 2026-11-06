#!/bin/bash
SCRIPTS_DIR="$HOME/.config/niri/scripts"

OPTIONS="󰍉 Recherche Wallhaven
󰓐 Recherche Unsplash
󰸉 Galerie images
󰎁 Galerie vidéos
󰐑 Galerie (tout)
󰑖 Aléatoire + palette
󰉩 Konachan
󰉏 Gelbooru
󰋩 Yande.re
󰝰 Ouvrir le dossier"

CHOICE=$(echo "$OPTIONS" | rofi -dmenu -i -p "󰸉 Wallpaper" \
  -theme "${ROFI_THEME:-$HOME/.config/rofi/config.rasi}" \
  -theme-str 'window { width: 32%; } listview { lines: 10; }')

case "$CHOICE" in
    "󰍉 Recherche Wallhaven") "$SCRIPTS_DIR/wallhaven_wallpaper.sh" & ;;
    "󰓐 Recherche Unsplash") "$SCRIPTS_DIR/unsplash_wallpaper.sh" & ;;
    "󰸉 Galerie images") "$SCRIPTS_DIR/wallpaper_select.sh" "images" & ;;
    "󰎁 Galerie vidéos") "$SCRIPTS_DIR/wallpaper_select.sh" "videos" & ;;
    "󰐑 Galerie (tout)") "$SCRIPTS_DIR/wallpaper_select.sh" "all" & ;;
    "󰑖 Aléatoire + palette") "$SCRIPTS_DIR/wallpaper.sh" random & ;;
    "󰉩 Konachan") "$SCRIPTS_DIR/konachan_wallpaper.sh" & ;;
    "󰉏 Gelbooru") "$SCRIPTS_DIR/gelbooru_wallpaper.sh" & ;;
    "󰋩 Yande.re") "$SCRIPTS_DIR/yandere_wallpaper.sh" & ;;
    "󰝰 Ouvrir le dossier") "$SCRIPTS_DIR/wallpaper.sh" dir & ;;
esac
