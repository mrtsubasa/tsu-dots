#!/usr/bin/env bash
# Tsubasa Catalyst — miniatures des fonds d'écran (cache local).
#   thumbs.sh <fichier>...   génère ~/.cache/catalyst/thumbs/<md5 du chemin>.jpg
# Images : vipsthumbnail (rapide, décodage réduit). Vidéos : ffmpegthumbnailer.
# Les miniatures existantes plus récentes que la source sont conservées.
set -u
OUT="$HOME/.cache/catalyst/thumbs"
mkdir -p "$OUT"
for f in "$@"; do
    [ -f "$f" ] || continue
    h="$(printf '%s' "$f" | md5sum | cut -c1-32)"
    t="$OUT/$h.jpg"
    [ -s "$t" ] && [ "$t" -nt "$f" ] && { echo "$f"; continue; }
    case "${f,,}" in
    *.mp4|*.webm|*.mkv|*.mov|*.m4v|*.avi)
        ffmpegthumbnailer -i "$f" -o "$t" -s 384 -q 7 >/dev/null 2>&1 ;;
    *)
        vipsthumbnail "$f" --size 384x216 --smartcrop attention -o "$t[Q=82,strip]" >/dev/null 2>&1 \
            || magick "$f[0]" -thumbnail 384x216^ -gravity center -extent 384x216 -quality 82 "$t" >/dev/null 2>&1 ;;
    esac
    [ -s "$t" ] && echo "$f"
done
