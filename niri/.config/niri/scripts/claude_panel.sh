#!/bin/bash
# claude_panel.sh — Panel latéral "Silver Wolf" pour les agents IA sous Niri
#
# Usage :
#   claude_panel.sh                 -> toggle le panel (dernière IA + dernier dossier)
#   claude_panel.sh --dir <path>    -> ouvre/toggle l'IA dans <path>
#   claude_panel.sh --switch --dir <path>
#                                   -> bascule le panel vers <path> (ferme l'actuel, rouvre)
#   claude_panel.sh --engine <nom>  -> force un moteur IA (opencode, claude, codex…)
#   claude_panel.sh --pick-engine   -> choisit l'IA via rofi puis ouvre/bascule
#   claude_panel.sh --print-engine  -> affiche l'IA active (nom|commande)
#
# Moteurs : voir ~/.config/niri/scripts/ai-engines.conf (auto-si non installé masqué)
#
# Toggle (sans --switch) :
#   - Panel absent      -> ouvre/ré-attache la session du dossier courant
#   - Panel au 1er plan -> ferme (cache). La conversation reste vivante.
#   - Panel en arrière  -> ramène au premier plan.
#
# Chaque (IA, dossier) = sa propre session tmux = sa propre conversation persistante.
# Le panel s'adapte auto au moniteur focalisé et à l'espace libre du workspace.

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/ai_engines.sh"

APP_ID="claude-panel"
GAP=16
WEZ_CONF="$HOME/.config/wezterm/claude-panel.lua"
TMUX_CONF="$HOME/.config/tmux/claude-panel.conf"
STATE_DIR="$HOME/.cache/claude-panel"
LASTDIR_FILE="$STATE_DIR/lastdir"
mkdir -p "$STATE_DIR"

# ─────────────────────────  ARGS  ─────────────────────────
DIR=""
SWITCH=0
ENGINE=""
PICK_ENGINE=0
PRINT_ONLY=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dir)          DIR="$2"; shift 2 ;;
        --switch)       SWITCH=1; shift ;;
        --engine)       ENGINE="$2"; shift 2 ;;
        --pick-engine)  PICK_ENGINE=1; shift ;;
        --print-engine) PRINT_ONLY=1; shift ;;
        *)              shift ;;
    esac
done
# Dossier par défaut : dernier utilisé, sinon $HOME
[ -z "$DIR" ] && DIR="$(cat "$LASTDIR_FILE" 2>/dev/null)"
[ -z "$DIR" ] && DIR="$HOME"
DIR="${DIR/#\~/$HOME}"
[ -d "$DIR" ] || DIR="$HOME"

# ─────────────────────────  MOTEUR IA  ─────────────────────────
if [ "$PICK_ENGINE" -eq 1 ]; then
    choice="$(ai_pick_engine_rofi)"
    [ -z "$choice" ] && exit 0
    ENGINE="$choice"
fi

if [ -z "$ENGINE" ]; then
    ENGINE="$(ai_last_engine)"
fi
ENGINE_CMD="$(ai_engine_cmd "$ENGINE")"
if [ -z "$ENGINE_CMD" ]; then
    ENGINE="$(ai_engines_available | head -n1 | cut -d'|' -f1)"
    ENGINE_CMD="$(ai_engine_cmd "$ENGINE")"
fi
[ -n "$ENGINE_CMD" ] || exit 1
ai_set_engine "$ENGINE"

if [ "$PRINT_ONLY" -eq 1 ]; then
    printf '%s|%s\n' "$ENGINE" "$ENGINE_CMD"
    exit 0
fi

# Session tmux unique par (IA, dossier) ; « claude » garde l'ancien nom cc<dossier>
eng_slug="$(printf '%s' "$ENGINE" | tr -c 'a-zA-Z0-9' '_')"
dir_slug="$(printf '%s' "$DIR" | tr -c 'a-zA-Z0-9' '_')"
if [ "$ENGINE" = "claude" ]; then
    SESS="cc${dir_slug}"
else
    SESS="cc-${eng_slug}-${dir_slug}"
fi
SESS="${SESS:0:90}"

