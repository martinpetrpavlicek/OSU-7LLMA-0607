#!/usr/bin/env bash
# =============================================================================
# hello.sh – "Hello world" s OpenRouter API pomocí curl
#
# OpenRouter = jedno API (kompatibilní s OpenAI) pro stovky modelů od různých
# firem. Model se vybírá jménem "firma/model", seznam: https://openrouter.ai/models
#
# API klíč se načte ze souboru .env (řádek KEY=...) ve stejné složce.
# Klíč nikdy nepíšeme přímo do skriptu ani ho nevypisujeme!
# Potřebujeme: curl a jq.
#
# Použití:  ./hello.sh ["your question"]
#           MODEL=openai/gpt-5-nano ./hello.sh
# =============================================================================

set -euo pipefail

# Načtení .env: `set -a` = všechny proměnné z .env se automaticky exportují.
set -a
source "$(dirname "$0")/.env"
set +a

MODEL="${MODEL:-deepseek/deepseek-v4-flash}"   # malý a levný model
PROMPT="${1:-Say hello world and tell me which model you are, in one sentence.}"

# POST /api/v1/chat/completions – stejný formát jako OpenAI, jen jiná adresa.
RESPONSE=$(curl -s https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{
        model: $model,
        messages: [{role: "user", content: $prompt}]
    }')")

# Při chybě (špatný klíč, neexistující model, málo kreditu…) přijde objekt "error".
if echo "$RESPONSE" | jq -e '.error' >/dev/null; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error.message')"
    exit 1
fi

# OpenRouter navíc vrací, který poskytovatel (provider) dotaz skutečně obsloužil.
echo "Model:    $(echo "$RESPONSE" | jq -r '.model')"
echo "Provider: $(echo "$RESPONSE" | jq -r '.provider // "?"')"
echo "Answer:   $(echo "$RESPONSE" | jq -r '.choices[0].message.content')"
echo "$RESPONSE" | jq -r '.usage | "Tokens: prompt=\(.prompt_tokens), answer=\(.completion_tokens)"'
