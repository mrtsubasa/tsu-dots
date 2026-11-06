# tsu greet - What a new terminal prints (Studio → Terminal → Accueil)

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tsu greet"
    echo ""
    echo "Print the terminal greeting: banner, fastfetch and the chosen extra"
    echo "(Pokémon, fortune, cowsay, bonsai). Set from Studio → Terminal,"
    echo "stored in ~/.cache/catalyst/greet.env."
    return 0
fi

# défauts = comportement d'avant (bannière bleue en blocs + fastfetch)
GREET_BANNER=1
GREET_BANNER_COLOR=blue
GREET_BANNER_STYLE=blocks
GREET_ACCENT=""
GREET_FETCH=1
GREET_EXTRA=none
GREET_SHINY=0
GREET_POKEMON=""
GREET_COW=default
[[ -r "$HOME/.cache/catalyst/greet.env" ]] && source "$HOME/.cache/catalyst/greet.env"

_greet_has() { command -v "$1" >/dev/null 2>&1; }

# ---- bannière ----
if [[ "$GREET_BANNER" == 1 ]]; then
    _greet_text="tsu"
    [[ -r "$HOME/.cache/catalyst/banner" ]] && _greet_text="$(<"$HOME/.cache/catalyst/banner")"
    _greet_art=""
    case "$GREET_BANNER_STYLE" in
    slant | small | big) _greet_has figlet && _greet_art="$(figlet -f "$GREET_BANNER_STYLE" -- "$_greet_text" 2>/dev/null)" ;;
    future | pagga) _greet_has toilet && _greet_art="$(toilet -f "$GREET_BANNER_STYLE" -- "$_greet_text" 2>/dev/null)" ;;
    esac

    if [[ -z "$_greet_art" ]]; then
        # style intégré (blocs), toujours disponible
        if [[ "$GREET_BANNER_COLOR" == rainbow ]] && _greet_has lolcat; then
            TSU_BANNER_COLOR=none tsu banner | lolcat -f -F 0.25
        else
            TSU_BANNER_COLOR="$GREET_BANNER_COLOR" TSU_BANNER_RGB="$GREET_ACCENT" tsu banner
        fi
    else
        echo
        if [[ "$GREET_BANNER_COLOR" == rainbow ]] && _greet_has lolcat; then
            printf '%s\n' "$_greet_art" | lolcat -f -F 0.25
        else
            case "$GREET_BANNER_COLOR" in
            accent) _greet_c="\e[1;38;2;${GREET_ACCENT:-122;162;247}m" ;;
            *) _greet_c="\e[1;34m" ;;
            esac
            printf "${_greet_c}%s\e[0m\n" "$_greet_art"
        fi
    fi
fi

# ---- gadget « au hasard » : un des gadgets installés ----
if [[ "$GREET_EXTRA" == random ]]; then
    _greet_pool=()
    _greet_has pokemon-colorscripts && _greet_pool+=(pokemon)
    _greet_has fortune && _greet_pool+=(fortune)
    _greet_has cowsay && _greet_pool+=(cowsay)
    _greet_has cbonsai && _greet_pool+=(bonsai)
    GREET_EXTRA=none
    ((${#_greet_pool[@]})) && GREET_EXTRA="${_greet_pool[RANDOM % ${#_greet_pool[@]}]}"
fi

_greet_poke=()
if [[ "$GREET_EXTRA" == pokemon ]] && _greet_has pokemon-colorscripts; then
    if [[ -n "$GREET_POKEMON" ]]; then
        _greet_poke=(pokemon-colorscripts -n "$GREET_POKEMON" --no-title)
    else
        _greet_poke=(pokemon-colorscripts -r --no-title)
    fi
    [[ "$GREET_SHINY" == 1 ]] && _greet_poke+=(-s)
fi

# ---- fastfetch (le Pokémon devient son logo) ----
if [[ "$GREET_FETCH" == 1 ]] && _greet_has fastfetch; then
    if ((${#_greet_poke[@]})); then
        "${_greet_poke[@]}" 2>/dev/null | fastfetch --logo-type file-raw --logo -
    else
        fastfetch
    fi
elif ((${#_greet_poke[@]})); then
    "${_greet_poke[@]}" 2>/dev/null
fi

case "$GREET_EXTRA" in
fortune) _greet_has fortune && { echo; fortune -s; echo; } ;;
cowsay)
    if _greet_has cowsay; then
        _greet_cow=()
        [[ "$GREET_COW" != default ]] && cowsay -l 2>/dev/null | tr ' ' '\n' | grep -qx "$GREET_COW" && _greet_cow=(-f "$GREET_COW")
        echo
        if _greet_has fortune; then fortune -s | cowsay "${_greet_cow[@]}"; else cowsay "${_greet_cow[@]}" "tsu"; fi
    fi
    ;;
bonsai) _greet_has cbonsai && cbonsai -p ;;
esac

unset -f _greet_has
unset _greet_text _greet_art _greet_c _greet_pool _greet_poke _greet_cow
unset GREET_BANNER GREET_BANNER_COLOR GREET_BANNER_STYLE GREET_ACCENT GREET_FETCH GREET_EXTRA GREET_SHINY GREET_POKEMON GREET_COW
