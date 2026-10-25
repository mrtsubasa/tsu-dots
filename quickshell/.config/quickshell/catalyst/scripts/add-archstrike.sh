#!/usr/bin/env bash
# Tsubasa Catalyst — ajoute le dépôt ArchStrike (outils de sécurité
# complémentaires de BlackArch). À lancer dans un VRAI terminal, il demande
# ton mot de passe (sudo). Réversible : voir « remove » et la sauvegarde.
#
#   add-archstrike.sh            ajoute la clé, le dépôt, et synchronise
#   add-archstrike.sh all        idem, puis installe TOUT le groupe archstrike
#                                (--needed : saute ce qui est déjà installé)
#   add-archstrike.sh remove     retire le dépôt (laisse les paquets installés)
#
# Sécurité : la clé de signature est téléchargée en HTTPS depuis le domaine
# officiel archstrike.org (authentifié par TLS), pas codée en dur ici. Le
# script affiche son empreinte avant de l'approuver pour que tu la compares
# avec https://archstrike.org/ si tu le souhaites.
set -euo pipefail

CONF=/etc/pacman.conf
KEYURL="https://archstrike.org/keyfile.asc"
MARK_BEGIN="# >>> ArchStrike (Tsubasa Catalyst) >>>"
MARK_END="# <<< ArchStrike (Tsubasa Catalyst) <<<"

need_root() { [ "$(id -u)" -eq 0 ] || exec sudo -- "$0" "$@"; }

remove() {
    need_root "$@"
    if grep -qF "$MARK_BEGIN" "$CONF"; then
        cp "$CONF" "$CONF.catalyst.bak.$(date +%s)"
        sed -i "/$(printf '%s' "$MARK_BEGIN" | sed 's/[][\.*^$/]/\\&/g')/,/$(printf '%s' "$MARK_END" | sed 's/[][\.*^$/]/\\&/g')/d" "$CONF"
        echo "Dépôt ArchStrike retiré de $CONF (sauvegarde créée). Les paquets déjà installés restent."
        pacman -Sy || true
    else
        echo "ArchStrike n'est pas configuré."
    fi
    exit 0
}

[ "${1:-}" = "remove" ] && remove "$@"

INSTALL_ALL=0
[ "${1:-}" = "all" ] && INSTALL_ALL=1

need_root "$@"

if grep -qiE '^\s*\[archstrike\]' "$CONF"; then
    echo "ArchStrike est déjà dans $CONF."
else
    echo "== 1. Clé de signature (téléchargée depuis $KEYURL) =="
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$KEYURL" -o "$tmp/key.asc"
    echo "Empreinte de la clé reçue :"
    gpg --show-keys --with-fingerprint "$tmp/key.asc" | sed -n '1,4p'
    fpr="$(gpg --show-keys --with-colons "$tmp/key.asc" | awk -F: '/^fpr:/{print $10; exit}')"
    [ -n "$fpr" ] || { echo "Impossible de lire l'empreinte — abandon."; exit 1; }
    echo
    read -rp "Approuver cette clé et continuer ? [o/N] " ans
    [ "$ans" = "o" ] || [ "$ans" = "O" ] || { echo "Annulé."; exit 1; }

    pacman-key --add "$tmp/key.asc"
    pacman-key --lsign-key "$fpr"

    echo "== 2. Vérification d'un miroir joignable =="
    MIRRORS=(
        "https://mirror.archstrike.org/\$arch/\$repo"
        "https://mirrors.dotsrc.org/archstrike/\$arch/\$repo"
        "https://ftp.halifax.rwth-aachen.de/archstrike/\$arch/\$repo"
    )
    GOOD=""
    for m in "${MIRRORS[@]}"; do
        test="${m//\$arch/x86_64}"; test="${test//\$repo/archstrike}/archstrike.db"
        if curl -fsI --connect-timeout 8 -m 15 "$test" >/dev/null 2>&1; then GOOD="$m"; break; fi
    done
    if [ -z "$GOOD" ]; then
        echo "Aucun miroir ArchStrike ne répond : le dépôt est actuellement"
        echo "indisponible (projet en sommeil). Rien n'a été modifié."
        exit 1
    fi
    echo "Miroir joignable : $GOOD"
    echo "== 3. Ajout du dépôt dans $CONF =="
    cp "$CONF" "$CONF.catalyst.bak.$(date +%s)"
    cat >>"$CONF" <<EOF

$MARK_BEGIN
[archstrike]
Server = $GOOD
$MARK_END
EOF
fi

echo "== 4. Synchronisation =="
if ! pacman -Sy; then
    echo "La synchronisation a échoué — retrait automatique du dépôt pour ne"
    echo "pas bloquer pacman."
    "$0" remove
    exit 1
fi
# bascule sur la mirrorlist officielle si le paquet existe
if pacman -Si archstrike-mirrorlist >/dev/null 2>&1; then
    pacman -S --noconfirm archstrike-keyring archstrike-mirrorlist || true
    if [ -f /etc/pacman.d/archstrike-mirrorlist ]; then
        sed -i "s#^Server = https://mirror.archstrike.org.*#Include = /etc/pacman.d/archstrike-mirrorlist#" "$CONF"
        pacman -Sy
    fi
fi

if [ "$INSTALL_ALL" -eq 1 ]; then
    echo "== 5. Installation de TOUT le groupe archstrike =="
    mapfile -t PKGS < <(pacman -Sg archstrike 2>/dev/null | awk '{print $2}' | sort -u)
    echo "${#PKGS[@]} paquets dans le groupe (ceux déjà installés seront sautés)."
    echo "En cas de conflit, pacman te demandera quoi garder — réponds au choix proposé."
    # --needed : ne réinstalle rien ; on n'utilise PAS --noconfirm pour que tu
    # gardes la main sur les éventuels conflits avec BlackArch.
    pacman -S --needed archstrike || {
        echo
        echo "Certains paquets ont échoué (souvent un conflit avec un équivalent"
        echo "BlackArch déjà installé). Ce n'est pas bloquant : le reste est installé."
    }
    echo "Rouvre l'Arsenal : le catalogue se reconstruit automatiquement."
fi

cat <<'EOF'

ArchStrike est prêt.
  Parcourir ses outils :   pacman -Sg | grep '^archstrike'
  En installer un :        sudo pacman -S <paquet>
  Tout voir dans l'Arsenal : il apparaît automatiquement une fois installé
                             (le catalogue inclut déjà les groupes archstrike-*).
Retirer le dépôt plus tard : add-archstrike.sh remove
EOF
