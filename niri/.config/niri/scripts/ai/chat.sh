#!/bin/bash
provider="${1:-ollama}"
model="${2:-}"
prompt="$(cat)"

case "$provider" in
ollama)
    payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,stream:false,messages:[{role:"user",content:$p}]}')
    resp=$(curl -s --max-time 300 http://localhost:11434/api/chat -d "$payload")
    echo "$resp" | jq -r '.message.content // .error // "erreur ollama (daemon lancé ?)"'
    ;;
claude)
    if [ -n "$model" ] && [ "$model" != "sonnet" ]; then
        claude -p "$prompt" --output-format text --model "$model" 2>/dev/null ||
            claude -p "$prompt" --output-format text 2>/dev/null
    else
        claude -p "$prompt" --output-format text 2>/dev/null
    fi
    ;;
gemini)
    key=$(secret-tool lookup application illogical-impulse 2>/dev/null | jq -r '.apiKeys.gemini // empty' 2>/dev/null)
    [ -z "$key" ] && key="${GEMINI_API_KEY:-}"
    [ -z "$key" ] && { echo "Erreur: aucune clé Gemini (secret-tool ou GEMINI_API_KEY)"; exit 1; }
    model="${model:-gemini-2.5-flash}"
    payload=$(jq -n --arg p "$prompt" '{contents:[{parts:[{text:$p}]}]}')
    curl -s --max-time 120 "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" \
        -H "x-goog-api-key: $key" -H "Content-Type: application/json" -d "$payload" |
        jq -r '.candidates[0].content.parts[0].text // .error.message // "erreur gemini"'
    ;;
openai)
    key="${OPENAI_API_KEY:-}"
    [ -z "$key" ] && { echo "Erreur: OPENAI_API_KEY non défini"; exit 1; }
    model="${model:-gpt-5-mini}"
    payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,messages:[{role:"user",content:$p}]}')
    curl -s --max-time 120 https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $key" -H "Content-Type: application/json" -d "$payload" |
        jq -r '.choices[0].message.content // .error.message // "erreur openai"'
    ;;
groq)
    key="${GROQ_API_KEY:-}"
    [ -z "$key" ] && { echo "Erreur: GROQ_API_KEY non défini"; exit 1; }
    model="${model:-llama-3.3-70b-versatile}"
    payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,messages:[{role:"user",content:$p}]}')
    curl -s --max-time 120 https://api.groq.com/openai/v1/chat/completions \
        -H "Authorization: Bearer $key" -H "Content-Type: application/json" -d "$payload" |
        jq -r '.choices[0].message.content // .error.message // "erreur groq"'
    ;;
openrouter)
    key="${OPENROUTER_API_KEY:-}"
    [ -z "$key" ] && { echo "Erreur: OPENROUTER_API_KEY non défini"; exit 1; }
    model="${model:-anthropic/claude-sonnet-4}"
    payload=$(jq -n --arg m "$model" --arg p "$prompt" '{model:$m,messages:[{role:"user",content:$p}]}')
    curl -s --max-time 180 https://openrouter.ai/api/v1/chat/completions \
        -H "Authorization: Bearer $key" -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://localhost" -H "X-Title: spell-shell" \
        -d "$payload" |
        jq -r '.choices[0].message.content // .error.message // "erreur openrouter"'
    ;;
*)
    echo "Provider inconnu : $provider"
    exit 1
    ;;
esac
