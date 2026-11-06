# tsu greet - What a new terminal prints (Studio → Terminal → Accueil)

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tsu greet"
    echo ""
    echo "Print the terminal greeting: banner, fastfetch and the chosen extra"
    echo "(Pokémon, fortune, cowsay, bonsai). Set from Studio → Terminal,"
    echo "stored in ~/.cache/catalyst/greet.env."
    return 0
fi

# défauts = comportement d'avant (bannière bleue + fastfetch)
GREET_BANNER=1
GREET_BANNER_COLOR=blue
GREET_ACCENT=""
GREET_FETCH=1
GREET_EXTRA=none
GREET_SHINY=0
[[ -r "$HOME/.cache/catalyst/greet.env" ]] && source "$HOME/.cache/catalyst/greet.env"

_greet_has() { command -v "$1" >/dev/null 2>&1; }

if [[ "$GREET_BANNER" == 1 ]]; then
    if [[ "$GREET_BANNER_COLOR" == rainbow ]] && _greet_has lolcat; then
        TSU_BANNER_COLOR=none tsu banner | lolcat -f -F 0.25
    else
        TSU_BANNER_COLOR="$GREET_BANNER_COLOR" TSU_BANNER_RGB="$GREET_ACCENT" tsu banner
    fi
fi

_greet_poke=""
if [[ "$GREET_EXTRA" == pokemon ]] && _greet_has pokemon-colorscripts; then
    _greet_poke="pokemon-colorscripts -r --no-title"
    [[ "$GREET_SHINY" == 1 ]] && _greet_poke+=" -s"
fi

if [[ "$GREET_FETCH" == 1 ]] && _greet_has fastfetch; then
    if [[ -n "$_greet_poke" ]]; then
        # le Pokémon devient le logo de fastfetch
        $_greet_poke | fastfetch --logo-type file-raw --logo -
    else
        fastfetch
    fi
elif [[ -n "$_greet_poke" ]]; then
    $_greet_poke
fi

case "$GREET_EXTRA" in
fortune) _greet_has fortune && { echo; fortune -s; echo; } ;;
cowsay) _greet_has cowsay && { echo; if _greet_has fortune; then fortune -s | cowsay; else cowsay "tsu"; fi; } ;;
bonsai) _greet_has cbonsai && cbonsai -p ;;
esac

unset -f _greet_has
unset _greet_poke GREET_BANNER GREET_BANNER_COLOR GREET_ACCENT GREET_FETCH GREET_EXTRA GREET_SHINY
