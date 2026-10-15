#!/usr/bin/env bash
# =============================================================================
# hello.sh – "Hello world" s OpenAI API pomocí curl
#
# API klíč se načte ze souboru .env (řádek KEY=...) ve stejné složce.
# Klíč nikdy nepíšeme přímo do skriptu ani ho nevypisujeme!
# Potřebujeme: curl a jq.
#
# Použití:  ./hello.sh ["your question"]
#           MODEL=gpt-5.6-luna ./hello.sh
# =============================================================================

set -euo pipefail

# Načtení .env: `set -a` = všechny proměnné z .env se automaticky exportují.
set -a
source "$(dirname "$0")/.env"
set +a

MODEL="${MODEL:-gpt-6-luna}"      # malý a levný model
PROMPT="${1:-Say hello world and tell me which model you are, in one sentence.}"

# POST /v1/chat/completions – stejný formát jako vLLM, LM Studio, OpenRouter…
# Klíč posíláme v hlavičce "Authorization: Bearer <klíč>".
# JSON tělo skládáme přes jq, aby se správně ošetřily uvozovky v promptu.
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg model "$MODEL" --arg prompt "$PROMPT" '{
        model: $model,
        messages: [{role: "user", content: $prompt}]
    }')")

# Při chybě (špatný klíč, neexistující model…) vrátí API objekt "error".
if echo "$RESPONSE" | jq -e '.error' >/dev/null; then
    echo "Error: $(echo "$RESPONSE" | jq -r '.error.message')"
    exit 1
fi

echo "Model:  $(echo "$RESPONSE" | jq -r '.model')"
echo "Answer: $(echo "$RESPONSE" | jq -r '.choices[0].message.content')"
echo "$RESPONSE" | jq -r '.usage | "Tokens: prompt=\(.prompt_tokens), answer=\(.completion_tokens)"'
