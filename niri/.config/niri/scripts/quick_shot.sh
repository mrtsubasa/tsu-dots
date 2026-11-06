#!/bin/bash
# quick_shot.sh region|full — capture Grim + presse-papiers + notification
# (remplace les binds sh -c de Niri, compat niri/hyprland)
set -u

D="$HOME/Images/Screenshots/$(date +%Y-%m-%d)"
mkdir -p "$D"
F="$D/Screenshot_$(date +%H%M%S).png"

case "${1:-full}" in
    region)
        G="$(slurp)" || exit 0
        [ -z "$G" ] && exit 0
        grim -g "$G" "$F" || exit 1
        ;;
    *)
        grim "$F" || exit 1
        ;;
esac

wl-copy <"$F"
notify-send "Screenshot" "Saved: $F" -i "$F"
