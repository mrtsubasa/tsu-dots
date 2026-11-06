#!/bin/bash
# Galerie locale : images et/ou vidéos. Miniatures cachées, daemon choisi par wallpaper.sh.

WALLPAPER_DIRS=("$HOME/.config/quickshell/catalyst/wallpapers")
VIDEOS_DIR="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
[ -z "$VIDEOS_DIR" ] && VIDEOS_DIR="$HOME/Vidéos"
for extra in "$VIDEOS_DIR/Wallpapers" "$HOME/Videos/Wallpapers" "$HOME/Vidéos/Wallpapers"; do
    [ -d "$extra" ] || continue
    dup=0
    for d in "${WALLPAPER_DIRS[@]}"; do
        [ "$d" = "$extra" ] && dup=1
    done
    [ "$dup" = 0 ] && WALLPAPER_DIRS+=("$extra")
done

THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$THUMB_DIR"

is_video() {
    case "${1,,}" in
        *.mp4|*.webm|*.mkv|*.mov|*.avi|*.m4v) return 0 ;;
        *) return 1 ;;
    esac
}

PICK=0
MODE="${1:-}"
if [ "$MODE" = "pick" ]; then
    PICK=1
    MODE="${2:-all}"
fi

case "$MODE" in
    images|image|img) MODE=images ;;
    videos|video|vid|mp4) MODE=videos ;;
    all|both|"") ;;
    *) MODE="" ;;
esac

if [ -z "$MODE" ]; then
    FILTER=$(printf '%s\n' "󰸉 Images" "󰎁 Vidéos" "󰐑 Tout" | rofi -dmenu -p "Galerie" -theme-str '
        window { width: 24%; border-radius: 14px; }
        listview { lines: 3; spacing: 6px; padding: 10px; }
        element { border-radius: 8px; padding: 8px; }
    ') || true
    case "$FILTER" in
        "󰸉 Images") MODE=images ;;
        "󰎁 Vidéos") MODE=videos ;;
        "󰐑 Tout") MODE=all ;;
        *) exit 0 ;;
    esac
fi
[ "$MODE" = "" ] && MODE=all

want_file() {
    if is_video "$1"; then
        [ "$MODE" = "videos" ] || [ "$MODE" = "all" ]
    else
        [ "$MODE" = "images" ] || [ "$MODE" = "all" ]
    fi
}

make_thumb() {
    local src="$1" dest="$2"
    if [ -f "$dest" ] && [ "$dest" -nt "$src" ]; then
        return 0
    fi
    if is_video "$src"; then
        ffmpeg -y -ss 1 -i "$src" -frames:v 1 \
            -vf "scale=280:280:force_original_aspect_ratio=increase,crop=280:280" \
            "$dest" >/dev/null 2>&1 \
            || ffmpeg -y -i "$src" -frames:v 1 \
                -vf "scale=280:280:force_original_aspect_ratio=increase,crop=280:280" \
                "$dest" >/dev/null 2>&1 \
            || return 1
        return 0
    fi
    magick "$src" -thumbnail 280x280^ -gravity center -extent 280x280 "$dest" 2>/dev/null \
        || convert "$src" -thumbnail 280x280^ -gravity center -extent 280x280 "$dest" 2>/dev/null \
        || return 1
}

missing=0
for d in "${WALLPAPER_DIRS[@]}"; do
    [ -d "$d" ] || missing=$((missing + 1))
done
if [ "$missing" -eq "${#WALLPAPER_DIRS[@]}" ]; then
    notify-send "Wallpaper" "Aucun dossier wallpaper trouvé."
    exit 1
fi

