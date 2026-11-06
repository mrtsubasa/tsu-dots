#!/bin/bash
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    hyprctl dispatch "hl.dsp.dpms({ action = \"${1:-off}\" })"
    exit 0
fi
if command -v niri >/dev/null; then
    if [ "${1:-off}" = "on" ]; then
        niri msg action power-on-monitors >/dev/null 2>&1 || true
    else
        niri msg action power-off-monitors
    fi
fi
