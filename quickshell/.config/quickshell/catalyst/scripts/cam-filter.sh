#!/bin/bash
# cam-filter.sh — filtres webcam en temps réel -> caméra virtuelle (GStreamer).
# Pilote depuis la barre Catalyst (singleton Cam / CamPanel). Aucun root au
# runtime : lit la vraie webcam, applique une chaîne de filtres, réexpose le
# flux sur un périphérique v4l2loopback que Discord/navigateur sélectionnent.
#
#   start <preset> | stop | toggle <preset> | status | src | sink | presets
#
# NB : LC_ALL=C est obligatoire (en locale FR, GStreamer attend « 1,2 » pour
# les flottants -> « erreur de syntaxe » sans ça).
set -uo pipefail

CACHE="$HOME/.cache/catalyst"
STATE="$CACHE/cam-filter.json"
PIDF="$CACHE/cam-filter.pid"
IMGF="$CACHE/cam-image.txt"       # image choisie (fond chroma + mode Image)
SCENEF="$HOME/.local/share/catalyst/cam-scene.json"   # calques du preset « scene »
mkdir -p "$CACHE" "$(dirname "$SCENEF")"

dev_name() { cat "/sys/class/video4linux/$(basename "$1")/name" 2>/dev/null; }

# première vraie webcam de capture (exclut les loopback/virtuelles)
find_src() {
    for d in /dev/video*; do
        [ -e "$d" ] || continue
        case "$(dev_name "$d")" in
            *Virtual*|*"Catalyst Cam"*|*Dummy*|*Loopback*) continue ;;
        esac
        if v4l2-ctl -d "$d" --list-formats 2>/dev/null | grep -qE "MJPG|YUYV"; then
            echo "$d"; return 0
        fi
    done
    return 1
}

# cam virtuelle cible : « Catalyst Cam » si elle existe, sinon « OBS Virtual Camera »
find_sink() {
    local obs=""
    for d in /dev/video*; do
        [ -e "$d" ] || continue
        case "$(dev_name "$d")" in
            *"Catalyst Cam"*) echo "$d"; return 0 ;;
            *Virtual*) obs="$d" ;;
        esac
    done
    [ -n "$obs" ] && { echo "$obs"; return 0; }
    return 1
}

# chaîne GStreamer par preset. NB : un « videoconvert » est requis ENTRE deux
# filtres frei0r (sinon la négociation de format échoue).
filter_chain() {
    case "$1" in
        # --- Rendu ---
        cyber)   echo "frei0r-filter-rgbsplit0r ! videoconvert ! videobalance saturation=1.5 contrast=1.2 hue=-0.06" ;;
        noir)    echo "frei0r-filter-bw0r ! videoconvert ! videobalance contrast=1.25" ;;
        retouch) echo "frei0r-filter-hqdn3d spatial=0.6 ! videoconvert ! videobalance brightness=0.05 contrast=1.03 saturation=1.08" ;;
        sepia)   echo "coloreffects preset=sepia" ;;
        thermal) echo "coloreffects preset=heat" ;;
        # --- Dessin ---
        cartoon) echo "frei0r-filter-cartoon diffspace=0.4 ! videoconvert ! frei0r-filter-posterize levels=0.25 ! videoconvert ! videobalance saturation=1.4" ;;
        anime)   echo "frei0r-filter-hqdn3d spatial=0.5 ! videoconvert ! videobalance saturation=1.6 contrast=1.1 ! videoconvert ! frei0r-filter-cartoon diffspace=0.5" ;;
        manga)   echo "frei0r-filter-sobel ! videoconvert ! frei0r-filter-invert0r" ;;
        comic)   echo "frei0r-filter-posterize levels=0.2 ! videoconvert ! frei0r-filter-colorhalftone" ;;
        pixel)   echo "frei0r-filter-pixeliz0r" ;;
        # --- Déformation ---
        mirror)  echo "frei0r-filter-mirr0r" ;;
        fisheye) echo "frei0r-filter-defish0r" ;;
        kaleid)  echo "frei0r-filter-kaleid0sc0pe" ;;
        water)   echo "frei0r-filter-water" ;;
        pixsort) echo "frei0r-filter-pixels0rt" ;;
        distort) echo "frei0r-filter-distort0r" ;;
        emboss)  echo "frei0r-filter-emboss" ;;
        # --- Fun ---
        neon)    echo "edgetv" ;;
        glitch)  echo "frei0r-filter-glitch0r" ;;
        vhs)     echo "agingtv" ;;
        crt)     echo "frei0r-filter-scanline0r" ;;
        matrix)  echo "optv" ;;
        *) return 1 ;;
    esac
}

