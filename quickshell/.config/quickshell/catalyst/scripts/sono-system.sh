#!/usr/bin/env bash
# Fait passer tout le son du PC dans la sono de VoxMix, en pointant la sortie par
# défaut vers « VoxMix Desktop ». EasyEffects et les applis suivent la sortie par défaut.
#   on    active et le retient     off   désactive et le retient
#   auto  à l'allumage : active, sauf si désactivé la dernière fois
#   stop  à l'extinction : remet la sortie d'origine sans changer le choix
set -u
STATE="$HOME/.cache/catalyst"
PREV="$STATE/sono-prev-sink"
OFF="$STATE/sono-system-off"
PREV_MIC="$STATE/sono-prev-source"
mkdir -p "$STATE"

desktop_sink() {
    pactl list sinks | awk '/^\s*(Name|Nom) ?:/ {name=$2} /Description ?: VoxMix Desktop$/ {print name; exit}'
}

enable() {
    local sink="" current
    # Le moteur vient peut-être de démarrer : sa sortie virtuelle arrive un peu après.
    for _ in $(seq 1 25); do
        sink=$(desktop_sink)
        [ -n "$sink" ] && break
        sleep 0.2
    done
    if [ -z "$sink" ]; then
        echo "sortie « VoxMix Desktop » introuvable" >&2
        return 1
    fi
    current=$(pactl get-default-sink)
    case "$current" in
        voxmix_*) ;;
        *) printf '%s\n' "$current" > "$PREV" ;;
    esac
    pactl set-default-sink "$sink"
}

restore() {
    case "$(pactl get-default-sink)" in
        voxmix_*) ;;
        *) return 0 ;;
    esac
    local prev=""
    [ -r "$PREV" ] && prev=$(cat "$PREV")
    if [ -n "$prev" ] && pactl list short sinks | awk '{print $2}' | grep -Fxq "$prev"; then
        pactl set-default-sink "$prev"
    else
        # Sortie d'origine débranchée : la première sortie matérielle fera l'affaire.
        pactl set-default-sink "$(pactl list short sinks | awk '$2 ~ /^alsa_output/ {print $2; exit}')"
    fi
}

easyeffects_ready() {
    pw-link -i | grep -Fxq "easyeffects_source:input_FR"
}

# Easy Effects ramène les applis sur easyeffects_source. Sa réduction de bruit y effacerait
# la réverbération : VoxMix alimente donc cette source directement, à la place de sa chaîne.
feed_easyeffects() {
    local side from
    # Easy Effects fermé : on le lance sans fenêtre, ses ports arrivent un peu après.
    if ! easyeffects_ready; then
        PATH="$HOME/.local/bin:$PATH" setsid -f easyeffects -w >/dev/null 2>&1 </dev/null
        for _ in $(seq 1 50); do
            easyeffects_ready && break
            sleep 0.2
        done
        # Sa chaîne se branche après ses ports : la débrancher trop tôt laisserait les deux voix.
        for _ in $(seq 1 25); do
            pw-link -l | grep -Fq "|<- ee_sie_output_level:output_FR" && break
            sleep 0.2
        done
        sleep 0.5
    fi
    if ! easyeffects_ready; then
        echo "Easy Effects n'a pas démarré" >&2
        return 1
    fi
    for side in FL FR; do
        pw-link -l | awk -v p="easyeffects_source:input_$side" '$0 == p {on=1; next} /^[^ ]/ {on=0} on && /\|<-/ {print $2}' | while read -r from; do
            pw-link -d "$from" "easyeffects_source:input_$side"
        done
        pw-link "voxmix_mic:capture_$side" "easyeffects_source:input_$side"
    done
}

# Micro par défaut sur VoxMix, pour les applis qui suivent le micro par défaut.
mic_enable() {
    local current
    for _ in $(seq 1 25); do
        pactl list short sources | awk '{print $2}' | grep -Fxq voxmix_mic && break
        sleep 0.2
    done
    current=$(pactl get-default-source)
    case "$current" in
        voxmix_*) ;;
        *) printf '%s\n' "$current" > "$PREV_MIC" ;;
    esac
    pactl set-default-source voxmix_mic
    sleep 1
    feed_easyeffects
}

mic_restore() {
    case "$(pactl get-default-source)" in
        voxmix_*) ;;
        *) return 0 ;;
    esac
    local prev=""
    [ -r "$PREV_MIC" ] && prev=$(cat "$PREV_MIC")
    [ -n "$prev" ] && pactl set-default-source "$prev"
}

case "${1:-}" in
    on) rm -f "$OFF"; enable ;;
    off) : > "$OFF"; restore ;;
    # La sortie d'abord : lancer Easy Effects pour le micro peut prendre plusieurs secondes.
    auto) [ -e "$OFF" ] || enable; mic_enable ;;
    stop) restore; mic_restore ;;
    *) echo "usage: $0 on|off|auto|stop" >&2; exit 2 ;;
esac
