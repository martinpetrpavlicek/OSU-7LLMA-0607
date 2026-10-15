#!/usr/bin/env bash
# Simple command-line client for the LM Studio local server (OpenAI-compatible API).
#
# Usage:
#   ./lms-chat.sh models                 # list available models
#   ./lms-chat.sh ask "your question"    # one-shot question
#   echo "text" | ./lms-chat.sh ask      # question from stdin
#   ./lms-chat.sh chat                   # interactive chat (keeps history)
#
# Environment variables:
#   LMS_HOST    server URL      (default: http://localhost:1234)
#   LMS_MODEL   model id        (default: first model reported by the server)
#   LMS_SYSTEM  system prompt   (default: "You are a helpful assistant.")
#   LMS_TEMP    temperature     (default: 0.7)

set -euo pipefail

HOST="${LMS_HOST:-http://localhost:1234}"
SYSTEM="${LMS_SYSTEM:-You are a helpful assistant.}"
TEMP="${LMS_TEMP:-0.7}"

for cmd in curl jq; do
    command -v "$cmd" >/dev/null || { echo "Error: '$cmd' is required." >&2; exit 1; }
done

list_models() {
    curl -sf "$HOST/v1/models" | jq -r '.data[].id' \
        || { echo "Error: cannot reach LM Studio server at $HOST (start it with 'lms server start')." >&2; exit 1; }
}

pick_model() {
    if [[ -n "${LMS_MODEL:-}" ]]; then
        echo "$LMS_MODEL"
    else
        list_models | head -n 1
    fi
}

# Send a JSON array of messages, print the assistant reply.
complete() {
    local messages="$1" model="$2"
    jq -n --arg model "$model" --argjson messages "$messages" --argjson temp "$TEMP" \
        '{model: $model, messages: $messages, temperature: $temp, stream: false}' \
    | curl -sf "$HOST/v1/chat/completions" -H "Content-Type: application/json" -d @- \
    | jq -r '.choices[0].message.content'
}

cmd_ask() {
    local prompt="${*:-}"
    [[ -z "$prompt" && ! -t 0 ]] && prompt="$(cat)"
    [[ -z "$prompt" ]] && { echo "Usage: $0 ask \"question\"" >&2; exit 1; }

    local model messages
    model="$(pick_model)"
    messages="$(jq -n --arg s "$SYSTEM" --arg u "$prompt" \
        '[{role: "system", content: $s}, {role: "user", content: $u}]')"
    complete "$messages" "$model"
}

cmd_chat() {
    local model messages input reply
    model="$(pick_model)"
    messages="$(jq -n --arg s "$SYSTEM" '[{role: "system", content: $s}]')"
    echo "Model: $model  (type 'exit' to quit, 'reset' to clear history)"

    while IFS= read -r -e -p $'\n> ' input; do
        case "$input" in
            exit|quit) break ;;
            reset) messages="$(jq -n --arg s "$SYSTEM" '[{role: "system", content: $s}]')"
                   echo "History cleared."; continue ;;
            "") continue ;;
        esac
        messages="$(jq --arg u "$input" '. + [{role: "user", content: $u}]' <<<"$messages")"
        reply="$(complete "$messages" "$model")" || { echo "Error: request failed." >&2; continue; }
        echo "$reply"
        messages="$(jq --arg a "$reply" '. + [{role: "assistant", content: $a}]' <<<"$messages")"
    done
}

case "${1:-}" in
    models) list_models ;;
    ask)    shift; cmd_ask "$@" ;;
    chat)   cmd_chat ;;
    *)      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
