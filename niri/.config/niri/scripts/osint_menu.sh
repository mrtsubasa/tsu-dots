#!/usr/bin/env bash
# Menu OSINT : username / email / phone / domain / IP / suites.
set -u
cd "$HOME" || exit 0
# shellcheck source=/dev/null
source "$HOME/.config/niri/scripts/arsenal-lib.sh"

have() { command -v "$1" >/dev/null 2>&1; }

pick_query() {
    local kind="$1"
    local pre
    pre="$(arsenal_target)"
    local q
    q="$(arsenal_ask "󰭔 $kind" "$pre")"
    [[ -z "$q" ]] && return 1
    printf '%s' "$q"
}

run_q() {
    local title="$1"
    local cmdline="$2"
    alacritty -t "OSINT - $title" -e bash -lc "echo -e '\\e[1;36m  \$ ${cmdline}\\e[0m'; echo; ${cmdline}; echo; exec bash" >/dev/null 2>&1 &
}

KIND="$(printf '%s\n' \
    "󰀉  Username" \
    "󰇮  Email" \
    "󰏲  Phone" \
    "󰖟  Domain" \
    "󰩠  IP" \
    "󰭔  Suites (Maltego / SpiderFoot / recon-ng)" \
    "󰁪  Cible actuelle : $(arsenal_target | sed 's/^$/aucune/')" \
    "󰓾  Définir la cible" \
    | arsenal_rofi "󰭔 OSINT")"

[[ -z "$KIND" ]] && exit 0

case "$KIND" in
    *Cible*)
        notify-send "OSINT" "Cible : $(arsenal_target | sed 's/^$/aucune/')"
        exit 0
        ;;
    *Définir*)
        t="$(arsenal_ask "Nouvelle cible" "$(arsenal_target)")"
        [[ -n "$t" ]] && arsenal_set_target "$t"
        exit 0
        ;;
    *Suites*)
        SUITE="$(printf '%s\n' \
            "maltego" \
            "spiderfoot" \
            "recon-ng" \
            "sn0int" \
            | arsenal_rofi "󰭔 Suite")"
        [[ -z "$SUITE" ]] && exit 0
        arsenal_launch "$SUITE"
        exit 0
        ;;
esac

Q="$(pick_query "$KIND")" || exit 0

TOOLS=()
case "$KIND" in
    *Username*)
        have sherlock && TOOLS+=("sherlock")
        have maigret && TOOLS+=("maigret")
        have socialscan && TOOLS+=("socialscan")
        have holehe && TOOLS+=("holehe")
        have osintgram && TOOLS+=("osintgram")
        ;;
    *Email*)
        have holehe && TOOLS+=("holehe")
        have socialscan && TOOLS+=("socialscan")
        have theharvester && TOOLS+=("theharvester")
        have sherlock && TOOLS+=("sherlock")
        ;;
    *Phone*)
        have phoneinfoga && TOOLS+=("phoneinfoga")
        have socialscan && TOOLS+=("socialscan")
        ;;
    *Domain*)
        have whois && TOOLS+=("whois")
        have dig && TOOLS+=("dig")
        have subfinder && TOOLS+=("subfinder")
        have amass && TOOLS+=("amass")
        have httpx && TOOLS+=("httpx")
        have whatweb && TOOLS+=("whatweb")
        have wpscan && TOOLS+=("wpscan")
        have waybackurls && TOOLS+=("waybackurls")
        have gau && TOOLS+=("gau")
        have theharvester && TOOLS+=("theharvester")
        ;;
    *IP*)
        have whois && TOOLS+=("whois")
        have nmap && TOOLS+=("nmap")
        have httpx && TOOLS+=("httpx")
        have dig && TOOLS+=("dig")
        ;;
esac

if [[ ${#TOOLS[@]} -eq 0 ]]; then
    notify-send "OSINT" "Aucun outil installé pour cette catégorie"
    exit 0
fi

TOOL="$(printf '%s\n' "${TOOLS[@]}" | arsenal_rofi "Outil · $Q")"
[[ -z "$TOOL" ]] && exit 0

# shellcheck disable=SC2089
case "$TOOL" in
    sherlock)     run_q "$TOOL" "sherlock '$Q'" ;;
    maigret)      run_q "$TOOL" "maigret '$Q'" ;;
    socialscan)   run_q "$TOOL" "socialscan '$Q'" ;;
    holehe)       run_q "$TOOL" "holehe '$Q'" ;;
    osintgram)    run_q "$TOOL" "osintgram '$Q'" ;;
    phoneinfoga)  run_q "$TOOL" "phoneinfoga scan -n '$Q'" ;;
    theharvester) run_q "$TOOL" "theharvester -d '$Q' -b all" ;;
    whois)        run_q "$TOOL" "whois '$Q'" ;;
    dig)          run_q "$TOOL" "dig '$Q' ANY +noall +answer" ;;
    subfinder)    run_q "$TOOL" "subfinder -d '$Q'" ;;
    amass)        run_q "$TOOL" "amass enum -d '$Q'" ;;
    httpx)        run_q "$TOOL" "echo '$Q' | httpx -title -status-code -tech-detect" ;;
    whatweb)      run_q "$TOOL" "whatweb '$Q'" ;;
    wpscan)       run_q "$TOOL" "wpscan --url '$Q'" ;;
    waybackurls)  run_q "$TOOL" "echo '$Q' | waybackurls | head" ;;
    gau)          run_q "$TOOL" "gau '$Q' | head" ;;
    nmap)         run_q "$TOOL" "nmap -sV -sC '$Q'" ;;
    *)            arsenal_launch "$TOOL" ;;
esac
