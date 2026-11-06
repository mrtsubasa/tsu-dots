#!/usr/bin/env bash
# pdf_menu.sh — PDF : fusionner, scinder, pivoter, compresser, extraire texte, protéger.
set -u
TOOLS_DIR="$HOME/.config/niri/scripts"
# shellcheck source=/dev/null
. "$TOOLS_DIR/tools_lib.sh"

PDF_FILTER='PDF | *.pdf'
strip_pdf() { local f="$1"; printf %s "${f%.pdf}"; }

CHOICE="$(
    printf '%s\n' \
        "↩  Retour au hub" \
        "󰘦  Fusionner plusieurs PDF (qpdf)" \
        "󰘤  Scinder un PDF (pages)" \
        "󰓎  Pivoter les pages" \
        "󰆈  Comprimer (gs, qualité écran)" \
        "󰆐  Extraire le texte (pdftotext)" \
        "󰋊  Aperçu / infos (pdfinfo)" \
        "󰈄  Ouvrir dans le lecteur" \
    | tools_pick "󰈄 PDF"
)"

[ -z "$CHOICE" ] && exit 0

case "$CHOICE" in
    *Retour*) tools_menu_hub ;;

    *"Fusionner"*)
        have qpdf || { tools_notify "PDF" "qpdf absent" dialog-warning; exit 1; }
        OUT="$(tools_ask "PDF de sortie" "$HOME/Documents/fusion_$(date +%H%M%S).pdf")"
        [ -z "$OUT" ] && exit 0
        # zenity multi-sélection (séparateur '|')
        SRC="$(zenity --file-selection --multiple --separator='|' \
                --title='Sélectionner les PDF (Ctrl+clic)' --file-filter='PDF | *.pdf' 2>/dev/null || true)"
        [ -z "$SRC" ] && exit 0
        ARGS=""
        IFS='|' read -r -a FILES <<<"$SRC"
        for f in "${FILES[@]}"; do ARGS="$ARGS \"$f\""; done
        tools_term "Fusion PDF" "qpdf --empty --pages $ARGS -- \"$OUT\" && echo OK: \"$OUT\""
        ;;

    *"Scinder"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF source")"
        [ -z "$SRC" ] && exit 0
        RNG="$(tools_ask "Plages (ex: 1-3,5,7-)" "1-")"
        [ -z "$RNG" ] && exit 0
        OUT="$(strip_pdf "$SRC")_split.pdf"
        tools_term "Scission PDF" "qpdf \"$SRC\" --pages . \"$RNG\" -- \"$OUT\" && echo OK: \"$OUT\""
        ;;

    *"Pivoter"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF source")"
        [ -z "$SRC" ] && exit 0
        ANG="$(printf '%s\n' "90 · horaire" "270 · antihoraire" "180 · à l'envers" | tools_pick "Rotation")"
        [ -z "$ANG" ] && exit 0
        case "$ANG" in
            90*)  A=90 ;;
            270*) A=270 ;;
            *)    A=180 ;;
        esac
        OUT="$(strip_pdf "$SRC")_rot${A}.pdf"
        tools_term "Rotation PDF" "qpdf --empty --pages \"$SRC\" 1-z --rotate \"$A\" -- \"$OUT\" && echo OK: \"$OUT\""
        ;;

    *"Comprimer"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF à compresser")"
        [ -z "$SRC" ] && exit 0
        OUT="$(strip_pdf "$SRC")_light.pdf"
        tools_term "Compression PDF" \
            "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"$OUT\" \"$SRC\" && ls -lh \"$SRC\" \"$OUT\""
        ;;

    *"Extraire"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF source")"
        [ -z "$SRC" ] && exit 0
        OUT="$(strip_pdf "$SRC").txt"
        if pdftotext -layout "$SRC" "$OUT" 2>/dev/null; then
            wl-copy <"$OUT"
            tools_notify "PDF" "Texte extrait + copié (${SRC##*/}.txt)" "$OUT"
        else
            tools_notify "PDF" "pdftotext a échoué" dialog-error
        fi
        ;;

    *"infos"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF à inspecter")"
        [ -z "$SRC" ] && exit 0
        tools_term "pdfinfo" "pdfinfo \"$SRC\"; echo; echo '── pages ──'; pdftotext -l 1 -layout \"$SRC\" - | head -40"
        ;;

    *"lecteur"*)
        SRC="$(tools_pick_file "$PDF_FILTER" "PDF à ouvrir")"
        [ -z "$SRC" ] && exit 0
        if have zathura; then
            setsid zathura "$SRC" >/dev/null 2>&1 &
        elif have mupdf; then
            setsid mupdf "$SRC" >/dev/null 2>&1 &
        else
            setsid xdg-open "$SRC" >/dev/null 2>&1 &
        fi
        ;;
esac
