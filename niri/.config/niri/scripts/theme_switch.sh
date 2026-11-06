#!/usr/bin/env bash
set -euo pipefail

APPLY="$HOME/.config/niri/scripts/theme-apply.py"
STYLES_DIR="$HOME/.config/waybar/styles"
RICE_JSON="$HOME/.config/waybar/rice.json"
ASSEMBLE="$HOME/.config/waybar/assemble.py"

notify() { command -v notify-send >/dev/null && notify-send "Rice" "$1" || true; }

pick_theme() {
  local current themes choice
  current="$(python3 "$APPLY" current 2>/dev/null || true)"
  themes="$(python3 "$APPLY" list)"
  [ -n "$themes" ] || { notify "Aucun pack thème"; exit 1; }

  choice="$(
    {
      echo "󰋩 Matugen (depuis wallpaper)"
      echo "── Packs Omarchy ──"
      while IFS= read -r t; do
        if [ "$t" = "$current" ]; then
          echo "● $t"
        else
          echo "  $t"
        fi
      done <<<"$themes"
      echo "── Barre waybar ──"
      if [ -d "$STYLES_DIR" ]; then
        for d in "$STYLES_DIR"/*/; do
          [ -d "$d" ] || continue
          base="$(basename "$d")"
          echo "▢ bar:$base"
        done
      fi
      echo "── Mode ──"
      echo "☀ Light"
      echo "☾ Dark"
    } | rofi -dmenu -i -p "󰃉 Thème" -theme "${ROFI_THEME:-$HOME/.config/rofi/config.rasi}" \
      -theme-str 'window { width: 32%; } listview { lines: 14; }'
  )"
  [ -z "$choice" ] && exit 0

  case "$choice" in
    *Matugen*)
      WALL="$(readlink -f "$HOME/.cache/matugen/current-wallpaper" 2>/dev/null || true)"
      if [ -n "$WALL" ] && [ -f "$WALL" ]; then
        bash "$HOME/.config/niri/scripts/wallpaper.sh" set "$WALL"
        notify "Matugen ← wallpaper"
      else
        notify "Pas de wallpaper courant — Mod+Shift+W"
      fi
      ;;
    *Light)
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
      command -v plasma-apply-colorscheme >/dev/null && plasma-apply-colorscheme BreezeLight >/dev/null 2>&1 || true
      notify "Mode light"
      ;;
    *Dark)
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
      command -v plasma-apply-colorscheme >/dev/null && plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
      notify "Mode dark"
      ;;
    ▢\ bar:*)
      style="${choice#▢ bar:}"
      style="${style#"${style%%[![:space:]]*}"}"
      if [ -f "$ASSEMBLE" ]; then
        python3 - <<PY
import json, pathlib
p = pathlib.Path("$RICE_JSON")
data = {}
if p.is_file():
    try: data = json.loads(p.read_text())
    except Exception: data = {}
data["style"] = "$style"
p.write_text(json.dumps(data, indent=2) + "\n")
PY
        python3 "$ASSEMBLE" 2>/dev/null || true
        notify "Barre → $style"
      else
        notify "assemble.py introuvable"
      fi
      ;;
    ──*)
      exit 0
      ;;
    *)
      name="$(echo "$choice" | sed -E 's/^[● ]+//; s/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -z "$name" ] && exit 0
      python3 "$APPLY" apply "$name"
      notify "Thème → $name"
      ;;
  esac
}

case "${1:-}" in
  list) python3 "$APPLY" list ;;
  apply)
    shift
    python3 "$APPLY" apply "${1:?theme}" ${2:+--no-wallpaper}
    ;;
  current) python3 "$APPLY" current ;;
  ""|menu|pick) pick_theme ;;
  *)
    echo "Usage: theme_switch.sh [menu|list|apply <name>|current]" >&2
    exit 2
    ;;
esac
