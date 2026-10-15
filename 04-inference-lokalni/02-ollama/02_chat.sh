#!/usr/bin/env bash
# =============================================================================
# 02_chat.sh – jednoduchý vstup/výstup s modelem v bashi
#
# Skript čte otázky ze standardního vstupu a posílá je modelu přes
# `ollama run`. Funguje interaktivně i v rouře (pipe):
#
#   ./02_chat.sh                              # interaktivně, konec = "exit"
#   echo "What is 2+2?" | ./02_chat.sh        # jeden dotaz z roury
#   ./02_chat.sh < questions.txt              # každý řádek = jeden dotaz
#
# Každá dvojice otázka–odpověď se uloží do souboru history.csv
# (sloupce: timestamp, model, question, answer).
#
# Pozor: každý dotaz je samostatný – model si nepamatuje předchozí otázky.
# (Paměť konverzace ukazuje až 03_curl.sh / 04_api.py přes /api/chat.)
# =============================================================================

set -euo pipefail

MODEL="${MODEL:-gemma3:1b}"     # Model lze změnit: MODEL=mistral:7b ./02_chat.sh

# Systémová instrukce – vložíme ji před každý dotaz, aby odpovědi byly krátké.
SYSTEM="Answer briefly, in at most three sentences."

HISTORY="${HISTORY:-history.csv}"   # Soubor s historií chatu.

# Pokud soubor ještě neexistuje, zapíšeme do něj hlavičku CSV.
[[ -f "$HISTORY" ]] || echo "timestamp,model,question,answer" > "$HISTORY"

# Pomocná funkce: připraví text jako jedno pole CSV.
# Pravidla CSV: pole obalíme uvozovkami a každou uvozovku uvnitř zdvojíme
# (" -> ""). Díky tomu mohou být v textu i čárky a nové řádky.
csv_field() {
    local text="${1//\"/\"\"}"
    printf '"%s"' "$text"
}

# Dočasný soubor pro zachycení odpovědi; po skončení skriptu se smaže.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# Smyčka: `read -r` načte jeden řádek do proměnné $question.
# `-p` zobrazí výzvu (prompt); při čtení z roury se výzva neukáže.
while read -rp "You> " question; do

    # Prázdný řádek přeskočíme.
    [[ -z "$question" ]] && continue

    # Klíčová slova pro ukončení.
    [[ "$question" == "exit" || "$question" == "quit" ]] && break

    echo -n "AI> "
    # Prompt předáme jako argument – `ollama run` pak odpoví a skončí.
    # `< /dev/null` zajistí, že ollama nesní zbytek našeho stdin
    # (jinak by při čtení ze souboru spolkla další otázky).
    # `--nowordwrap` vypne zalamování řádků – jinak by se do odpovědi
    # dostaly řídicí znaky terminálu a rozbily by nám CSV.
    ollama run --nowordwrap "$MODEL" "$SYSTEM

$question" < /dev/null | tee "$TMP"
    # `tee` odpověď zároveň vypisuje na obrazovku a ukládá do $TMP,
    # takže ji uživatel vidí průběžně a my ji pak můžeme zapsat do CSV.
    echo

    answer=$(< "$TMP")                     # Načteme celou odpověď ze souboru.
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Připíšeme (>>) jeden řádek do CSV.
    printf '%s,%s,%s,%s\n' \
        "$(csv_field "$timestamp")" \
        "$(csv_field "$MODEL")" \
        "$(csv_field "$question")" \
        "$(csv_field "$answer")" >> "$HISTORY"
done

echo "Bye. Chat saved to $HISTORY"