# ─────────────────────────  TOGGLE / SWITCH  ─────────────────────────
HYPR=0
[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && HYPR=1

if [ "$HYPR" -eq 1 ]; then
    panel_id="$(hyprctl clients -j 2>/dev/null \
        | jq -r --arg a "$APP_ID" '[.[]|select(.class==$a)] | .[0].address // empty')"
    panel_focused="$(hyprctl activewindow -j 2>/dev/null \
        | jq -r --arg a "$APP_ID" '(.class==$a)|tostring')"
else
    windows="$(niri msg --json windows 2>/dev/null)"
    panel_id="$(printf '%s' "$windows" | jq -r --arg a "$APP_ID" \
        'map(select(.app_id==$a)) | .[0].id // empty')"
    panel_focused="$(printf '%s' "$windows" | jq -r --arg a "$APP_ID" \
        'map(select(.app_id==$a)) | .[0].is_focused // false')"
fi

# Changer d'IA doit reloader le panel s'il est déjà ouvert
[ "$PICK_ENGINE" -eq 1 ] && [ -n "$panel_id" ] && SWITCH=1

if [ -n "$panel_id" ] && [ "$SWITCH" -eq 0 ]; then
    # Mode toggle pur
    if [ "$panel_focused" = "true" ]; then
        if [ "$HYPR" -eq 1 ]; then
            hyprctl dispatch "hl.dsp.window.close({ window = \"$panel_id\" })" >/dev/null 2>&1
        else
            niri msg action close-window --id "$panel_id"
        fi
    else
        if [ "$HYPR" -eq 1 ]; then
            hyprctl dispatch "hl.dsp.focus({ window = \"$panel_id\" })" >/dev/null 2>&1
        else
            niri msg action focus-window --id "$panel_id"
        fi
    fi
    exit 0
fi

if [ -n "$panel_id" ] && [ "$SWITCH" -eq 1 ]; then
    # On bascule de dossier : on ferme le panel courant avant de rouvrir
    if [ "$HYPR" -eq 1 ]; then
        hyprctl dispatch "hl.dsp.window.close({ window = \"$panel_id\" })" >/dev/null 2>&1
    else
        niri msg action close-window --id "$panel_id"
    fi
    for _ in $(seq 1 20); do
        if [ "$HYPR" -eq 1 ]; then
            still="$(hyprctl clients -j 2>/dev/null \
                | jq -r --arg a "$APP_ID" '[.[]|select(.class==$a)] | .[0].address // empty')"
        else
            still="$(niri msg --json windows 2>/dev/null \
                | jq -r --arg a "$APP_ID" 'map(select(.app_id==$a)) | .[0].id // empty')"
        fi
        [ -z "$still" ] && break
        sleep 0.05
    done
fi

# Mémorise le dossier choisi
printf '%s\n' "$DIR" > "$LASTDIR_FILE"

# ─────────────────────────  OUVERTURE  ─────────────────────────
read -r -a _CMD <<<"$ENGINE_CMD"
setsid -f env WEZTERM_CONFIG_FILE="$WEZ_CONF" wezterm start \
    --always-new-process \
    --class "$APP_ID" \
    --cwd "$DIR" \
    -- tmux -f "$TMUX_CONF" new-session -A -s "$SESS" -c "$DIR" "${_CMD[@]}" \
    >/dev/null 2>&1

# Attend l'apparition de la fenêtre (max ~3s)
id=""
for _ in $(seq 1 30); do
    if [ "$HYPR" -eq 1 ]; then
        id="$(hyprctl clients -j 2>/dev/null \
            | jq -r --arg a "$APP_ID" '[.[]|select(.class==$a)] | .[0].address // empty')"
    else
        id="$(niri msg --json windows 2>/dev/null \
            | jq -r --arg a "$APP_ID" 'map(select(.app_id==$a)) | .[0].id // empty')"
    fi
    [ -n "$id" ] && break
    sleep 0.1
done
[ -z "$id" ] && exit 0

# Label de la barre d'état : "ia · dossier" (voir @panel_label)
tmux set -t "$SESS" @panel_label "${ENGINE} · ${DIR/#$HOME/\~}" >/dev/null 2>&1 || true

# ─────────────────────────  DIMENSIONNEMENT AUTO  ─────────────────────────
if [ "$HYPR" -eq 1 ]; then
    outW="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | (.width / .scale | round)')"
    outH="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | (.height / .scale | round)')"
    [ -z "$outW" ] || [ "$outW" = "null" ] && outW=1920
    [ -z "$outH" ] || [ "$outH" = "null" ] && outH=1080

    panelW=$(awk -v w="$outW" 'BEGIN{v=int(w*50/100); if(v<640)v=640; if(v>1100)v=1100; print int(v/2)*2}')
    panelH=$(( outH - 2*GAP ))
    moveX=$(( outW - panelW - GAP ))
    moveY=$GAP

    hyprctl dispatch "hl.dsp.focus({ window = \"$id\" })" >/dev/null 2>&1 || true
    sleep 0.05
    hyprctl dispatch "hl.dsp.window.resize({ x = $panelW, y = $panelH, relative = false })" >/dev/null 2>&1 || true
    hyprctl dispatch "hl.dsp.window.move({ x = $moveX, y = $moveY, relative = false })" >/dev/null 2>&1 || true
    exit 0
fi

out="$(niri msg --json focused-output 2>/dev/null)"
outW="$(printf '%s' "$out" | jq -r '.logical.width  // 1920')"
outH="$(printf '%s' "$out" | jq -r '.logical.height // 1080')"

win="$(niri msg --json windows 2>/dev/null)"
init_y="$(printf '%s' "$win" \
    | jq -r --argjson i "$id" '.[]|select(.id==$i)|.layout.tile_pos_in_workspace_view[1] // 54')"
strut=$(awk -v y="$init_y" 'BEGIN{s=int(y-16); print (s<0?0:s)}')

ws="$(printf '%s' "$win" | jq -r --argjson i "$id" '.[]|select(.id==$i)|.workspace_id')"
tiled="$(printf '%s' "$win" | jq -r --argjson i "$id" --argjson w "$ws" \
    '[.[]|select(.workspace_id==$w and .is_floating==false and .id!=$i)]|length')"

# Pas de tuiles -> plus large (l'écran est à lui) ; sinon on épouse
# la colonne libre sans écraser le reste. Largeur arrondie à 2 px.
if [ "${tiled:-0}" -eq 0 ]; then frac=50; else frac=42; fi
panelW=$(awk -v w="$outW" -v f="$frac" \
    'BEGIN{v=int(w*f/100); if(v<640)v=640; if(v>1100)v=1100; print int(v/2)*2}')
panelH=$(( outH - strut - 2*GAP ))
moveX=$(( outW - panelW - GAP ))
moveY=$GAP

niri msg action set-window-width  --id "$id" "$panelW"                  >/dev/null 2>&1
niri msg action set-window-height --id "$id" "$panelH"                  >/dev/null 2>&1
niri msg action move-floating-window --id "$id" -x "$moveX" -y "$moveY" >/dev/null 2>&1
niri msg action focus-window --id "$id"                                 >/dev/null 2>&1
