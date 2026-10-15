#!/usr/bin/env bash
# =============================================================================
# 03_curl.sh – volání vLLM serveru přes HTTP pomocí curl
#
# vLLM nabízí API kompatibilní s OpenAI (/v1/models, /v1/chat/completions…).
# Server musí běžet (./02_serve.sh v jiném terminálu).
# Potřebujeme: curl (HTTP požadavky) a jq (práce s JSON).
#
# Použití:  ./03_curl.sh ["your question"]
# =============================================================================

set -euo pipefail

VLLM_URL="${VLLM_URL:-http://localhost:8000}"
PROMPT="${1:-Why is the sky blue? Answer in one sentence.}"

# -----------------------------------------------------------------------------
# 0) Je server připravený? – GET /health  (HTTP 200 = ano)
# -----------------------------------------------------------------------------
echo "=== 0) Health check (GET /health) ==="
curl -s -o /dev/null -w "HTTP %{http_code}\n" "$VLLM_URL/health"

# -----------------------------------------------------------------------------
# 1) Seznam modelů – GET /v1/models
# vLLM obsluhuje jen model(y), se kterými byl spuštěn. Jméno si zjistíme
# a použijeme dál v požadavcích.
# -----------------------------------------------------------------------------
echo
echo "=== 1) Models (GET /v1/models) ==="
MODEL=$(curl -s "$VLLM_URL/v1/models" | jq -r '.data[0].id')
echo "$MODEL"

# -----------------------------------------------------------------------------
# 2) Chat – POST /v1/chat/completions
# Posíláme seznam zpráv s rolemi (system / user / assistant).
# JSON tělo skládáme přes jq, aby se správně ošetřily uvozovky v promptu.
# -----------------------------------------------------------------------------
echo
echo "=== 2) Chat completion (POST /v1/chat/completions) ==="
echo "Prompt: $PROMPT"

REQUEST=$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{
    model: $model,
    messages: [
        {role: "system", content: "You are a helpful assistant. Answer briefly."},
        {role: "user",   content: $prompt}
    ],
    max_tokens: 200,
    temperature: 0.7
}')

RESPONSE=$(curl -s "$VLLM_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$REQUEST")

# Text odpovědi je v choices[0].message.content ...
echo "Answer: $(echo "$RESPONSE" | jq -r '.choices[0].message.content')"
# ... a spotřeba tokenů v "usage".
echo "$RESPONSE" | jq -r '.usage | "Tokens: prompt=\(.prompt_tokens), answer=\(.completion_tokens)"'

# -----------------------------------------------------------------------------
# 3) Streamování – stejný endpoint, ale "stream": true
# Server posílá Server-Sent Events (SSE): řádky ve tvaru
#     data: {...json s kouskem textu...}
# a na konci
#     data: [DONE]
# Ukážeme nejdřív syrová data, pak jen text.
# -----------------------------------------------------------------------------
STREAM_REQUEST=$(echo "$REQUEST" | jq '.stream = true')

echo
echo "=== 3a) Streaming – raw SSE (first 5 lines) ==="
curl -sN "$VLLM_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$STREAM_REQUEST" | grep -v '^$' | head -n 5 || true

echo
echo "=== 3b) Streaming – text only ==="
# sed: odstraní "data: " a vyhodí řádek [DONE]; jq -j: tiskne bez odřádkování.
curl -sN "$VLLM_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$STREAM_REQUEST" \
    | sed -u -n 's/^data: //p' | grep --line-buffered -v '^\[DONE\]' \
    | jq --unbuffered -j '.choices[0].delta.content // ""'
echo

# -----------------------------------------------------------------------------
# 4) Chat s historií
# Model sám nic nepamatuje – historii konverzace posíláme pokaždé celou.
# -----------------------------------------------------------------------------
echo
echo "=== 4) Chat with history ==="
curl -s "$VLLM_URL/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg model "$MODEL" '{
        model: $model,
        messages: [
            {role: "system",    content: "You are a helpful assistant. Answer briefly."},
            {role: "user",      content: "My name is Alice."},
            {role: "assistant", content: "Nice to meet you, Alice!"},
            {role: "user",      content: "What is my name?"}
        ]
    }')" | jq -r '.choices[0].message.content'
