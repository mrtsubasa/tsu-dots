#!/bin/bash
chosen=$(cliphist list 2>/dev/null | rofi -dmenu -i -p "󰅌 Clipboard" -theme-str '
    window { width: 46%; border-radius: 14px; }
    listview { lines: 14; }
    entry { placeholder: "Rechercher…"; }
')
[ -n "$chosen" ] && echo "$chosen" | cliphist decode | wl-copy
