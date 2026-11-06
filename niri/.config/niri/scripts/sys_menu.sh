#!/usr/bin/env bash
# sys_menu.sh — Informatique / système : mise à jour, disque, services, process, réseau.
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰏕  Mettre à jour le système" \
        "󰆴  Nettoyer les paquets" \
        "󰝤  Analyse disque (dua)" \
        "󰣇  Services systemd en échec" \
        "󰌳  Journal des erreurs" \
        "󰈳  Ports ouverts" \
        "󰆠  Tuer un processus" \
        "󰋉  Santé des disques (smartctl)" \
        "󰇪  Miroirs Arch (reflector)" \
        "󰉖  Sauvegarde rsync (Documents → backup)" \
        "󰩠  IP publique → presse-papiers" \
    | tools_pick "󰋃 Informatique"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Mettre à jour"*)
        tools_term "Mise à jour" "cachyos-update"
        ;;

    *"Nettoyer"*)
        tools_confirm "Nettoyer le cache (paccache -rk2), les orphelins et les Flatpak inutiles ?" || exit 0
        tools_term "Nettoyage" \
            "sudo paccache -rk2; echo; echo '── Orphelins ──'; \
orph=\$(pacman -Qtdq 2>/dev/null); if [ -n \"\$orph\" ]; then echo \"\$orph\"; sudo pacman -Rns \$orph; else echo 'aucun orphelin'; fi; \
echo; echo '── Flatpak ──'; flatpak uninstall --unused -y 2>/dev/null || echo 'rien à faire'"
        ;;

    *"Analyse disque"*)
        tools_term "Analyse disque" "dua i ~"
        ;;

    *"Services"*)
        tools_term "Services" "systemctl --failed --no-pager; echo; systemctl list-units --state=failed --no-pager | head -40"
        ;;

    *"Journal"*)
        tools_term "Journal erreurs" "journalctl -p err -b --no-pager | tail -n 80"
        ;;

    *"Ports"*)
        tools_term "Ports ouverts" "ss -tulpn"
        ;;

    *"Tuer"*)
        LINE="$(
            ps -eo pid,pcpu,pmem,comm --sort=-pcpu | tail -n +2 | head -n 40 \
            | awk '{printf "%-7s %5s%% %5s%%  %s\n", $1, $2, $3, $4}' \
            | tools_pick "Tuer un processus" "PID · CPU · MEM · nom"
        )"
        [ -z "$LINE" ] && exit 0
        PID="$(awk '{print $1}' <<<"$LINE")"
        NAME="$(awk '{print $NF}' <<<"$LINE")"
        tools_confirm "Envoyer SIGTERM à $NAME (PID $PID) ?" || exit 0
        kill -TERM "$PID" 2>/dev/null && tools_notify "Processus" "$NAME ($PID) signalé" \
            || tools_notify "Processus" "Échec pour $PID"
        ;;

    *"Santé"*)
        DEVS="$(lsblk -dn -o NAME,TYPE,MODEL,SIZE 2>/dev/null | awk '$2=="disk" {print $1"  "$4"  "$3}')"
        [ -z "$DEVS" ] && { tools_notify "Santé disques" "Aucun disque détecté"; exit 0; }
        DEV="$(printf '%s\n' "$DEVS" | tools_pick "Disque")"
        [ -z "$DEV" ] && exit 0
        DEV="$(awk '{print $1}' <<<"$DEV")"
        tools_term "Santé /dev/$DEV" \
            "if [ -r /dev/$DEV ]; then smartctl -H -A /dev/$DEV; else echo 'sudo nécessaire :'; sudo smartctl -H -A /dev/$DEV; fi"
        ;;

    *"Miroirs"*)
        tools_confirm "Régénérer mirrorlist (20 meilleurs, tri par débit) ?" || exit 0
        tools_term "Reflector" "sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist && echo OK"
        ;;

    *"Sauvegarde"*)
        DEST="$(tools_ask "Destination rsync" "$HOME/backup/$(date +%F)")"
        [ -z "$DEST" ] && exit 0
        tools_term "Sauvegarde" \
            "mkdir -p '$DEST' && rsync -avh --info=progress2 --delete-excluded \
              --exclude='.cache' --exclude='.local/share/Trash' --exclude='node_modules' \
              --exclude='*.part' --exclude='.git' \
              \"$HOME/Documents/\" \"$DEST/Documents/\""
        ;;

    *"IP publique"*)
        IP="$(curl -sS --max-time 5 https://ifconfig.me 2>/dev/null || true)"
        if [ -n "$IP" ]; then
            printf '%s' "$IP" | wl-copy
            tools_notify "Réseau" "IP publique copiée : $IP"
        else
            tools_notify "Réseau" "Impossible de récupérer l'IP" dialog-error
        fi
        ;;
esac
