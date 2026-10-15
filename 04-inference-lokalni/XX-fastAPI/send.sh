#!/usr/bin/env bash
# =============================================================================
# send.sh – pošle zprávu našemu FastAPI endpointu a ukáže historii
#
# Server musí běžet (./run.sh v jiném terminálu).
#
# Použití:  ./send.sh ["your message"]
#           MODEL=mistral:7b ./send.sh "Hi"
# =============================================================================

set -euo pipefail

API_URL="${API_URL:-http://localhost:8001}"
MESSAGE="${1:-Why is the sky blue? Answer in one sentence.}"

# Tělo požadavku: {"message": "..."} (+ volitelně "model").
if [[ -n "${MODEL:-}" ]]; then
    BODY=$(jq -n --arg m "$MESSAGE" --arg model "$MODEL" '{message: $m, model: $model}')
else
    BODY=$(jq -n --arg m "$MESSAGE" '{message: $m}')
fi

echo "=== POST /chat ==="
curl -s "$API_URL/chat" -H "Content-Type: application/json" -d "$BODY" | jq .

echo
echo "=== GET /history (fastapichat.txt) ==="
curl -s "$API_URL/history"
