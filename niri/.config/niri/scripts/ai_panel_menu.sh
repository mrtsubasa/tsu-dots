#!/bin/bash
# ai_panel_menu.sh — Menu IA cliquable (rofi) — prefix + i OU clic sur
# la barre d'état du panel
#   • bascule d'IA d'un clic (le panel rouvre avec la nouvelle)
#   • met à jour toutes les IA (mise + qwen-code)
#   • installe / ajoute / retire des IA du catalogue
#   • édite le catalogue ou les configs MCP
#   • dossier / fond / relance / fermeture
#
# Hooks d'automatisation (tests / usage en ligne de commande) :
#   AI_ADD_NAME=x AI_ADD_CMD=y   -> ajoute sans dialogue
#   AI_ADD_NOASK=1               -> pas de question « ouvrir maintenant ? »
#   AI_REM_NAME=x                -> retire sans dialogue
#   AI_INSTALL_NAME=x            -> installe sans dialogue
#   AI_NO_GUI=1                  -> aucun zenity (mode non interactif)
#   AI_MENU_SEL="<libellé>"      -> exécute directement cette entrée
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/ai_engines.sh"

PANEL="$HOME/.config/niri/scripts/claude_panel.sh"
PICK="$HOME/.config/niri/scripts/claude_panel_pick.sh"
BGP="$HOME/.config/niri/scripts/claude_panel_bg.sh"
INSTALL_CONF="$HOME/.config/niri/scripts/ai-install.conf"
CONF="$AI_ENGINES_CONF"
EDITOR_BIN="${EDITOR:-nvim}"
ASKPASS="$HOME/.local/bin/cachyos-askpass"
DIR="$(cat "$AI_STATE_DIR/lastdir" 2>/dev/null)"
[ -d "$DIR" ] || DIR="$HOME"
CUR="$(ai_last_engine)"

SEP="──────────────────────────────"
UPD="🔄  Mettre à jour les IA (mise + qwen)"
INS="📦  Installer une IA du catalogue"
ADD="➕  Ajouter une IA (nom + commande)"
REM="➖  Retirer une IA du catalogue"
EDT="📂  Éditer le catalogue (ai-engines.conf)"
MCP="🧩  Éditer une config MCP"
CURSOR="🖱  Curseur (thème + taille)"
FOL="📂  Changer de dossier"
BGI="🎨  Changer le fond du panel"
REL="🔁  Relancer le panel (même IA)"
CLS="✖   Fermer le panel"

