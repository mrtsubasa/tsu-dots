#!/bin/bash
# Wallpaper picker pour gelbooru.com : liste de tags sélectionnable + pagination des résultats

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/gelbooru_preview"
FINAL_DIR="$HOME/.config/quickshell/catalyst/wallpapers/nsfw/Gelbooru"
TAGS_CACHE="${XDG_RUNTIME_DIR:-/tmp}/gelbooru_tags_list.txt"
mkdir -p "$CACHE_DIR" "$FINAL_DIR"
rm -f "$CACHE_DIR"/*

# Clés API Gelbooru (optionnel mais recommandé pour éviter le throttling)
# Récupérables sur : https://gelbooru.com/index.php?page=account&s=options
# À mettre dans ~/.config/catalyst/secrets.env (hors dépôt, chmod 600) :
#   GELBOORU_API_KEY="..."  GELBOORU_USER_ID="..."
SECRETS="$HOME/.config/catalyst/secrets.env"
[ -r "$SECRETS" ] && . "$SECRETS"
API_KEY="${GELBOORU_API_KEY:-}"
USER_ID="${GELBOORU_USER_ID:-}"

AUTH=""
if [ -n "$API_KEY" ] && [ -n "$USER_ID" ]; then
    AUTH="&api_key=${API_KEY}&user_id=${USER_ID}"
fi

LIMIT=12

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

TAGS_THEME='window { width: 40%; height: 55%; }'

# 1. Liste des tags les plus utilisés (cache 24h pour éviter de re-fetch à chaque lancement)
if [ ! -f "$TAGS_CACHE" ] || [ -n "$(find "$TAGS_CACHE" -mmin +1440 2>/dev/null)" ]; then
    notify-send "Gelbooru" "Mise à jour de la liste des tags..."
    curl -s "https://gelbooru.com/index.php?page=dapi&s=tag&q=index&json=1&limit=1000&orderby=count${AUTH}" \
        | jq -r '.tag[]? | "\(.name)\t\(.count)"' \
        | awk -F'\t' '{printf "%-40s (%s)\n", $1, $2}' > "$TAGS_CACHE"
fi

if [ ! -s "$TAGS_CACHE" ]; then
    notify-send "Gelbooru" "Impossible de récupérer la liste des tags."
    exit 1
fi

# 2. Sélection d'un ou plusieurs tags (Shift+Entrée pour cocher plusieurs, sinon Entrée valide)
#    Tu peux aussi taper un tag qui n'est pas dans la liste (recherche fuzzy Rofi native).
TAG_SELECTION=$(rofi -dmenu -i -multi-select \
    -p " Tags Gelbooru" \
    -mesg "Tab/Shift+Entrée = multi-sélection · tape aussi un tag libre" \
    -theme-str "$TAGS_THEME" < "$TAGS_CACHE")

[ -z "$TAG_SELECTION" ] && exit 0

# Ne garde que le nom du tag (avant le padding / le compteur entre parenthèses)
TAGS_URL=$(echo "$TAG_SELECTION" | awk '{print $1}' | paste -sd'+' -)

PAGE=1

while true; do
    notify-send "Gelbooru" "Récupération page $PAGE ($TAGS_URL)..."

    # Gelbooru pagine avec "pid" (0-indexé)
    PID=$((PAGE - 1))
    JSON_DATA=$(curl -s "https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&limit=${LIMIT}&pid=${PID}&tags=${TAGS_URL}${AUTH}")

    POST_COUNT=$(echo "$JSON_DATA" | jq '.post | length' 2>/dev/null)
    if [ -z "$JSON_DATA" ] || [ "$POST_COUNT" == "0" ] || [ "$POST_COUNT" == "null" ]; then
        if [ "$PAGE" -gt 1 ]; then
            notify-send "Gelbooru" "Fin de la pagination, retour à la page précédente."
            PAGE=$((PAGE - 1))
            continue
        fi
        notify-send "Gelbooru" "Aucun résultat pour : $TAGS_URL"
        exit 1
    fi

    rm -f "$CACHE_DIR"/*
    unset ID_TO_URL
    declare -A ID_TO_URL
    ROFI_INPUT=""

    while IFS=$'\t' read -r id preview_url file_url; do
        [ -z "$id" ] && continue

        case "$preview_url" in
            http*) ;;
            //*) preview_url="https:${preview_url}" ;;
            *)   preview_url="https://gelbooru.com/${preview_url}" ;;
        esac

        ext="${file_url##*.}"
        case "$ext" in
            webm|mp4) continue ;;
        esac

        preview_ext="${preview_url##*.}"
        preview_path="$CACHE_DIR/${id}.${preview_ext}"

        ID_TO_URL[$id]="$file_url"
        curl -s "$preview_url" -o "$preview_path" &
        ROFI_INPUT+="${id}\x00icon\x1f${preview_path}\n"
    done < <(echo "$JSON_DATA" | jq -r '.post[] | "\(.id)\t\(.preview_url)\t\(.file_url)"')

    wait

    NAV=""
    [ "$PAGE" -gt 1 ] && NAV+="◀ Page précédente\n"
    NAV+="▶ Page suivante\n"
    NAV+="🔍 Nouvelle recherche de tags\n"

    SELECTION=$(echo -e "${NAV}${ROFI_INPUT}" | rofi -dmenu \
        -p "󰸉 Gelbooru : $TAGS_URL [page $PAGE]" \
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
        "🔍 Nouvelle recherche de tags")
            exec "$0"
            ;;
        *)
            FINAL_URL="${ID_TO_URL[$SELECTION]}"
            ext="${FINAL_URL##*.}"
            FINAL_PATH="$FINAL_DIR/${SELECTION}.${ext}"

            notify-send "Gelbooru" "Téléchargement du wallpaper HD..."
            curl -s "$FINAL_URL" -o "$FINAL_PATH"

            if [ -f "$FINAL_PATH" ]; then
        ~/.config/niri/scripts/wallpaper.sh set "$FINAL_PATH"
                notify-send "Wallpaper" "Fond d'écran Gelbooru appliqué !"
            else
                notify-send "Erreur" "Échec du téléchargement HD."
            fi
            exit 0
            ;;
    esac
done
