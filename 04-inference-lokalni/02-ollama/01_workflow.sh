#!/usr/bin/env bash
# =============================================================================
# 01_workflow.sh – základní práce s Ollamou z příkazové řádky
#
# Ukázka: vyhledání modelu -> stažení -> kontrola -> spuštění -> úklid.
# Použití:  ./01_workflow.sh [model]      (výchozí model: gemma3:1b)
# =============================================================================

set -euo pipefail   # Skript skončí při první chybě nebo nedefinované proměnné.

MODEL="${1:-gemma3:1b}"          # Malý model (~800 MB) – rychle se stáhne.
SEARCH_TERM="${MODEL%%:*}"       # Název bez tagu, např. "gemma3".

# Pomocná funkce: vypíše nadpis kroku a počká na Enter,
# aby šlo workflow na přednášce procházet krok za krokem.
step() {
    echo
    echo "=== $1 ==="
    read -rp "(press Enter to continue)" _
}

# -----------------------------------------------------------------------------
# 0) Kontrola instalace
# Ollama běží jako server (služba) na portu 11434. Příkaz `ollama` je jen
# klient, který se k tomuto serveru připojuje.
# -----------------------------------------------------------------------------
step "0) Check installation"
ollama --version

# -----------------------------------------------------------------------------
# 1) Vyhledání modelu
# CLI nemá příkaz "search", modely se hledají na https://ollama.com/search.
# Tady stránku stáhneme curlem a vytáhneme z HTML názvy modelů.
# (Je to jen ukázka – HTML se může časem změnit.)
# -----------------------------------------------------------------------------
step "1) Search for models matching '$SEARCH_TERM'"
curl -s "https://ollama.com/search?q=${SEARCH_TERM}" \
    | grep -oE 'href="/library/[^"]+' \
    | sed 's|href="/library/||' \
    | sort -u

# Každý model má více variant (tagů) – liší se velikostí (1b, 4b, 12b…)
# a kvantizací (q4, q8, fp16). Menší = rychlejší, ale méně chytrý.
step "1b) Available tags (variants) of '$SEARCH_TERM'"
curl -s "https://ollama.com/library/${SEARCH_TERM}/tags" \
    | grep -oE "${SEARCH_TERM}:[A-Za-z0-9._-]+" \
    | sort -u | head -n 15

# -----------------------------------------------------------------------------
# 2) Stažení modelu
# `ollama pull` stáhne váhy do ~/.ollama/models (nebo do adresáře služby).
# Pokud model už máme, stáhnou se jen případné změny.
# -----------------------------------------------------------------------------
step "2) Download the model: $MODEL"
ollama pull "$MODEL"

# -----------------------------------------------------------------------------
# 3) Seznam lokálních modelů a informace o modelu
# `ollama show` ukáže architekturu, počet parametrů, délku kontextu,
# kvantizaci a licenci.
# -----------------------------------------------------------------------------
step "3) List local models"
ollama list

step "3b) Show model details"
ollama show "$MODEL"

# -----------------------------------------------------------------------------
# 4) Spuštění modelu
# a) Jednorázový dotaz – prompt předáme jako argument, model odpoví a skončí.
#    Přepínač --verbose vypíše i statistiky (tokeny za sekundu apod.).
# -----------------------------------------------------------------------------
step "4) One-shot prompt"
ollama run "$MODEL" --verbose "Explain in two sentences what a large language model is."

# b) Interaktivní chat – ukončíte ho příkazem /bye (nebo Ctrl+D).
#    Užitečné příkazy uvnitř chatu: /? (nápověda), /show info, /clear.
step "4b) Interactive chat (type /bye to exit)"
ollama run "$MODEL"

# -----------------------------------------------------------------------------
# 5) Běžící modely
# Model zůstává po použití nějakou dobu načtený v paměti (výchozí 5 minut),
# aby další dotaz nemusel čekat na načtení. `ollama ps` ukáže, kde běží
# (GPU / CPU) a kolik paměti zabírá.
# -----------------------------------------------------------------------------
step "5) Running models"
ollama ps

step "5b) Unload the model from memory"
ollama stop "$MODEL"
ollama ps

# -----------------------------------------------------------------------------
# 6) Smazání modelu (volitelné)
# Uvolní místo na disku. Ve výchozím stavu je zakomentováno.
# -----------------------------------------------------------------------------
# ollama rm "$MODEL"

echo
echo "Done."
