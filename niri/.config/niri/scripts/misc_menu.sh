#!/usr/bin/env bash
# misc_menu.sh — Divers / productivité : notes, historique shell, QR, lancement d'app, info.
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰜯  Note rapide → ~/Notes" \
        "󰆓  Rechercher dans l'historique shell (atuin)" \
        "󰜮  QR code depuis un texte" \
        "󰣀  Lancer une application (fzf)" \
        "󰐊  Exécuter une commande (terminal)" \
        "󰉷  Info système (fastfetch)" \
        "󰌀  Ouvrir les éditeurs / outils…" \
        "󰆲  Traduction du presse-papiers…" \
    | tools_pick "󰊖 Divers"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Note rapide"*)
        TEXT="$(gum input --prompt "Note : " --placeholder "idée, rappel, lien…" 2>/dev/null || true)"
        [ -z "$TEXT" ] && exit 0
        NOTES="$HOME/Notes"
        mkdir -p "$NOTES"
        F="$NOTES/$(date +%Y-%m-%d).md"
        printf '\n## %s\n\n- %s\n' "$(date +%H:%M)" "$TEXT" >>"$F"
        tools_notify "Note" "Ajoutée à ${F##*/}" "$F"
        ;;

    *"historique"*)
        if ! have atuin; then
            tools_notify "Historique" "atuin absent" dialog-warning
            exit 0
        fi
        LINE="$(atuin search --interactive 2>/dev/null | head -n1 || true)"
        [ -z "$LINE" ] && exit 0
        printf '%s' "$LINE" | wl-copy
        tools_notify "Historique" "Commande copiée : ${LINE:0:120}"
        ;;

    *"QR code"*)
        TXT="$(tools_ask "Texte ou URL" "https://")"
        [ -z "$TXT" ] && exit 0
        if have qrencode; then
            GEN="$TXT" tools_term "QR code" 'printf "%s" "$GEN" | qrencode -t UTF8 -o - 2>/dev/null || printf "%s" "$GEN" | qrencode -t ANSIUTF8'
        else
            tools_notify "QR" "qrencode absent" dialog-warning
        fi
        ;;

    *"application"*)
        APPS="$(find /usr/share/applications ~/.local/share/applications -maxdepth 1 -name '*.desktop' -printf '%f\n' 2>/dev/null \
                | sed 's/\.desktop$//' | sort -u)"
        [ -z "$APPS" ] && { tools_notify "Apps" "Aucun .desktop" dialog-warning; exit 0; }
        PICK="$(printf '%s\n' "$APPS" | fzf --height=20 --reverse --prompt='app> ' 2>/dev/null || true)"
        if [ -n "$PICK" ]; then
            setsid gtk-launch "$PICK" >/dev/null 2>&1 || setsid sh -c "$(grep -m1 '^Exec=' /usr/share/applications/"$PICK".desktop 2>/dev/null | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g; s/"/\\"/g')" >/dev/null 2>&1 &
            tools_notify "Lancement" "$PICK"
        fi
        ;;

    *"Exécuter"*)
        CMD="$(tools_ask "Commande" "")"
        [ -z "$CMD" ] && exit 0
        tools_term "Exécution" "$CMD"
        ;;

    *"fastfetch"*)
        tools_term "fastfetch" "fastfetch -c archey"
        ;;

    *"éditeurs"*)
        TOOL="$(printf '%s\n' nvim helix micro krita gimp obs lazygit yazi btop \
                     | while read -r t; do command -v "$t" >/dev/null && echo "$t"; done \
                     | tools_pick "Outil")"
        [ -z "$TOOL" ] && exit 0
        case "$TOOL" in
            nvim|helix|micro|yazi) tools_term "$TOOL" "$TOOL" ;;
            *) setsid "$TOOL" >/dev/null 2>&1 & ;;
        esac
        ;;

    *"Traduction"*)
        exec "$TOOLS_DIR/translate_sel.sh"
        ;;
esac
