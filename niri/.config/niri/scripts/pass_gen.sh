#!/usr/bin/env bash
# pass_gen.sh — Générateur de mot de passe / passphrase / PIN + QR optionnel (qrencode).
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰌾  Mot de passe aléatoire (openssl)" \
        "󰉪  Passphrase lisible (mots)" \
        "󰏪  Code PIN numérique" \
        "󰜮  UUID" \
        "󰜀  Clé API hex (32 octets)" \
    | tools_pick "󰌾 Générateur"
)"

[ -z "$CHOICE" ] && exit 0

GEN=""
case "$CHOICE" in
    *Retour*)   tools_menu_hub ;;
    *"aléatoire"*)
        LEN="$(tools_ask "Longueur" "24")"
        [[ "$LEN" =~ ^[0-9]+$ ]] || LEN=24
        [ "$LEN" -lt 8 ] && LEN=8
        GEN="$(openssl rand -base64 64 | tr -d 'A-Za-z0-9+/=\n' | head -c "$LEN")"
        ;;
    *"passphrase"*)
        N="$(tools_ask "Nombre de mots (3-8)" "5")"
        [[ "$N" =~ ^[0-9]+$ ]] || N=5
        [ "$N" -lt 3 ] && N=3
        [ "$N" -gt 8 ] && N=8
        WORDLIST=""
        for w in /usr/share/dict/words /usr/share/dict/american-english /usr/share/dict/francais; do
            [ -r "$w" ] && WORDLIST="$w" && break
        done
        if [ -n "$WORDLIST" ]; then
            GEN="$(shuf -n "$N" "$WORDLIST" | tr '\n' '-' | sed 's/-$//;s/^$/erreur/')"
        else
            GEN="$(openssl rand -hex "$((N * 2))" | sed -E 's/([0-9a-f]{6})/\1-/g;s/-$//')"
            tools_notify "Passphrase" "dictionnaire absent — hex par défaut" dialog-warning
        fi
        ;;
    *"PIN"*)
        N="$(tools_ask "Nombre de chiffres" "6")"
        [[ "$N" =~ ^[0-9]+$ ]] || N=6
        GEN="$(od -An -N8 -tu4 </dev/urandom | tr -d ' \n' | head -c "$N")"
        ;;
    *"UUID"*)
        GEN="$(cat /proc/sys/kernel/random/uuid)"
        ;;
    *"Clé API"*)
        GEN="$(openssl rand -hex 32)"
        ;;
esac

[ -z "$GEN" ] && { tools_notify "Générateur" "Aucune sortie"; exit 1; }

printf '%s' "$GEN" | wl-copy

QR="$(
    printf '%s\n' "✔  Copier seulement" "󰜮  Copier + QR (terminal)" | tools_pick "$GEN"
)"
case "$QR" in
    *"QR"*)
        if have qrencode; then
            GEN="$GEN" tools_term "QR code" 'qrencode -t UTF8 -- "$GEN" 2>/dev/null || qrencode -t ANSIUTF8 -- "$GEN"'
        else
            tools_notify "Générateur" "qrencode absent" dialog-warning
        fi
        tools_notify "Générateur" "Copié (${#GEN} caractères)"
        ;;
    *)
        tools_notify "Générateur" "Copié (${#GEN} caractères)"
        ;;
esac
