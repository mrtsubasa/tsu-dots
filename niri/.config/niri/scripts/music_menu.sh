#!/usr/bin/env bash
# music_menu.sh — Musique : transport lecteur, EasyEffects, micro, cava, Spotify.
# Bind: Mod+Alt+M
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

EE_DIR_USER="$HOME/.local/share/easyeffects/presets"
EE_DIR_SYS="/usr/share/easyeffects/output"
MIC_FILE="$HOME/Musique/Enregistrements/mic_$(date +%Y-%m-%d_%H-%M-%S).wav"
MIC_STATE="$HOME/.cache/tools-mic.pid"

current_media() { # "Artiste — Titre" ou vide
    playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null | head -c 120 || true
}

CHOICE="$(
    CUR="$(current_media)"
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰐊  Lecture / Pause" \
        "󰒮  Précédent" \
        "󰒭  Suivant" \
        "󰅉  Reculer 10 s" \
        "󰅔  Avancer 10 s" \
        "󰝚  Choisir le lecteur actif" \
        "󰝟  Preset Easy Effects…" \
        "󰍪  Enregistrement micro (toggle)" \
        "󰜌  Visualiseur cava" \
        "󰓇  Ouvrir Spotify" \
        "󰎆  Info lecture en cours" \
    | tools_pick "󰝚 Musique" "${CUR:-aucune lecture}"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Lecture"*)   playerctl play-pause 2>/dev/null && tools_notify "Musique" "$(current_media || echo toggle)" || tools_notify "Musique" "Aucun lecteur" dialog-warning ;;
    *"Précédent"*) playerctl previous 2>/dev/null || tools_notify "Musique" "Aucun lecteur" dialog-warning ;;
    *"Suivant"*)   playerctl next 2>/dev/null || tools_notify "Musique" "Aucun lecteur" dialog-warning ;;
    *"Reculer"*)   playerctl position 10- 2>/dev/null || true ;;
    *"Avancer"*)   playerctl position 10+ 2>/dev/null || true ;;

    *"Choisir le lecteur"*)
        PLAYERS="$(playerctl -l 2>/dev/null || true)"
        if [ -z "$PLAYERS" ]; then
            tools_notify "Musique" "Aucun lecteur détecté" dialog-warning
            exit 0
        fi
        P="$(printf '%s\n' "$PLAYERS" | tools_pick "Lecteur" "spotify / firefox / vesktop…")"
        [ -z "$P" ] && exit 0
        # playerctl n'a pas de set-default : on mémorise via PLAYERCTLD si dispo, sinon export fichier
        printf '%s' "$P" >"$HOME/.cache/tools-player"
        if have playerctld; then
            playerctld shift 2>/dev/null || true
        fi
        tools_notify "Musique" "Lecteur choisi : $P (utilise -p $P pour les actions)"
        ;;

    *"Easy Effects"*)
        if ! have easyeffects; then
            tools_notify "EasyEffects" "Non installé" dialog-warning
            exit 0
        fi
        PRESETS="$(
            { find "$EE_DIR_USER" -maxdepth 1 -name '*.json' -printf '%f\n' 2>/dev/null | sed 's/\.json$//';
              find "$EE_DIR_SYS" -name '*.json' -printf '%f\n' 2>/dev/null | sed 's/\.json$//'; } \
            | sort -u
        )"
        if [ -z "$PRESETS" ]; then
            tools_notify "EasyEffects" "Aucun preset trouvé" dialog-warning
            exit 0
        fi
        PR="$(printf '%s\n' "$PRESETS" | tools_pick "Preset EasyEffects" "Bundy01 : Bose / Music / Sony / Video")"
        [ -z "$PR" ] && exit 0
        if easyeffects -l "$PR" >/dev/null 2>&1; then
            tools_notify "EasyEffects" "Preset chargé : $PR"
        else
            tools_term "EasyEffects" "easyeffects -l \"$PR\""
        fi
        ;;

    *"micro"*)
        if [ -f "$MIC_STATE" ] && kill -0 "$(cat "$MIC_STATE")" 2>/dev/null; then
            kill -TERM "$(cat "$MIC_STATE")" 2>/dev/null || true
            rm -f "$MIC_STATE"
            sleep 0.3
            tools_notify "Micro" "Enregistrement arrêté" "$MIC_FILE"
        else
            mkdir -p "$(dirname "$MIC_FILE")"
            pw-record --rate 48000 --channels 1 "$MIC_FILE" >/dev/null 2>&1 &
            echo $! >"$MIC_STATE"
            tools_notify "Micro" "Enregistrement démarré → ${MIC_FILE##*/}"
        fi
        ;;

    *"cava"*)
        if ! have cava; then
            tools_notify "cava" "Non installé" dialog-warning
            exit 0
        fi
        setsid alacritty -t cava -e cava >/dev/null 2>&1 &
        ;;

    *"Spotify"*)
        if have spotify; then
            setsid spotify >/dev/null 2>&1 &
        else
            tools_notify "Spotify" "Non installé" dialog-warning
        fi
        ;;

    *"Info"*)
        INFO="$(playerctl metadata --format '{{artist}} - {{title}}  ·  {{album}}  ·  {{position}}/{{mpris:length}}' 2>/dev/null || true)"
        STATUS="$(playerctl status 2>/dev/null || echo '?')"
        tools_notify "Lecture [$STATUS]" "${INFO:-aucune lecture}"
        ;;
esac