# dernier wallpaper (fallback)
last_wall() {
    ls -t "$HOME/.config/quickshell/catalyst/wallpapers/sfw"/*.jpg "$HOME/.config/quickshell/catalyst/wallpapers/sfw"/*.jpeg \
          "$HOME/.config/quickshell/catalyst/wallpapers/sfw"/*.png 2>/dev/null | head -1
}

# image choisie par l'utilisateur (fond chroma / mode Image) ; sinon wallpaper
cam_image() {
    if [ -f "$IMGF" ]; then
        local p; p=$(cat "$IMGF" 2>/dev/null)
        [ -n "$p" ] && [ -f "$p" ] && { echo "$p"; return 0; }
    fi
    last_wall
}

write_state() { printf '{"on":%s,"preset":"%s","sink":"%s","image":"%s"}\n' "$1" "$2" "$3" "$(cam_image)" >"$STATE"; }

running() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null; }

stop() {
    [ -f "$PIDF" ] && kill "$(cat "$PIDF" 2>/dev/null)" 2>/dev/null
    pkill -f "catalystcamsink" 2>/dev/null
    pkill -f "cam_anime.py" 2>/dev/null
    pkill -f "cam_bg.py" 2>/dev/null
    pkill -f "cam_scene.py" 2>/dev/null
    rm -f "$PIDF"
    write_state false "" ""
}

# venv IA (AnimeGANv3) : python + dossier des libs CUDA (cudnn/cublas)
AIVENV="$HOME/.local/share/catalyst/animenv"
ai_libs() {
    local d
    d=$(dirname "$(find "$AIVENV/lib" -name 'libcudnn.so*' 2>/dev/null | head -1)")
    local c
    c=$(dirname "$(find "$AIVENV/lib" -name 'libcublas.so*' 2>/dev/null | head -1)")
    echo "$d:$c"
}

start() {
    local preset="${1:-cyber}" chain src sink
    src=$(find_src)   || { echo '{"error":"aucune webcam détectée"}'; exit 1; }
    sink=$(find_sink) || { echo '{"error":"aucune caméra virtuelle (v4l2loopback manquant)"}'; exit 1; }
    stop
    sleep 0.2

    if [ "$preset" = "scene" ]; then
        # scène multi-sources (webcam, écrans, images) relue à chaud — le venv IA
        # n'est utile que pour le détourage, sinon le python système suffit
        local py="$AIVENV/bin/python"
        [ -x "$py" ] || py=python3
        LD_LIBRARY_PATH="$(ai_libs):${LD_LIBRARY_PATH:-}" \
            setsid "$py" "$HOME/.config/quickshell/catalyst/scripts/cam_scene.py" \
                "$src" "$sink" "$SCENEF" "${XDG_RUNTIME_DIR:-$CACHE}/catalyst-cam-preview.jpg" \
            >/dev/null 2>"$CACHE/cam-scene.log" &
        echo $! >"$PIDF"
        write_state true "$preset" "$sink"
        echo "{\"ok\":true,\"preset\":\"$preset\",\"sink\":\"$sink\"}"
        return 0
    fi

    if [ "$preset" = "aianime" ]; then
        # filtre IA (AnimeGANv3 sur GPU) — process Python dédié
        local py="$AIVENV/bin/python"
        if [ ! -x "$py" ]; then echo '{"error":"IA non installée (venv manquant)"}'; exit 1; fi
        LD_LIBRARY_PATH="$(ai_libs):${LD_LIBRARY_PATH:-}" \
            setsid "$py" "$HOME/.config/quickshell/catalyst/scripts/cam_anime.py" "$src" "$sink" \
            >/dev/null 2>&1 &
        echo $! >"$PIDF"
        write_state true "$preset" "$sink"
        echo "{\"ok\":true,\"preset\":\"$preset\",\"sink\":\"$sink\"}"
        return 0
    fi

    if [ "$preset" = "bgblur" ] || [ "$preset" = "bgimage" ]; then
        # détourage IA (sans fond vert) : fond flou ou remplacé par l'image choisie
        local py="$AIVENV/bin/python"
        if [ ! -x "$py" ]; then echo '{"error":"IA non installée (venv manquant)"}'; exit 1; fi
        local mode="blur" bgarg=""
        if [ "$preset" = "bgimage" ]; then mode="image"; bgarg=$(cam_image); fi
        LD_LIBRARY_PATH="$(ai_libs):${LD_LIBRARY_PATH:-}" \
            setsid "$py" "$HOME/.config/quickshell/catalyst/scripts/cam_bg.py" \
                "$src" "$sink" "$mode" "$bgarg" \
            >/dev/null 2>&1 &
        echo $! >"$PIDF"
        write_state true "$preset" "$sink"
        echo "{\"ok\":true,\"preset\":\"$preset\",\"sink\":\"$sink\"}"
        return 0
    fi

    if [ "$preset" = "image" ]; then
        # remplace entièrement la webcam par une image fixe (écran BRB / avatar)
        local img; img=$(cam_image)
        if [ -z "$img" ]; then echo '{"error":"aucune image choisie"}'; exit 1; fi
        LC_ALL=C gst-launch-1.0 -q \
            filesrc location="$img" ! decodebin ! imagefreeze ! videoconvert ! videoscale ! \
                "video/x-raw,width=1280,height=720,pixel-aspect-ratio=1/1" ! videoconvert ! \
                "video/x-raw,format=YUY2" ! v4l2sink name=catalystcamsink device="$sink" sync=false \
            >/dev/null 2>&1 &
        echo $! >"$PIDF"
        write_state true "$preset" "$sink"
        echo "{\"ok\":true,\"preset\":\"$preset\",\"sink\":\"$sink\"}"
        return 0
    fi

    if [ "$preset" = "chroma" ]; then
        # fond vert -> remplacé par l'image choisie (compositor). Nécessite un
        # vrai fond vert derrière toi pour un détourage propre.
        local bg; bg=$(cam_image)
        if [ -z "$bg" ]; then echo '{"error":"aucune image de fond"}'; exit 1; fi
        LC_ALL=C gst-launch-1.0 -q \
            filesrc location="$bg" ! decodebin ! imagefreeze ! videoconvert ! videoscale ! \
                video/x-raw,width=1280,height=720 ! comp.sink_0 \
            v4l2src device="$src" ! image/jpeg,width=1280,height=720,framerate=30/1 ! jpegdec ! \
                videoconvert ! alpha method=green ! comp.sink_1 \
            compositor name=comp sink_0::zorder=0 sink_1::zorder=1 ! videoconvert ! \
                video/x-raw,format=YUY2 ! v4l2sink name=catalystcamsink device="$sink" sync=false \
            >/dev/null 2>&1 &
    else
        chain=$(filter_chain "$preset") || { echo "{\"error\":\"preset inconnu : $preset\"}"; exit 1; }
        LC_ALL=C gst-launch-1.0 -q \
            v4l2src device="$src" ! image/jpeg,width=1280,height=720,framerate=30/1 ! jpegdec ! videoconvert ! \
            $chain ! videoconvert ! video/x-raw,format=YUY2 ! \
            v4l2sink name=catalystcamsink device="$sink" sync=false \
            >/dev/null 2>&1 &
    fi
    echo $! >"$PIDF"
    write_state true "$preset" "$sink"
    echo "{\"ok\":true,\"preset\":\"$preset\",\"sink\":\"$sink\"}"
}

case "${1:-}" in
    start)  start "${2:-cyber}" ;;
    stop)   stop; echo '{"ok":true,"on":false}' ;;
    toggle) if running; then stop; echo '{"ok":true,"on":false}'; else start "${2:-cyber}"; fi ;;
    status) if running; then cat "$STATE"; else printf '{"on":false,"sink":"%s","image":"%s"}\n' "$(find_sink || echo "")" "$(cam_image)"; fi ;;
    setimg) [ -n "${2:-}" ] && [ -f "$2" ] && { echo "$2" >"$IMGF"; echo '{"ok":true}'; } || echo '{"error":"image introuvable"}' ;;
    getimg) cam_image ;;
    src)    find_src || echo "" ;;
    sink)   find_sink || echo "" ;;
    presets) echo "scene cyber noir retouch sepia thermal chroma image bgblur bgimage aianime cartoon anime manga comic pixel mirror fisheye kaleid water pixsort distort emboss neon glitch vhs crt matrix" ;;
    *) echo "usage: $0 {start|stop|toggle <preset>|status|src|sink|presets}"; exit 1 ;;
esac
