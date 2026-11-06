# tsu banner - Print the terminal banner (text set in Studio → Profil & interface)

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: tsu banner [text]"
    echo ""
    echo "Print the block-letter banner shown when a terminal opens."
    echo "The text comes from Studio → Profil & interface → Bannière du terminal"
    echo "(copied to ~/.cache/catalyst/banner). Pass a text to preview it without saving."
    echo "Supported: A-Z, 0-9, space, - . ! ?"
    return 0
fi

_banner_text="${1:-}"
if [[ -z "$_banner_text" && -r "$HOME/.cache/catalyst/banner" ]]; then
    _banner_text="$(<"$HOME/.cache/catalyst/banner")"
fi
[[ -z "${_banner_text// /}" ]] && _banner_text="tsu"

# Two-row half-block font, one glyph per character: "top|bottom"
declare -A _banner_font=(
    [A]="▄▀█|█▀█" [B]="█▄▄|█▄█" [C]="█▀▀|█▄▄" [D]="█▀▄|█▄▀" [E]="█▀▀|██▄"
    [F]="█▀▀|█▀ " [G]="█▀▀|█▄█" [H]="█ █|█▀█" [I]="█|█"     [J]="  █|█▄█"
    [K]="█▄▀|█ █" [L]="█  |█▄▄" [M]="█▀▄▀█|█ ▀ █" [N]="█▄ █|█ ▀█" [O]="█▀█|█▄█"
    [P]="█▀█|█▀▀" [Q]="█▀█|▀▀█" [R]="█▀█|█▀▄" [S]="█▀|▄█"   [T]="▀█▀| █ "
    [U]="█ █|█▄█" [V]="█ █|▀▄▀" [W]="█ █ █|▀▄▀▄▀" [X]="▀▄▀|█ █" [Y]="█▄█| █ "
    [Z]="▀█|█▄"
    [0]="█▀█|█▄█" [1]="▄█| █"   [2]="▀█|█▄"   [3]="▀▀█|▄██" [4]="█ █|▀▀█"
    [5]="█▀|▄█"   [6]="█▄▄|█▄█" [7]="▀▀█|  █" [8]="█▀█|█▀█" [9]="█▀█|▀▀█"
    [" "]="  |  " ["-"]="▄▄|  "  ["."]=" |▄"     ["!"]="█|▄"     ["?"]="▀█|▄ "
)

_banner_top="" _banner_bot=""
# accents → lettres simples (é → E), le reste des caractères inconnus est ignoré
_banner_up="$(printf '%s' "$_banner_text" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null || printf '%s' "$_banner_text")"
_banner_up="${_banner_up^^}"
for ((_i = 0; _i < ${#_banner_up}; _i++)); do
    _g="${_banner_font[${_banner_up:_i:1}]:-}"
    [[ -z "$_g" ]] && continue
    _banner_top+="${_g%%|*} "
    _banner_bot+="${_g#*|} "
done
if [[ -z "${_banner_top// /}" ]]; then
    _banner_top="▀█▀ █▀ █ █ " _banner_bot=" █  ▄█ █▄█ "
fi

# couleur : TSU_BANNER_COLOR = blue (défaut) | accent (TSU_BANNER_RGB="r;g;b") | none
case "${TSU_BANNER_COLOR:-blue}" in
accent) _banner_c="\e[1;38;2;${TSU_BANNER_RGB:-122;162;247}m" ;;
none) _banner_c="" ;;
*) _banner_c="\e[1;34m" ;;
esac
printf "${_banner_c}\n  %s\n  %s\n${_banner_c:+\e[0m}\n" "$_banner_top" "$_banner_bot"
unset _banner_text _banner_font _banner_top _banner_bot _banner_up _i _g _banner_c
