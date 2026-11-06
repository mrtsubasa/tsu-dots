#!/bin/bash
# Recherche de wallpapers Wallhaven — grille type Pinterest, pagination, applique + palette.

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/wallhaven_preview"
FINAL_DIR="$HOME/.config/quickshell/catalyst/wallpapers/sfw/Wallhaven"
mkdir -p "$CACHE_DIR" "$FINAL_DIR"

LIMIT=12
UA="Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0"

GRID_THEME='
    window {
        width: 75%;
        height: 65%;
        border: 2px;
        border-color: #cba6f7;
        border-radius: 12px;
        background-color: #11111b;
    }
    listview {
        columns: 4;
        lines: 3;
        spacing: 20px;
        padding: 20px;
        fixed-height: true;
    }
    element {
        orientation: vertical;
        border-radius: 8px;
        padding: 10px;
        background-color: #1e1e2e;
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
        font-size: 10px;
    }
'

QUERY=$(rofi -dmenu -p " Recherche Wallhaven" \
    -mesg "Paysage, tokyo night, cyberpunk, mountains…  ·  vide = populaires" \
    -theme-str 'window { width: 42%; }')
[ $? -ne 0 ] && exit 0
QUERY=$(printf '%s' "$QUERY" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

CAT_CHOICE=$(printf '%s\n' \
    "Tous" \
    "Général" \
    "Anime" \
    "Photos" \
    | rofi -dmenu -p " Catégorie" -theme-str 'window { width: 28%; } listview { lines: 4; }')
[ -z "$CAT_CHOICE" ] && exit 0
case "$CAT_CHOICE" in
    Général) CATS="100" ;;
    Anime) CATS="010" ;;
    Photos) CATS="001" ;;
    *) CATS="111" ;;
esac

SORT_CHOICE=$(printf '%s\n' \
    "Pertinence" \
    "Favoris" \
    "Récents" \
    "Aléatoire" \
    | rofi -dmenu -p " Tri" -theme-str 'window { width: 28%; } listview { lines: 4; }')
[ -z "$SORT_CHOICE" ] && exit 0
case "$SORT_CHOICE" in
    Favoris) SORT="favorites" ;;
    Récents) SORT="date_added" ;;
    Aléatoire) SORT="random" ;;
    *) SORT="relevance" ;;
esac
[ -z "$QUERY" ] && [ "$SORT" = "relevance" ] && SORT="toplist"

PAGE=1
QENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")

while true; do
    notify-send "Wallhaven" "Recherche page $PAGE…"
    URL="https://wallhaven.cc/api/v1/search?q=${QENC}&categories=${CATS}&purity=100&atleast=1920x1080&sorting=${SORT}&page=${PAGE}"
    JSON_DATA=$(curl -sA "$UA" "$URL")
    COUNT=$(echo "$JSON_DATA" | jq '.data | length' 2>/dev/null)
    if [ -z "$JSON_DATA" ] || [ "$COUNT" = "0" ] || [ "$COUNT" = "null" ]; then
        if [ "$PAGE" -gt 1 ]; then
            notify-send "Wallhaven" "Fin des résultats."
            PAGE=$((PAGE - 1))
            continue
        fi
        notify-send "Wallhaven" "Aucun résultat."
        exit 1
    fi

    rm -f "$CACHE_DIR"/*
    unset ID_TO_URL
    declare -A ID_TO_URL
    ROFI_INPUT=""

    while IFS=$'\t' read -r id thumb full res; do
        [ -z "$id" ] && continue
        ext="${full##*.}"
        case "$ext" in
            webm|mp4) continue ;;
        esac
        preview_path="$CACHE_DIR/${id}.jpg"
        ID_TO_URL[$id]="$full"
        curl -sA "$UA" "$thumb" -o "$preview_path" &
        ROFI_INPUT+="${id}  ${res}\x00icon\x1f${preview_path}\n"
    done < <(echo "$JSON_DATA" | jq -r '.data[] | "\(.id)\t\(.thumbs.small)\t\(.path)\t\(.resolution)"')

    wait

    NAV=""
    [ "$PAGE" -gt 1 ] && NAV+="◀ Page précédente\n"
    NAV+="▶ Page suivante\n"
    NAV+="🔍 Nouvelle recherche\n"

    SELECTION=$(echo -e "${NAV}${ROFI_INPUT}" | rofi -dmenu \
        -p "󰸉 Wallhaven${QUERY:+ : $QUERY} [page $PAGE]" \
        -show-icons \
        -theme-str "$GRID_THEME")

    case "$SELECTION" in
        "")
            exit 0
            ;;
        "▶ Page suivante")
            PAGE=$((PAGE + 1))
            continue
            ;;
        "◀ Page précédente")
            PAGE=$((PAGE - 1))
            continue
            ;;
        "🔍 Nouvelle recherche")
            exec "$0"
            ;;
        *)
            WID="${SELECTION%% *}"
            FINAL_URL="${ID_TO_URL[$WID]}"
            [ -z "$FINAL_URL" ] && exit 1
            ext="${FINAL_URL##*.}"
            FINAL_PATH="$FINAL_DIR/${WID}.${ext}"
            notify-send "Wallhaven" "Téléchargement HD…"
            curl -sA "$UA" "$FINAL_URL" -o "$FINAL_PATH"
            if [ -f "$FINAL_PATH" ]; then
                ~/.config/niri/scripts/wallpaper.sh set "$FINAL_PATH"
                notify-send "Wallpaper" "Wallhaven appliqué"
            else
                notify-send "Erreur" "Échec du téléchargement."
            fi
            exit 0
            ;;
    esac
done