mapfile -t FILES < <(
    for d in "${WALLPAPER_DIRS[@]}"; do
        [ -d "$d" ] || continue
        find "$d" -type f -not -path "*_corrupted*" \( \
            -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \
            -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.mov" \
            -o -iname "*.avi" -o -iname "*.m4v" \
        \)
    done | sort
)

FILTERED=()
for img in "${FILES[@]}"; do
    [ -f "$img" ] || continue
    want_file "$img" && FILTERED+=("$img")
done
FILES=("${FILTERED[@]}")

if [ "${#FILES[@]}" -eq 0 ]; then
    if [ "$MODE" = "videos" ]; then
        notify-send "Wallpaper" "Aucune vidéo dans les fonds du rice (ni ~/Vidéos/Wallpapers)."
    else
        notify-send "Wallpaper" "Aucun fond trouvé."
    fi
    exit 1
fi

INPUT_FILE="$(mktemp "${XDG_RUNTIME_DIR:-/tmp}"/wall-rofi.XXXXXX)"
PATHS_FILE="$(mktemp "${XDG_RUNTIME_DIR:-/tmp}"/wall-paths.XXXXXX)"
trap 'rm -f "$INPUT_FILE" "$PATHS_FILE"' EXIT

jobs=0
for img in "${FILES[@]}"; do
    [ -f "$img" ] || continue
    hash=$(printf '%s' "$img" | md5sum | cut -c1-12)
    thumb="$THUMB_DIR/${hash}.png"
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
        make_thumb "$img" "$thumb" &
        jobs=$((jobs + 1))
        if [ "$jobs" -ge 8 ]; then
            wait
            jobs=0
        fi
    fi
done
wait

declare -A USED_LABELS
: >"$INPUT_FILE"
: >"$PATHS_FILE"

for img in "${FILES[@]}"; do
    [ -f "$img" ] || continue
    filename=$(basename "$img")
    parent=$(basename "$(dirname "$img")")
    if is_video "$img"; then
        label="▶ $filename"
    else
        label="$filename"
    fi
    if [ -n "${USED_LABELS[$label]+x}" ]; then
        label="$parent/$label"
    fi
    USED_LABELS["$label"]=1

    hash=$(printf '%s' "$img" | md5sum | cut -c1-12)
    thumb="$THUMB_DIR/${hash}.png"
    icon="$thumb"
    [ -f "$icon" ] || icon="$img"

    printf '%s\0icon\x1f%s\n' "$label" "$icon" >>"$INPUT_FILE"
    printf '%s\n' "$img" >>"$PATHS_FILE"
done

if [ ! -s "$PATHS_FILE" ]; then
    notify-send "Wallpaper" "Aucun fond affichable."
    exit 1
fi

case "$MODE" in
    images) PROMPT="󰸉 Images" ;;
    videos) PROMPT="󰎁 Vidéos" ;;
    *) PROMPT="󰸉 Galerie" ;;
esac

SELECTION=$(rofi -dmenu \
    -p "$PROMPT" \
    -show-icons \
    -sync \
    -format i \
    -input "$INPUT_FILE" \
    -theme-str '
        configuration { show-icons: true; }
        window {
            width: 75%;
            height: 65%;
            border: 2px;
            border-color: #cba6f7;
            border-radius: 12px;
            background-color: #11111b;
        }
        mainbox { background-color: #11111b; }
        inputbar { background-color: #1e1e2e; text-color: #cdd6f4; }
        prompt { text-color: #cba6f7; }
        entry { text-color: #cdd6f4; }
        listview {
            columns: 4;
            lines: 3;
            spacing: 20px;
            padding: 20px;
            fixed-height: true;
            background-color: #11111b;
        }
        element {
            orientation: vertical;
            children: [ element-icon, element-text ];
            border-radius: 8px;
            padding: 10px;
            background-color: #1e1e2e;
            text-color: #cdd6f4;
        }
        element selected {
            background-color: #cba6f7;
            text-color: #11111b;
        }
        element-icon {
            size: 130px;
            horizontal-align: 0.5;
        }
        element-text {
            horizontal-align: 0.5;
            padding-top: 5px;
            text-color: inherit;
        }
    ') || true

[ -z "${SELECTION:-}" ] && exit 0
[[ "$SELECTION" =~ ^[0-9]+$ ]] || exit 0

# rofi -format i is 0-based; sed is 1-based
TARGET=$(sed -n "$((SELECTION + 1))p" "$PATHS_FILE")
[ -f "$TARGET" ] || exit 1

if [ "$PICK" = 1 ]; then
    printf '%s\n' "$TARGET"
    exit 0
fi

~/.config/niri/scripts/wallpaper.sh set "$TARGET"
if is_video "$TARGET"; then
    notify-send "Wallpaper" "Vidéo · $(basename "$TARGET")"
else
    notify-send "Wallpaper" "$(basename "$TARGET")"
fi
