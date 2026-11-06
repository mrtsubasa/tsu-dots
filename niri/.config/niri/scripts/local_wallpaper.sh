#!/bin/bash
# Configuration
WALL_DIR="$HOME/.config/quickshell/catalyst/wallpapers"
CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/wallpaper_preview"
mkdir -p "$CACHE_DIR"

# Extensions supportées
EXTENSIONS="jpg|jpeg|png|webp|gif"

# Récupère tous les wallpapers récursivement
mapfile -t WALLS < <(find "$WALL_DIR" -type f | grep -iE "\.(${EXTENSIONS})$" | sort)

if [ ${#WALLS[@]} -eq 0 ]; then
    notify-send "Wallpaper Picker" "Aucun wallpaper trouvé dans $WALL_DIR"
    exit 1
fi

notify-send "Wallpaper Picker" "${#WALLS[@]} wallpapers trouvés..."

# Construit l'entrée Rofi avec miniatures cachées
ROFI_INPUT=""
declare -A PATH_TO_FILE

for WALL in "${WALLS[@]}"; do
    FILENAME=$(basename "$WALL")
    # Hash du chemin complet pour éviter les collisions de noms
    HASH=$(echo "$WALL" | md5sum | cut -c1-8)
    THUMB="$CACHE_DIR/${HASH}.png"

    # Génère la miniature si elle n'existe pas encore
    if [ ! -f "$THUMB" ]; then
        convert "$WALL" -thumbnail 200x200^ -gravity center -extent 200x200 "$THUMB" 2>/dev/null &
    fi

    # Clé = nom affiché dans Rofi
    LABEL="${FILENAME%.*}"
    PATH_TO_FILE["$LABEL"]="$WALL"
    ROFI_INPUT+="${LABEL}\x00icon\x1f${THUMB}\n"
done

# Attendre que toutes les miniatures soient générées
wait

# Affichage Rofi grille
SELECTION=$(echo -e "$ROFI_INPUT" | rofi -dmenu \
    -p "󰸉 Wallpapers locaux" \
    -show-icons \
    -theme-str '
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
    ')

# Application du wallpaper sélectionné
if [ -n "$SELECTION" ]; then
    FINAL_PATH="${PATH_TO_FILE[$SELECTION]}"

    if [ -f "$FINAL_PATH" ]; then
        ~/.config/niri/scripts/wallpaper.sh set "$FINAL_PATH"
        notify-send "Wallpaper" "$(basename "$FINAL_PATH") appliqué !"
    else
        notify-send "Erreur" "Fichier introuvable : $FINAL_PATH"
    fi
fi