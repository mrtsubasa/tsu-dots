#!/bin/bash
# Répare la connexion AirPods : AAC, pas de HFP auto, USB BT toujours allumé.
set -euo pipefail

ADDR="74:3F:8E:EF:FA:80"
UDEV_SRC="$HOME/.config/udev/50-intel-bt-no-autosuspend.rules"
UDEV_DST="/etc/udev/rules.d/50-intel-bt-no-autosuspend.rules"
USB_CTRL="/sys/bus/usb/devices/1-5/power/control"

need_sudo=0
if [ -f "$USB_CTRL" ] && [ "$(cat "$USB_CTRL" 2>/dev/null)" != "on" ]; then
    need_sudo=1
fi
if [ ! -f "$UDEV_DST" ]; then
    need_sudo=1
fi

if [ "$need_sudo" = 1 ]; then
    echo "→ Désactive l'autosuspend USB de l'adaptateur Intel (sudo)…"
    sudo tee "$UDEV_DST" >/dev/null <"$UDEV_SRC"
    sudo udevadm control --reload-rules
    sudo udevadm trigger --subsystem-match=usb --attr-match=idVendor=8087 --attr-match=idProduct=0025
    if [ -f "$USB_CTRL" ]; then
        echo on | sudo tee "$USB_CTRL" >/dev/null
    fi
fi

rfkill unblock bluetooth 2>/dev/null || true
rfkill unblock wifi 2>/dev/null || true
bluetoothctl power on >/dev/null 2>&1 || true

echo "→ Recharge WirePlumber…"
systemctl --user restart wireplumber.service
sleep 1.5
rfkill unblock bluetooth 2>/dev/null || true
bluetoothctl power on >/dev/null 2>&1 || true

echo "→ Reconnecte les AirPods…"
bluetoothctl disconnect "$ADDR" >/dev/null 2>&1 || true
sleep 1
bluetoothctl connect "$ADDR"

for _ in $(seq 1 12); do
    if pactl list cards 2>/dev/null | grep -q "bluez_card.74_3F_8E_EF_FA_80"; then
        pactl set-card-profile bluez_card.74_3F_8E_EF_FA_80 a2dp-sink 2>/dev/null || true
        break
    fi
    sleep 0.4
done

sleep 0.4
profile=$(pactl list cards 2>/dev/null | awk '
    $0 ~ /Name: bluez_card.74_3F_8E_EF_FA_80/ {ok=1}
    ok && /Active Profile:/ {print $3; exit}
')
sink=$(pactl get-default-sink 2>/dev/null || true)
echo "Profil : ${profile:-?}  ·  sortie : ${sink:-?}"
notify-send "AirPods" "Profil ${profile:-inconnu}" 2>/dev/null || true