# ── Utilitaires ──────────────────────────────────────────────────────
# Thème Silver Wolf — grosses lignes = boutons cliquables à la souris
# comme au clavier (↑↓ filtrer, Entrée/Ou clic gauche = valider).
ROFI_THEME='
    window { width: 36%; border-radius: 14px; background-color: #0f1220;
             border: 2px; border-color: #7b5cff; }
    mainbox { spacing: 8px; padding: 12px; }
    inputbar { children: [ prompt, entry ]; padding: 10px 14px;
               border-radius: 10px; background-color: #161926; spacing: 10px; }
    prompt { text-color: #00e5d8; }
    entry   { placeholder: "filtrer…"; text-color: #cdd6f9; }
    listview { lines: 14; columns: 1; spacing: 6px; fixed-height: false; }
    element { padding: 12px 16px; border-radius: 10px;
              background-color: #161926; text-color: #cdd6f9; }
    element selected { background-color: #7b5cff; text-color: #0a0c16; }
    message { background-color: #0f1220; text-color: #565f89; padding: 6px; }
'

pick() { # $1 = prompt · $2 = message (optionnel) · stdin = entrées
    if [ -n "$2" ]; then
        rofi -dmenu -i -no-custom -p "$1" -mesg "$2" -theme-str "$ROFI_THEME"
    else
        rofi -dmenu -i -no-custom -p "$1" -theme-str "$ROFI_THEME"
    fi
}

notify() {
    printf '\n%s\n' "$1"
    printf 'Entrée pour fermer.'
    read -r _ || true
}

ask() { # ask "texte" -> 0 si oui
    [ -n "$AI_NO_GUI" ] && return 0
    zenity --question --title "Panel IA" --text "$1" 2>/dev/null
}

entry() { # entry "titre" "texte" "défaut" -> affiche la réponse
    [ -n "$AI_NO_GUI" ] && return 1
    local out
    if [ -n "$3" ]; then
        out="$(zenity --entry --title "$1" --text "$2" --entry-text "$3" 2>/dev/null)"
    else
        out="$(zenity --entry --title "$1" --text "$2" 2>/dev/null)"
    fi
    [ -n "$out" ] || return 1
    printf '%s' "$out"
}

term_open() { # lance une commande dans un terminal détaché
    local t
    for t in ghostty foot alacritty kitty wezterm; do
        command -v "$t" >/dev/null 2>&1 || continue
        case "$t" in
            wezterm) setsid -f "$t" start --always-new-process -- "$@" >/dev/null 2>&1 ;;
            *)       setsid -f "$t" -e "$@" >/dev/null 2>&1 ;;
        esac
        return 0
    done
    return 1
}

engine_cmd_in_conf() { # $1 = nom -> commande déclarée dans le catalogue
    [ -f "$CONF" ] || return 0
    awk -F'|' -v n="$1" '$1==n{print substr($0,index($0,"|")+1);exit}' "$CONF"
}

conf_remove() { # retire la ligne « nom| » (awk : pas de regex)
    [ -f "$CONF" ] || return 0
    awk -F'|' -v n="$1" '$1!=n' "$CONF" > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
}

propose_switch() { # $1 = nom d'IA
    [ -n "$AI_NO_GUI" ] || [ -n "$AI_ADD_NOASK" ] && return 0
    if ask "Ouvrir le panel avec $1 maintenant ?"; then
        ai_set_engine "$1"
        setsid -f "$PANEL" --engine "$1" --switch --dir "$DIR" >/dev/null 2>&1
    fi
}

# ── Actions ──────────────────────────────────────────────────────────
add_ai() {
    local name="$1" cmd="$2" first
    [ -n "$name" ] && [ -n "$cmd" ] || return 1
    case "$name" in
        *'|'*|*' '*|*$'\t'*|*$'\n'*)
            notify "❌ Nom invalide : ni espace, ni tab, ni « | »."; return 1 ;;
    esac
    first="${cmd%% *}"
    conf_remove "$name"
    printf '%s|%s\n' "$name" "$cmd" >> "$CONF"
    if command -v "$first" >/dev/null 2>&1; then
        notify "✅ ${name} ajoutée : ${cmd}"
        propose_switch "$name"
    else
        notify "➕ ${name} enregistrée (${cmd}) — masquée tant que « ${first} » n'est pas installée."
    fi
}

install_ai() {
    local name="$1" line icmd ecmd first
    [ -n "$name" ] || return 1
    line="$(awk -F'|' -v n="$name" '$1==n{print;exit}' "$INSTALL_CONF" 2>/dev/null)"
    [ -n "$line" ] || { notify "❌ Pas de commande d'installation pour ${name}. Édite ai-install.conf."; return 1; }
    icmd="${line#*|}"
    ecmd="$(engine_cmd_in_conf "$name")"
    first="${ecmd%% *}"
    [ -n "$first" ] || { notify "❌ ${name} n'est pas dans ai-engines.conf."; return 1; }
    if command -v "$first" >/dev/null 2>&1; then
        notify "✅ ${name} est déjà installée (${first})."
        return 0
    fi
    case "$icmd" in
        "pacman "*)
            printf 'Installation de %s…\n\n' "$name"
            if [ -x "$ASKPASS" ]; then
                SUDO_ASKPASS="$ASKPASS" sudo -A bash -c "$icmd"
            else
                bash -c "$icmd"
            fi ;;
        *)
            printf 'Installation de %s…\n\n' "$name"
            bash -c "$icmd" ;;
    esac
    printf '\n'
    if command -v "$first" >/dev/null 2>&1; then
        notify "✅ ${name} installée (${first})."
        propose_switch "$name"
    else
        notify "⚠️ ${name} : la commande « ${first} » n'est toujours pas visible. Vérifie le message ci-dessus."
    fi
}

rem_ai() {
    local name="$1" list=""
    if [ -z "$name" ]; then
        local line
        while IFS= read -r line; do
            case "$line" in ''|'#'*) continue ;; esac
            list+="${line%%|*}"$'\n'
        done < "$CONF"
        [ -n "$list" ] || return 0
        name="$(printf '%s' "${list%$'\n'}" | pick "➖ retirer" "")"
    fi
    [ -n "$name" ] || return 0
    awk -F'|' -v n="$name" '$1==n{f=1} END{exit !f}' "$CONF" 2>/dev/null \
        || { notify "❌ ${name} introuvable dans le catalogue."; return 1; }
    conf_remove "$name"
    notify "🗑️ ${name} retirée du catalogue (le programme n'est pas désinstallé)."
}

mcp_flow() {
    local files="" f choice
    for f in \
        "$DIR/opencode.json" \
        "$HOME/.config/opencode/opencode.json" \
        "$HOME/.claude.json" \
        "$HOME/.claude/settings.json" \
        "$HOME/.codex/config.toml" \
        "$HOME/.gemini/settings.json" \
        "$HOME/.config/aichat/config.yaml"; do
        [ -f "$f" ] && files+="$f"$'\n'
    done
    if [ -z "$files" ]; then
        notify "Aucune config MCP trouvée. Crée $HOME/.config/opencode/opencode.json (mcpServers)."
        return 0
    fi
    choice="$(printf '%s' "${files%$'\n'}" | pick "🧩 config MCP" "")"
    [ -n "$choice" ] || return 0
    term_open "$EDITOR_BIN" "$choice" || notify "❌ Aucun terminal trouvé."
}

# ── Construction du menu ─────────────────────────────────────────────
rows=""
[ -n "$CUR" ] && rows+="${CUR}"$'\n'
while IFS= read -r line; do
    [ -z "$line" ] && continue
    name="${line%%|*}"
    [ "$name" = "$CUR" ] && continue
    rows+="${name}"$'\n'
done <<EOF
$(ai_engines_available)
EOF
rows+="${SEP}"$'\n'"${UPD}"$'\n'"${INS}"$'\n'"${ADD}"$'\n'"${REM}"$'\n'
rows+="${EDT}"$'\n'"${MCP}"$'\n'"${CURSOR}"$'\n'"${SEP}"$'\n'"${FOL}"$'\n'"${BGI}"$'\n'"${REL}"$'\n'"${CLS}"

sel="${AI_MENU_SEL:-}"
if [ -z "$sel" ]; then
    sel="$(printf '%s' "${rows%$'\n'}" | pick "🤖 ${CUR} ▸" \
        "${DIR/#$HOME/\~}  ·  clic ou Échap")"
fi
[ -n "$sel" ] || exit 0

case "$sel" in
    "$UPD")
        printf 'Mise à jour de toutes les IA…\n\n'
        mise upgrade -g -y 2>&1 || true
        printf '\n\nqwen-code…\n'
        npm install -g --prefix "$HOME/.local/lib/qwen-code" \
            @qwen-code/qwen-code@latest 2>&1 | tail -n 8 || true
        printf '\n\n✅ Terminé. Entrée pour fermer.'
        read -r _ || true
        ;;
    "$INS")
        name="${AI_INSTALL_NAME:-}"
        if [ -z "$name" ]; then
            # propose uniquement celles du catalogue pas encore installées
            list=""
            while IFS= read -r line; do
                case "$line" in ''|'#'*) continue ;; esac
                n="${line%%|*}"
                ecmd="$(engine_cmd_in_conf "$n")"
                [ -n "$ecmd" ] || continue
                first="${ecmd%% *}"
                command -v "$first" >/dev/null 2>&1 && continue
                list+="$n"$'\n'
            done < "$INSTALL_CONF"
            [ -n "$list" ] || { notify "✅ Rien à installer : tout le catalogue installable est déjà présent."; exit 0; }
            name="$(printf '%s' "${list%$'\n'}" | pick "📦 installer" "")"
        fi
        [ -n "$name" ] || exit 0
        ecmd="$(engine_cmd_in_conf "$name")"
        if [ -z "$AI_NO_GUI" ] && [ -z "$AI_INSTALL_NAME" ]; then
            ask "$(printf 'Installer %s ?\n\n%s' "$name" \
                "$(awk -F'|' -v n="$name" '$1==n{print substr($0,index($0,"|")+1)}' "$INSTALL_CONF")")" \
                || exit 0
        fi
        install_ai "$name"
        ;;
    "$ADD")
        name="${AI_ADD_NAME:-}"
        cmd="${AI_ADD_CMD:-}"
        [ -n "$name" ] || name="$(entry "➕ Ajouter une IA" \
            "Nom affiché (sans espace, ex : mon-agent)")" || exit 0
        [ -n "$cmd" ] || cmd="$(entry "Commande de ${name}" \
            "Commande lancée dans le dossier du panel (ex : mon-agent --tui)" "$name")" || exit 0
        add_ai "$name" "$cmd"
        ;;
    "$REM")   rem_ai "${AI_REM_NAME:-}" ;;
    "$EDT")   term_open "$EDITOR_BIN" "$CONF" || notify "❌ Aucun terminal trouvé." ;;
    "$MCP")   mcp_flow ;;
    "$CURSOR") setsid -f "$HOME/.local/bin/cachyos-cursor" menu >/dev/null 2>&1 ;;
    "$FOL")   setsid -f "$PICK" >/dev/null 2>&1 ;;
    "$BGI")   setsid -f "$BGP"  >/dev/null 2>&1 ;;
    "$REL")   setsid -f "$PANEL" --switch --dir "$DIR" >/dev/null 2>&1 ;;
    "$CLS")
        win="$(niri msg --json windows 2>/dev/null \
            | jq -r '.[]|select(.app_id=="claude-panel")|.id' | head -n1)"
        [ -n "$win" ] && niri msg action close-window --id "$win"
        ;;
    *)
        # Une IA connue du catalogue ? (ignore les lignes décoratives)
        [ -n "$(ai_engine_cmd "$sel")" ] || exit 0
        ai_set_engine "$sel"
        setsid -f "$PANEL" --engine "$sel" --switch --dir "$DIR" >/dev/null 2>&1
        ;;
esac
exit 0
