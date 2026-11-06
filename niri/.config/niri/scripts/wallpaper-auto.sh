#!/bin/bash
INTERVAL="${1:-1800}"
while true; do
    sleep "$INTERVAL"
    ~/.config/niri/scripts/wallpaper.sh random
done
