#!/usr/bin/env python3
"""
hello.py – "Hello world" s OpenRouter API v čistém Pythonu (jen standardní knihovna).

OpenRouter = jedno API (kompatibilní s OpenAI) pro stovky modelů od různých
firem. Model se vybírá jménem "firma/model", seznam: https://openrouter.ai/models

Žádné `pip install` – HTTP požadavek pošleme přes urllib a JSON zpracujeme
modulem json. API klíč se načte ze souboru .env (řádek KEY=...) ve stejné složce.

Použití:  python3 hello.py ["your question"]
          MODEL=openai/gpt-5-nano python3 hello.py
"""

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

MODEL = os.environ.get("MODEL", "deepseek/deepseek-v4-flash")  # malý a levný model
URL = "https://openrouter.ai/api/v1/chat/completions"


def load_key() -> str:
    """Najde v .env řádek KEY=... a vrátí hodnotu (bez uvozovek)."""
    env_file = Path(__file__).parent / ".env"
    for line in env_file.read_text().splitlines():
        if line.startswith("KEY="):
            return line.split("=", 1)[1].strip().strip("\"'")
    sys.exit("KEY not found in .env")


def main() -> None:
    prompt = sys.argv[1] if len(sys.argv) > 1 else \
        "Say hello world and tell me which model you are, in one sentence."

    # Tělo požadavku – stejný formát jako u OpenAI, jen jiná adresa (URL).
    body = {"model": MODEL, "messages": [{"role": "user", "content": prompt}]}

    request = urllib.request.Request(
        URL,
        data=json.dumps(body).encode(),  # dict -> JSON text -> bajty
        headers={
            "Authorization": f"Bearer {load_key()}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request) as response:
            result = json.load(response)
    except urllib.error.HTTPError as e:
        # Při chybě (špatný klíč, neexistující model, málo kreditu…) přijde JSON s popisem.
        sys.exit(f"Error {e.code}: {json.load(e)['error']['message']}")

    print("Model:   ", result["model"])
    # OpenRouter navíc vrací, který poskytovatel (provider) dotaz skutečně obsloužil.
    print("Provider:", result.get("provider", "?"))
    print("Answer:  ", result["choices"][0]["message"]["content"])
    usage = result["usage"]
    print(f"Tokens: prompt={usage['prompt_tokens']}, answer={usage['completion_tokens']}")


if __name__ == "__main__":
    main()
