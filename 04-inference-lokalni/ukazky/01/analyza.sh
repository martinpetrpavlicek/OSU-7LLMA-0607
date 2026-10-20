#!/bin/bash
# -----------------------------------------------------------------
# Bash varianta: precte vsechny .txt soubory ze slozky input/,
# kazdy posle modelu pres prikaz "ollama run" a odpoved ulozi
# do output/ pod stejnym nazvem souboru.
#
# Spusteni:   bash analyza.sh
# -----------------------------------------------------------------

# ============ NASTAVENI - tady si upravte, co potrebujete ============

MODEL="gemma3:1b"
PROMPT="Urci sentiment nasledujiciho textu (pozitivni, negativni, neutralni) a strucne zduvodni."
SLOZKA_VSTUP="input"
SLOZKA_VYSTUP="output"

# =====================================================================

# Vytvorime vystupni slozku, pokud jeste neexistuje
mkdir -p "$SLOZKA_VYSTUP"

echo "Model: $MODEL"

# Projdeme vsechny .txt soubory ve vstupni slozce
for soubor in "$SLOZKA_VSTUP"/*.txt; do

    # Pokud zadny .txt soubor neexistuje, smycka dostane doslovny vzor "*.txt"
    if [ ! -f "$soubor" ]; then
        echo "Ve slozce '$SLOZKA_VSTUP' nejsou zadne .txt soubory."
        exit 0
    fi

    # Jen nazev souboru bez cesty (napr. recenze1.txt)
    nazev=$(basename "$soubor")

    echo -n "Zpracovavam: $nazev ... "

    # Prompt a obsah souboru spojime a posleme modelu pres standardni vstup.
    # Odpoved modelu presmerujeme rovnou do vystupniho souboru.
    #   --nowordwrap  = model nevklada do textu ridici znaky pro zalamovani
    #   2>/dev/null   = schovame "tocici se" indikator prubehu (jde na stderr)
    { echo "$PROMPT"; echo; cat "$soubor"; } \
        | ollama run --nowordwrap "$MODEL" > "$SLOZKA_VYSTUP/$nazev" 2>/dev/null

    echo "hotovo"
done

echo
echo "Vysledky jsou ve slozce '$SLOZKA_VYSTUP'."
