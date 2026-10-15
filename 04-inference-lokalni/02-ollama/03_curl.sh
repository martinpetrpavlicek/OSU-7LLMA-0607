#!/usr/bin/env bash
# =============================================================================
# 03_curl.sh – volání Ollamy přes REST API pomocí curl
#
# Ollama server poslouchá na http://localhost:11434 a nabízí HTTP API.
# Díky tomu ji lze volat z libovolného jazyka – stačí poslat JSON.
# Potřebujeme: curl (HTTP požadavky) a jq (práce s JSON).
#
# Použití:  ./03_curl.sh ["your question"]
# =============================================================================

set -euo pipefail

OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
MODEL="${MODEL:-gemma3:1b}"
PROMPT="${1:-Why is the sky blue? Answer in one sentence.}"

# -----------------------------------------------------------------------------
# 1) Seznam lokálních modelů – GET /api/tags
# Totéž jako `ollama list`, jen ve formátu JSON.
# -----------------------------------------------------------------------------
echo "=== 1) Local models (GET /api/tags) ==="
curl -s "$OLLAMA_URL/api/tags" | jq -r '.models[].name'

# -----------------------------------------------------------------------------
# 2) Generování textu – POST /api/generate
# "stream": false => server vrátí celou odpověď najednou v jednom JSONu.
# JSON tělo skládáme pomocí jq, aby se správně ošetřily uvozovky
# a speciální znaky v promptu.
# -----------------------------------------------------------------------------
echo
echo "=== 2) Generate (POST /api/generate) ==="
echo "Prompt: $PROMPT"

REQUEST=$(jq -n \
    --arg model "$MODEL" \
    --arg prompt "$PROMPT" \
    '{model: $model, prompt: $prompt, stream: false}')

RESPONSE=$(curl -s "$OLLAMA_URL/api/generate" -d "$REQUEST")

# Z odpovědi vytáhneme jen text ...
echo "Answer: $(echo "$RESPONSE" | jq -r '.response')"

# ... a pár užitečných statistik (časy jsou v nanosekundách).
echo "$RESPONSE" | jq -r '
    "Tokens generated: \(.eval_count)",
    "Speed: \((.eval_count / (.eval_duration / 1e9)) | floor) tokens/s"'

# -----------------------------------------------------------------------------
# 3) Streamování – stejný endpoint, ale "stream": true (výchozí)
# Server posílá odpověď po kouscích – každý řádek je samostatný JSON
# s jedním nebo několika tokeny. Tak vzniká efekt "psaní" jako v ChatGPT.
# `jq -j` vypisuje bez odřádkování, `--unbuffered` hned, jak data přijdou.
# -----------------------------------------------------------------------------
echo
echo "=== 3) Streaming (POST /api/generate, stream: true) ==="
curl -sN "$OLLAMA_URL/api/generate" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" \
          '{model: $model, prompt: $prompt}')" \
    | jq --unbuffered -j '.response'
echo

# -----------------------------------------------------------------------------
# 4) Chat – POST /api/chat
# Místo jednoho promptu posíláme seznam zpráv s rolemi:
#   system    – instrukce pro model (jak se má chovat),
#   user      – otázky uživatele,
#   assistant – předchozí odpovědi modelu.
# Model sám nic nepamatuje – historii konverzace musíme posílat pokaždé celou.
# -----------------------------------------------------------------------------
echo
echo "=== 4) Chat with history (POST /api/chat) ==="
curl -s "$OLLAMA_URL/api/chat" -d "$(jq -n --arg model "$MODEL" '{
    model: $model,
    stream: false,
    messages: [
        {role: "system",    content: "You are a helpful assistant. Answer briefly."},
        {role: "user",      content: "My name is Alice."},
        {role: "assistant", content: "Nice to meet you, Alice!"},
        {role: "user",      content: "What is my name?"}
    ]
}')" | jq -r '.message.content'
