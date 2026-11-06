#!/usr/bin/env bash
# img_menu.sh — Design / images : conversion, redimension, palette, GIF, Krita, captures.
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

IMG_FILTER='Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp *.svg *.avif *.jxl'
VID_FILTER='Vidéos | *.mp4 *.mkv *.webm *.mov *.avi'

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰹞  Captures d'écran & OCR…" \
        "󰀼  Pipette couleur (écran)" \
        "󰏗  Convertir le format d'une image" \
        "󰊠  Redimensionner une image" \
        "󰏘  Palette matugen depuis une image" \
        "󰰶  Vidéo → GIF" \
        "󰹉  Ouvrir dans Krita" \
        "󰋢  Info / métadonnées (identify)" \
    | tools_pick "󰏘 Design"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;
    *"Captures"*) exec "$TOOLS_DIR/shot_menu.sh" ;;
    *"Pipette"*) exec "$TOOLS_DIR/color_pick.sh" ;;

    *"Convertir"*)
        SRC="$(tools_pick_file "$IMG_FILTER" "Image à convertir")"
        [ -z "$SRC" ] && exit 0
        FMT="$(printf '%s\n' png jpg webp avif tiff bmp | tools_pick "Format cible" "Source : ${SRC##*/}")"
        [ -z "$FMT" ] && exit 0
        DST="${SRC%.*}.$FMT"
        [ "$DST" = "$SRC" ] && DST="${SRC%.*}_out.$FMT"
        if convert "$SRC" "$DST" 2>/dev/null; then
            tools_notify "Image" "→ $DST" "$DST"
        else
            tools_notify "Image" "Échec de la conversion" dialog-error
        fi
        ;;

    *"Redimensionner"*)
        SRC="$(tools_pick_file "$IMG_FILTER" "Image à redimensionner")"
        [ -z "$SRC" ] && exit 0
        W="$(tools_ask "Largeur (px, ou 50%)" "1920")"
        [ -z "$W" ] && exit 0
        DST="${SRC%.*}_resized.${SRC##*.}"
        if convert "$SRC" -resize "$W" "$DST" 2>/dev/null; then
            tools_notify "Image" "→ $DST" "$DST"
        else
            tools_notify "Image" "Échec du redimensionnement" dialog-error
        fi
        ;;

    *"Palette"*)
        SRC="$(tools_pick_file "$IMG_FILTER" "Image source de la palette")"
        [ -z "$SRC" ] && exit 0
        if have matugen; then
            tools_notify "Palette" "matugen depuis ${SRC##*/}…"
            (cd "$HOME" && matugen image "$SRC" -t scheme-content) >/dev/null 2>&1 &
        else
            tools_notify "Palette" "matugen absent" dialog-warning
        fi
        ;;

    *"GIF"*)
        SRC="$(tools_pick_file "$VID_FILTER" "Vidéo source")"
        [ -z "$SRC" ] && exit 0
        FPS="$(tools_ask "Images par seconde" "12")"
        [ -z "$FPS" ] && exit 0
        WIDTH="$(tools_ask "Largeur du GIF (px)" "480")"
        [ -z "$WIDTH" ] && exit 0
        DST="${SRC%.*}.gif"
        [ "$DST" = "$SRC" ] && DST="${SRC%.*}_clip.gif"
        tools_term "Vidéo → GIF" \
            "ffmpeg -y -i \"$SRC\" -vf \"fps=$FPS,scale=$WIDTH:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5\" -loop 0 \"$DST\" && echo OK: $DST"
        ;;

    *"Krita"*)
        if ! have krita; then
            tools_notify "Krita" "Non installé" dialog-warning
            exit 0
        fi
        SRC="$(tools_pick_file "$IMG_FILTER" "Image à éditer (ou annuler pour un canvas vierge)")"
        if [ -n "$SRC" ]; then
            setsid krita "$SRC" >/dev/null 2>&1 &
        else
            setsid krita >/dev/null 2>&1 &
        fi
        ;;

    *"Info"*)
        SRC="$(tools_pick_file "$IMG_FILTER" "Image à inspecter")"
        [ -z "$SRC" ] && exit 0
        tools_term "identify" "identify -verbose \"$SRC\" | head -60"
        ;;
esac
