#!/usr/bin/env bash
# audio_conv.sh — Conversion audio : format, normalisation EBU, découpe, extraire de la vidéo.
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

AUD_FILTER='Audio et vidéo | *.mp3 *.flac *.wav *.ogg *.opus *.m4a *.aac *.webm *.mp4 *.mkv *.mov'

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰝟  Convertir le format (ff / lame / sox)" \
        "󰊤  Normaliser le volume (loudnorm)" \
        "󰅄  Découper un extrait (début/fin)" \
        "󰉖  Extraire l'audio d'une vidéo" \
        "󰜡  Analyser le volume (ebur128)" \
        "󰋃  Convertir plusieurs fichiers (batch)" \
    | tools_pick "󰝚 Audio"
)"

[ -z "$CHOICE" ] && exit 0

SRC=""
pick_audio() {
    SRC="$(tools_pick_file "$AUD_FILTER" "$1")"
    [ -z "$SRC" ] && exit 0
}

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Convertir le format"*)
        pick_audio "Fichier audio source"
        FMT="$(printf '%s\n' mp3 flac wav ogg opus m4a | tools_pick "Format cible" "Source : ${SRC##*/}")"
        [ -z "$FMT" ] && exit 0
        DST="${SRC%.*}.$FMT"
        [ "$DST" = "$SRC" ] && DST="${SRC%.*}_out.$FMT"
        case "$FMT" in
            mp3)  ARGS="-c:a libmp3lame -q:a 0" ;;
            flac) ARGS="-c:a flac" ;;
            wav)  ARGS="-c:a pcm_s16le" ;;
            ogg)  ARGS="-c:a libvorbis -q:a 6" ;;
            opus) ARGS="-c:a libopus -b:a 128k" ;;
            m4a)  ARGS="-c:a aac -b:a 256k" ;;
        esac
        tools_term "Conversion audio" "ffmpeg -y -i \"$SRC\" $ARGS \"$DST\" && echo OK: \"$DST\""
        ;;

    *"Normaliser"*)
        pick_audio "Fichier à normaliser"
        DST="${SRC%.*}_norm.${SRC##*.}"
        tools_term "Normalisation" \
            "ffmpeg -y -i \"$SRC\" -af loudnorm=I=-16:TP=-1.5:LRA=11 -c:a libmp3lame -q:a 0 \"$DST\" 2>&1 | tail -25; echo OK: \"$DST\""
        ;;

    *"Découper"*)
        pick_audio "Fichier à découper"
        START="$(tools_ask "Début (ex: 00:00:10)" "00:00:00")"
        [ -z "$START" ] && exit 0
        DUR="$(tools_ask "Durée (ex: 00:00:30)" "00:00:30")"
        [ -z "$DUR" ] && exit 0
        DST="${SRC%.*}_clip.${SRC##*.}"
        tools_term "Découpe" "ffmpeg -y -ss $START -t $DUR -i \"$SRC\" -c copy \"$DST\" && echo OK: \"$DST\""
        ;;

    *"Extraire"*)
        pick_audio "Vidéo source"
        DST="${SRC%.*}.m4a"
        [ "$DST" = "$SRC" ] && DST="${SRC%.*}_audio.m4a"
        tools_term "Extraction audio" "ffmpeg -y -i \"$SRC\" -vn -c:a copy \"$DST\" && echo OK: \"$DST\""
        ;;

    *"Analyser"*)
        pick_audio "Fichier à analyser"
        tools_term "ebur128" "ffmpeg -i \"$SRC\" -af ebur128 -f null - 2>&1 | tail -30"
        ;;

    *"batch"*)
        DIR="$(zenity --file-selection --directory --title='Dossier audio source' 2>/dev/null || true)"
        [ -z "$DIR" ] && exit 0
        FMT="$(printf '%s\n' mp3 flac wav | tools_pick "Format cible (tout le dossier)")"
        [ -z "$FMT" ] && exit 0
        tools_term "Batch $FMT" \
            "find \"$DIR\" -maxdepth 1 -type f \\( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.flac' -o -iname '*.ogg' -o -iname '*.m4a' -o -iname '*.opus' \\) -print0 | \
             while IFS= read -r -d '' f; do ffmpeg -y -i \"\$f\" -c:a \"$(case $FMT in mp3) echo libmp3lame;; flac) echo flac;; wav) echo pcm_s16le;; esac)\" \"\${f%.*}.$FMT\" && echo \"✓ \${f##*/}\"; done"
        ;;
esac
