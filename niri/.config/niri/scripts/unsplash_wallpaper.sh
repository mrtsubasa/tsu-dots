#!/bin/bash
# Recherche Unsplash — photos, grille, applique + palette.

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/unsplash_preview"
FINAL_DIR="$HOME/.config/quickshell/catalyst/wallpapers/sfw/Unsplash"
mkdir -p "$CACHE_DIR" "$FINAL_DIR"

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

QUERY=$(rofi -dmenu -p " Recherche Unsplash" \
    -mesg "city night, mountains, car, forest…  ·  photos libres" \
    -theme-str 'window { width: 42%; }')
[ $? -ne 0 ] && exit 0
QUERY=$(printf '%s' "$QUERY" | tr '\n' ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
[ -z "$QUERY" ] && QUERY="wallpaper"

PAGE=1
QENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")

while true; do
    notify-send "Unsplash" "Recherche page $PAGE…"
    JSON_DATA=$(curl -sA "$UA" \
        -H "Accept-Version: v1" \
        "https://unsplash.com/napi/search/photos?query=${QENC}&per_page=12&page=${PAGE}")
    COUNT=$(echo "$JSON_DATA" | jq '.results | length' 2>/dev/null)
    if [ -z "$JSON_DATA" ] || [ "$COUNT" = "0" ] || [ "$COUNT" = "null" ]; then
        if [ "$PAGE" -gt 1 ]; then
            notify-send "Unsplash" "Fin des résultats."
            PAGE=$((PAGE - 1))
            continue
        fi
        notify-send "Unsplash" "Aucun résultat (API Unsplash peut être limitée)."
        exit 1
    fi

    rm -f "$CACHE_DIR"/*
    unset ID_TO_URL
    declare -A ID_TO_URL
    ROFI_INPUT=""

    while IFS=$'\t' read -r id thumb full author; do
        [ -z "$id" ] && continue
        preview_path="$CACHE_DIR/${id}.jpg"
        ID_TO_URL[$id]="$full"
        curl -sA "$UA" "$thumb" -o "$preview_path" &
        ROFI_INPUT+="${id}  ${author}\x00icon\x1f${preview_path}\n"
    done < <(echo "$JSON_DATA" | jq -r '.results[] | "\(.id)\t\(.urls.small)\t\(.urls.full)\t\(.user.name // "unsplash")"')

    wait

    NAV=""
    [ "$PAGE" -gt 1 ] && NAV+="◀ Page précédente\n"
    NAV+="▶ Page suivante\n"
    NAV+="🔍 Nouvelle recherche\n"

    SELECTION=$(echo -e "${NAV}${ROFI_INPUT}" | rofi -dmenu \
        -p "󰸉 Unsplash : $QUERY [page $PAGE]" \
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
            FINAL_PATH="$FINAL_DIR/${WID}.jpg"
            notify-send "Unsplash" "Téléchargement HD…"
            curl -sA "$UA" "$FINAL_URL" -o "$FINAL_PATH"
            if [ -f "$FINAL_PATH" ]; then
                ~/.config/niri/scripts/wallpaper.sh set "$FINAL_PATH"
                notify-send "Wallpaper" "Unsplash appliqué"
            else
                notify-send "Erreur" "Échec du téléchargement."
            fi
            exit 0
            ;;
    esac
done
