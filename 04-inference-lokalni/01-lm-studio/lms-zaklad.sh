#!/usr/bin/env bash
# Jednoduchy prehled zakladnich prikazu LM Studio CLI (lms)
# Spusteni: ./lms-zaklad.sh

# Nazev modelu, se kterym budeme pracovat (zmen podle sebe)
MODEL="qwen2.5-7b-instruct"

# Zobrazi stav LM Studia (bezi server? jaky model je nacteny?)
lms status

# Stahne model z internetu (pokud ho jeste nemame)
lms get "$MODEL"

# Vypise vsechny stazene modely na disku
lms ls

# Spusti lokalni server (OpenAI kompatibilni API na portu 1234)
lms server start

# Nacte model do pameti (GPU)
lms load "$MODEL"

# Vypise modely, ktere jsou prave nactene v pameti
lms ps

# Polozi modelu jednu otazku primo z prikazove radky
lms chat "$MODEL" -p "Ahoj, kdo jsi?"

# Stejny dotaz pres HTTP API pomoci curl (jak by to delala jina aplikace)
curl -s http://localhost:1234/v1/chat/completions -H "Content-Type: application/json" -d '{"model": "'"$MODEL"'", "messages": [{"role": "user", "content": "Ahoj, kdo jsi?"}]}'

# Uvolni vsechny modely z pameti
lms unload --all

# Zastavi lokalni server
lms server stop
