#!/bin/bash
# palette-apply.sh — injecte la palette matugen dans les CSS (waybar + gtk3/gtk4)
# Les couleurs sont inlinées entre marqueurs (GTK ne résout pas les @import).
# Le design hors bloc reste intact et éditable.

COLORS_GTK="$HOME/.config/matugen/templates/gtk-colors.css.resolved"
HOME_DIR="$HOME"

resolve() { # substitue les placeholders matugen déjà résolus depuis colors.css existant
    true
}

# --- GTK 3 + 4 : bloc de @define-color inliné ---
inject_gtk() {
    local css="$1" colors_src="$2"
    [ -f "$css" ] || return 0
    local block
    block=$(sed -n '1,100p' "$colors_src" 2>/dev/null)
    [ -n "$block" ] || return 0

    awk -v block="$block" '
        BEGIN { done=0 }
        /\/\* COLORS:BEGIN/ && !done {
            print "/* COLORS:BEGIN — généré par matugen, ne pas éditer */"
            print block
            print "/* COLORS:END */"
            inblock=1; done=1; next
        }
        /\/\* COLORS:END/ { inblock=0; next }
        inblock { next }
        /@import/ && !done { print "/* COLORS:BEGIN — généré par matugen, ne pas éditer */"; print block; print "/* COLORS:END */"; done=1; next }
        /@import/ && done { next }
        { print }
    ' "$css" >"$css.tmp" && mv "$css.tmp" "$css"
}

# --- WAYBAR : bloc de @define-color inliné dans style.css ---
inject_waybar() {
    local style="$HOME/.config/waybar/style.css"
    local colors="$HOME/.config/waybar/colors.css"
    [ -f "$style" ] && [ -f "$colors" ] || return 0
    if grep -q "COLORS:BEGIN" "$style"; then
        awk -v colors="$(cat "$colors")" '
            /\/\* COLORS:BEGIN/ { inblock=1; print "/* COLORS:BEGIN — généré par matugen, ne pas éditer */"; print colors; print "/* COLORS:END */"; next }
            /\/\* COLORS:END/ { inblock=0; next }
            !inblock { print }
        ' "$style" >"$style.tmp" && mv "$style.tmp" "$style"
    else
        TMP=$(mktemp)
        { echo "/* COLORS:BEGIN — généré par matugen, ne pas éditer */"; cat "$colors"; echo "/* COLORS:END */"; cat "$style"; } >"$TMP"
        mv "$TMP" "$style"
    fi
}

inject_gtk "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/colors.css"
inject_gtk "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/colors.css"
inject_waybar

# SIGUSR2 does a full config reload and aborts the tray instance
# (GLib-GIO g_application_impl_command_line). Touch the live CSS instead
# so reload_style_on_change picks up the new palette.
STYLE_NAME="$(python3 -c '
import json, pathlib
p = pathlib.Path.home() / ".config/waybar/rice.json"
try:
    print(json.loads(p.read_text()).get("style") or "apple")
except Exception:
    print("apple")
' 2>/dev/null || echo apple)"
[ -f "$HOME/.config/waybar/styles/${STYLE_NAME}/style.css" ] && touch "$HOME/.config/waybar/styles/${STYLE_NAME}/style.css"
[ -f "$HOME/.config/waybar/style.css" ] && touch "$HOME/.config/waybar/style.css"
