#!/bin/bash
# image.sh <model> <prompt> — génère une image via ollama (flux2…), renvoie le chemin du PNG
model="${1:-x/flux2-klein:latest}"
prompt="$2"
out_dir="$HOME/Images/ai"
mkdir -p "$out_dir"
out="$out_dir/img_$(date +%Y%m%d_%H%M%S).png"

payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,prompt:$p,stream:false}')
resp=$(curl -s --max-time 600 http://localhost:11434/api/generate -d "$payload")

b64=$(echo "$resp" | jq -r '.images[0] // empty')
if [ -z "$b64" ]; then
    echo "ERR: $(echo "$resp" | jq -r '.error // "réponse inattendue d'\''ollama"')" >&2
    exit 1
fi
echo "$b64" | base64 -d >"$out" && echo "$out"
