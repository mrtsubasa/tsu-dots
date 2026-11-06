#!/bin/bash
set -euo pipefail

SM=0.2

read_pct() {
    ddcutil getvcp 10 --display 1 --brief --sleep-multiplier "$SM" 2>/dev/null | awk '{print $(NF-1)}'
}

apply() {
    local n="${1:-50}"
    n=${n%.*}
    if [ "$n" -lt 1 ]; then n=1; fi
    if [ "$n" -gt 100 ]; then n=100; fi
    ddcutil setvcp 10 "$n" --display 1 --sleep-multiplier "$SM" >/dev/null 2>&1 &
    ddcutil setvcp 10 "$n" --display 2 --sleep-multiplier "$SM" >/dev/null 2>&1 &
    wait
    printf '%s\n' "$n"
}

case "${1:-get}" in
get)
    read_pct || echo 100
    ;;
set)
    apply "${2:?}"
    ;;
up)
    cur=$(read_pct || echo 50)
    apply $((cur + 10))
    ;;
down)
    cur=$(read_pct || echo 50)
    apply $((cur - 10))
    ;;
*)
    apply "$1"
    ;;
esac
