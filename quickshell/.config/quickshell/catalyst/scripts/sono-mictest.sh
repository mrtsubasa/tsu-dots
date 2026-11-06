#!/usr/bin/env bash
# Test de voix : enregistre ce que tes applis reçoivent de VoxMix Micro, puis le fait
# réécouter en direct sur le casque (sans la sono). Le fichier est supprimé aussitôt.
#   record <secondes>   play [sortie]   who
set -u
MIC="${SONO_MIC_NODE:-voxmix_mic}"
FILE="${XDG_RUNTIME_DIR:-/tmp}/voxmix-mic-test.wav"

case "${1:-}" in
    record)
        rm -f "$FILE"
        timeout "${2:-5}" pw-record --target "$MIC" --rate 48000 --channels 2 "$FILE"
        [ -s "$FILE" ] || { echo "Rien n'a été enregistré depuis VoxMix Micro" >&2; exit 1; }
        ;;
    play)
        [ -s "$FILE" ] || { echo "Aucun enregistrement à réécouter" >&2; exit 1; }
        # Sortie d'avant la sono : on veut entendre ce que reçoivent les autres, sans la salle.
        target="${2:-}"
        [ -n "$target" ] || target=$(cat "$HOME/.cache/catalyst/sono-prev-sink" 2>/dev/null)
        pw-play --target "${target:-auto}" "$FILE"
        status=$?
        rm -f "$FILE"
        exit $status
        ;;
    who)
        # Applis qui écoutent un micro, et lequel.
        python3 -I - <<'PY'
import json, subprocess
run = lambda *a: json.loads(subprocess.run(["pactl", "-f", "json", "list", *a], capture_output=True, text=True).stdout or "[]")
sources = {s["index"]: s for s in run("sources")}
# Easy Effects ramène les applis sur sa source : elles reçoivent VoxMix s'il l'alimente.
links = subprocess.run(["pw-link", "-l"], capture_output=True, text=True).stdout
via_ee = "easyeffects_source:input_FL\n  |<- voxmix_mic:capture_FL" in links
out = []
for o in run("source-outputs"):
    p = o["properties"]
    name = p.get("application.name") or p.get("node.name") or "?"
    node = p.get("node.name", "")
    if node.startswith(("voxmix", "ee_", "output.", "input.")) or "easyeffects" in name.lower() or "peak detect" in p.get("media.name", "").lower():
        continue
    src = sources.get(o["source"], {})
    if name == "quickshell" or src.get("name", "").endswith(".monitor"):
        continue
    out.append({"app": name, "source": src.get("description", "?"), "voxmix": src.get("name") in ("voxmix_mic", "voxmix_b2") or (src.get("name") == "easyeffects_source" and via_ee)})
print(json.dumps(out))
PY
        ;;
    *) echo "usage: $0 record|play|who" >&2; exit 2 ;;
esac
