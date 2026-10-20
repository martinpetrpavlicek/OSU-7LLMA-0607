#!/usr/bin/env python3
# -----------------------------------------------------------------
# Jednoduchy skript: precte vsechny .txt soubory ze slozky input/,
# kazdy posle lokalnimu modelu v Ollama a odpoved ulozi do output/
# pod stejnym nazvem souboru.
#
# Spusteni:   python3 analyza.py
# Potreba:    bezici Ollama (prikaz "ollama serve" nebo aplikace)
#             a stazeny model (napr. "ollama pull gemma3:1b")
# -----------------------------------------------------------------

import json
import urllib.request
from pathlib import Path

# ============ NASTAVENI - tady si upravte, co potrebujete ============

# Nazev modelu v Ollama (seznam modelu zobrazi prikaz: ollama list)
MODEL = "gemma3:1b"

# Instrukce pro model. Text ze souboru se pripoji pod tuto instrukci.
PROMPT = "Urci sentiment nasledujiciho textu (pozitivni, negativni, neutralni) a strucne zduvodni."

# Slozky se vstupem a vystupem
SLOZKA_VSTUP = Path("input")
SLOZKA_VYSTUP = Path("output")

# Adresa, na ktere bezi Ollama (vychozi nastaveni po instalaci)
OLLAMA_URL = "http://localhost:11434/api/generate"

# =====================================================================


def zeptej_se_ollamy(text):
    """Posle prompt + text do Ollama a vrati odpoved modelu jako retezec."""

    # Data, ktera Ollama ocekava (format JSON)
    data = {
        "model": MODEL,
        "prompt": PROMPT + "\n\n" + text,
        "stream": False,  # chceme celou odpoved najednou, ne po kouskach
    }

    # Sestavime HTTP pozadavek typu POST
    pozadavek = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
    )

    # Odesleme pozadavek a prijmeme odpoved (muze trvat i desitky sekund)
    with urllib.request.urlopen(pozadavek, timeout=600) as odpoved:
        vysledek = json.loads(odpoved.read().decode("utf-8"))

    # Samotny text odpovedi je v polozce "response"
    return vysledek["response"]


def main():
    # Vytvorime vystupni slozku, pokud jeste neexistuje
    SLOZKA_VYSTUP.mkdir(exist_ok=True)

    # Najdeme vsechny .txt soubory ve vstupni slozce (serazene podle nazvu)
    soubory = sorted(SLOZKA_VSTUP.glob("*.txt"))

    if not soubory:
        print(f"Ve slozce '{SLOZKA_VSTUP}' nejsou zadne .txt soubory.")
        return

    print(f"Model: {MODEL}")
    print(f"Nalezeno souboru: {len(soubory)}\n")

    # Projdeme soubory jeden po druhem
    for soubor in soubory:
        print(f"Zpracovavam: {soubor.name} ...", end=" ", flush=True)

        # Precteme obsah vstupniho souboru
        text = soubor.read_text(encoding="utf-8")

        # Zeptame se modelu
        odpoved = zeptej_se_ollamy(text)

        # Ulozime odpoved do output/ pod stejnym nazvem souboru
        vystupni_soubor = SLOZKA_VYSTUP / soubor.name
        vystupni_soubor.write_text(odpoved, encoding="utf-8")

        print("hotovo")

    print(f"\nVysledky jsou ve slozce '{SLOZKA_VYSTUP}'.")


# Tento blok se spusti jen pri primem spusteni skriptu
if __name__ == "__main__":
    main()
