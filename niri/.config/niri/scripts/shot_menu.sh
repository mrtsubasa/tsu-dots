#!/usr/bin/env bash
# shot_menu.sh — Captures : zone / fenêtre / écran, annotation satty, OCR.
# Bind: Mod+Alt+S
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

SHOT_DIR="$HOME/Images/Screenshots/$(date +%Y-%m-%d)"

save_from_stdin() { # lit un PNG sur stdin -> $SHOT_DIR + clipboard + notif
    mkdir -p "$SHOT_DIR"
    local f
    f="$SHOT_DIR/$(date +Screenshot_%H%M%S).png"
    cat >"$f" || return 1
    wl-copy <"$f"
    tools_notify "Capture" "Sauvegardée + copiée" "$f"
}

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰹞  Zone (sélection)" \
        "󰖯  Fenêtre active" \
        "󰊠  Écran entier" \
        "󰏆  Annoter la dernière capture (satty)" \
        "󰒨  OCR d'une zone → presse-papiers" \
        "󰒩  OCR de la dernière capture" \
        "󰅭  Vidéo : enregistrer (wf-recorder)" \
    | tools_pick "󰹞 Captures"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Zone"*)
        GEOM="$(slurp)" || exit 0
        [ -z "$GEOM" ] && exit 0
        mkdir -p "$SHOT_DIR"
        F="$SHOT_DIR/$(date +Screenshot_%H%M%S).png"
        grim -g "$GEOM" "$F" && wl-copy <"$F" && tools_notify "Capture zone" "Sauvegardée + copiée" "$F" \
            || tools_notify "Capture zone" "Échec" dialog-error
        ;;

    *"Fenêtre"*)
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            GEOM="$(hyprctl activewindow -j 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
            if [ -n "$GEOM" ] && [ "$GEOM" != "null,null nullxnull" ]; then
                mkdir -p "$SHOT_DIR"
                F="$SHOT_DIR/$(date +Screenshot_%H%M%S).png"
                grim -g "$GEOM" "$F" 2>/dev/null \
                    && tools_notify "Capture fenêtre" "Fenêtre active capturée" \
                    || tools_notify "Capture fenêtre" "Échec" dialog-error
                sleep 0.2
                wl-copy <"$F"
                exit 0
            fi
            tools_notify "Capture fenêtre" "Aucune fenêtre active" dialog-error
            exit 0
        fi
        niri msg action screenshot-window >/dev/null 2>&1 \
            && tools_notify "Capture fenêtre" "Fenêtre active capturée" \
            || tools_notify "Capture fenêtre" "Échec" dialog-error
        sleep 0.6
        F="$(tools_last_screenshot)"
        [ -n "$F" ] && wl-copy <"$F"
        ;;

    *"Écran"*)
        mkdir -p "$SHOT_DIR"
        F="$SHOT_DIR/$(date +Screenshot_%H%M%S).png"
        grim "$F" && wl-copy <"$F" && tools_notify "Capture écran" "Sauvegardée + copiée" "$F" \
            || tools_notify "Capture écran" "Échec" dialog-error
        ;;

    *"Annoter"*)
        F="$(tools_last_screenshot)"
        if [ -z "$F" ]; then
            tools_notify "Annotation" "Aucune capture trouvée" dialog-error
            exit 0
        fi
        satty --filename "$F" --output-filename "$F" --early-exit >/dev/null 2>&1 &
        ;;

    *"OCR d'une zone"*)
        GEOM="$(slurp)" || exit 0
        [ -z "$GEOM" ] && exit 0
        TMP="$(mktemp --suffix=.png)"
        grim -g "$GEOM" "$TMP" || { tools_notify "OCR" "Capture impossible" dialog-error; exit 0; }
        TEXT="$(tesseract "$TMP" stdout -l eng+spa 2>/dev/null | sed -e 's/[[:space:]]*$//')"
        rm -f "$TMP"
        if [ -z "$TEXT" ]; then
            tools_notify "OCR" "Aucun texte détecté"
            exit 0
        fi
        printf '%s' "$TEXT" | wl-copy
        tools_notify "OCR ($(printf '%s' "$TEXT" | wc -l) lignes)" "$(printf '%s' "$TEXT" | head -c 300)"
        ;;

    *"OCR de la"*)
        F="$(tools_last_screenshot)"
        if [ -z "$F" ]; then
            tools_notify "OCR" "Aucune capture trouvée" dialog-error
            exit 0
        fi
        TEXT="$(tesseract "$F" stdout -l eng+spa 2>/dev/null | sed -e 's/[[:space:]]*$//')"
        if [ -z "$TEXT" ]; then
            tools_notify "OCR" "Aucun texte détecté"
            exit 0
        fi
        printf '%s' "$TEXT" | wl-copy
        tools_notify "OCR" "$(printf '%s' "$TEXT" | head -c 300)"
        ;;

    *"Vidéo"*)
        if pgrep -x wf-recorder >/dev/null 2>&1; then
            pkill -INT -x wf-recorder
            tools_notify "Vidéo" "Enregistrement arrêté (~/Videos)"
        else
            GEOM="$(slurp)" || exit 0
            [ -z "$GEOM" ] && exit 0
            mkdir -p "$HOME/Videos"
            OUT="$HOME/Videos/$(date +capture_%Y-%m-%d_%H-%M-%S).mkv"
            wf-recorder -g "$GEOM" -f "$OUT" >/dev/null 2>&1 &
            tools_notify "Vidéo" "Enregistrement démarré — relance pour arrêter" "$OUT"
        fi
        ;;
esac
