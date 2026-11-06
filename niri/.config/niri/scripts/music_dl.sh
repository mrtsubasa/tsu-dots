#!/usr/bin/env bash
# music_dl.sh — Téléchargement audio/vidéo → ~/Musique via yt-dlp (mp3/flac/opus).
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

CLIP="$(wl-paste -n 2>/dev/null | head -c1 | grep -qE '[A-Za-z0-9]' && printf '%s' "$(wl-paste -n | tr -d '\n' | cut -c1-120)" || true)"
URL="$(tools_ask "URL (YouTube, SoundCloud…)" "${CLIP:-}")"
[ -z "$URL" ] && exit 0
printf '%s' "$URL" | grep -qE '^https?://' || { tools_notify "Téléchargement" "URL invalide" dialog-error; exit 1; }

FMT="$(printf '%s\n' "mp3 — 320 kbps" "opus — original" "flac — lossless" | tools_pick "Format audio")"
[ -z "$FMT" ] && exit 0

OUT_DIR="$(tools_ask "Dossier de destination" "$HOME/Musique")"
[ -z "$OUT_DIR" ] && exit 0

case "$FMT" in
    mp3*)   EXTRA="--extract-audio --audio-format mp3 --audio-quality 0" ;;
    opus*)  EXTRA="--extract-audio --audio-format opus" ;;
    flac*)  EXTRA="--extract-audio --audio-format flac" ;;
    *)      EXTRA="" ;;
esac

if have aria2c; then
    DLD="--downloader aria2c --downloader-args 'aria2c:-x8'"
else
    DLD=""
fi

mkdir -p "$OUT_DIR"
ESC_URL="$(printf '%s' "$URL" | sed 's/"/\\"/g')"
tools_term "yt-dlp" \
    "yt-dlp -P \"$OUT_DIR\" --embed-thumbnail --embed-metadata $DLD $EXTRA -- \"$ESC_URL\""
