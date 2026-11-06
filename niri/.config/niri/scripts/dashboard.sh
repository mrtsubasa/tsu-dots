#!/usr/bin/env bash

# --- 1. RÉCUPÉRATION DES ÉTATS ---
# Volume
VOL=$(pamixer --get-volume-human 2>/dev/null || echo "N/A")
if [ "$VOL" = "muted" ]; then VOL_ICON="󰝟"; else VOL_ICON="󰕾"; fi

# Wi-Fi
WIFI_STATUS=$(nmcli radio wifi)
if [ "$WIFI_STATUS" = "enabled" ]; then WIFI_ICON="󰖩"; WIFI_TEXT="Wi-Fi (Actif)"; else WIFI_ICON="󰖪"; WIFI_TEXT="Wi-Fi (Inactif)"; fi

# Bluetooth
BT_STATUS=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
if [ "$BT_STATUS" = "yes" ]; then BT_ICON="󰂯"; BT_TEXT="Bluetooth (Actif)"; else BT_ICON="󰂲"; BT_TEXT="Bluetooth (Inactif)"; fi

# --- 2. CONFIGURATION DE L'AFFICHAGE ROFI ---
MENU_OPTIONS="$VOL_ICON  Volume ($VOL)\n$WIFI_ICON  $WIFI_TEXT\n$BT_ICON  $BT_TEXT\n󰌾  Verrouiller l'écran\n󰗼  Déconnexion\n󰐥  Éteindre le PC"

# Lancement de Rofi avec un style compact (type dmenu)
CHOICE=$(echo -e "$MENU_OPTIONS" | rofi -dmenu -i -p "󰣇 Control Center" -theme ~/.config/rofi/dashboard.rasi)

# --- 3. ACTIONS ---
case "$CHOICE" in
    *Volume*)
        # Ouvre un prompt rapide pour changer le volume ou lance pavucontrol
        "$HOME/.config/niri/scripts/audio-panel.sh"
        ;;
    *Wi-Fi*)
        if [ "$WIFI_STATUS" = "enabled" ]; then nmcli radio wifi off; else nmcli radio wifi on; fi
        exec "$0" # Relance le menu pour voir le changement d'état
        ;;
    *Bluetooth*)
        if [ "$BT_STATUS" = "yes" ]; then bluetoothctl power off; else bluetoothctl power on; fi
        exec "$0"
        ;;
    *Verrouiller*)
        loginctl lock-session || swaylock
        ;;
    *Déconnexion*)
        loginctl terminate-user "$USER"
        ;;
    *Éteindre*)
        poweroff
        ;;
esac