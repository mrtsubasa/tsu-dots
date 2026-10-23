#!/usr/bin/env bash
# Tsubasa Catalyst — restaure les fonds d'écran par écran choisis dans le Studio
# (après wallpaper.sh restore, qui pose le fond global + matugen).
#   catalyst-walls.sh restore
set -u
MAP="$HOME/.cache/catalyst/walls.json"
[ "${1:-}" = "restore" ] || { sed -n '2,4p' "$0"; exit 2; }
[ -s "$MAP" ] || exit 0
for _ in $(seq 1 20); do pgrep -x awww-daemon >/dev/null && break; sleep 0.5; done
python3 - "$MAP" <<'PY' | while IFS=$'\t' read -r out img; do
import json, os, sys
for out, img in (json.load(open(sys.argv[1])) or {}).items():
    if os.path.isfile(img):
        print(f"{out}\t{img}")
PY
    awww img -o "$out" "$img" --transition-type none >/dev/null 2>&1 || true
done
