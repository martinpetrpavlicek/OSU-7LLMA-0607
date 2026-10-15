#!/usr/bin/env python3
"""
04_api.py – volání Ollamy přes REST API z Pythonu.

Dělá totéž co 03_curl.sh, jen v Pythonu pomocí knihovny `requests`
(instalace: pip install requests). Na konci je jednoduchý chat,
který si pamatuje historii konverzace.

Použití:  python3 04_api.py ["your question"]
          MODEL=mistral:7b python3 04_api.py
"""

import json
import os
import sys

import requests

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
MODEL = os.environ.get("MODEL", "gemma3:1b")


def list_models() -> list[str]:
    """Vrátí názvy lokálně stažených modelů (GET /api/tags)."""
    r = requests.get(f"{OLLAMA_URL}/api/tags")
    r.raise_for_status()  # Při HTTP chybě (404, 500…) vyhodí výjimku.
    return [m["name"] for m in r.json()["models"]]


def generate(prompt: str) -> dict:
    """Pošle jeden prompt a vrátí celou odpověď najednou (stream: False)."""
    r = requests.post(
        f"{OLLAMA_URL}/api/generate",
        json={"model": MODEL, "prompt": prompt, "stream": False},
    )
    r.raise_for_status()
    return r.json()


def generate_stream(prompt: str) -> None:
    """Streamovaná odpověď – vypisuje tokeny průběžně, jak přicházejí.

    Server posílá každý kousek odpovědi jako samostatný řádek JSON.
    """
    with requests.post(
        f"{OLLAMA_URL}/api/generate",
        json={"model": MODEL, "prompt": prompt},  # stream je ve výchozím stavu True
        stream=True,
    ) as r:
        r.raise_for_status()
        for line in r.iter_lines():
            if not line:
                continue
            chunk = json.loads(line)
            # flush=True – vypsat hned, ne až po naplnění bufferu.
            print(chunk["response"], end="", flush=True)
            if chunk.get("done"):
                break
    print()


def chat(messages: list[dict]) -> str:
    """Pošle celou historii konverzace (POST /api/chat) a vrátí odpověď modelu."""
    r = requests.post(
        f"{OLLAMA_URL}/api/chat",
        json={"model": MODEL, "messages": messages, "stream": False},
    )
    r.raise_for_status()
    return r.json()["message"]["content"]


def main() -> None:
    prompt = sys.argv[1] if len(sys.argv) > 1 else "Why is the sky blue? Answer in one sentence."

    # 1) Seznam modelů
    print("=== 1) Local models ===")
    for name in list_models():
        print(" -", name)

    # 2) Jednorázové generování + statistiky (časy jsou v nanosekundách)
    print("\n=== 2) Generate ===")
    print("Prompt:", prompt)
    result = generate(prompt)
    print("Answer:", result["response"])
    tokens_per_s = result["eval_count"] / (result["eval_duration"] / 1e9)
    print(f"Tokens generated: {result['eval_count']}, speed: {tokens_per_s:.0f} tokens/s")

    # 3) Streamování
    print("\n=== 3) Streaming ===")
    generate_stream(prompt)

    # 4) Interaktivní chat s pamětí
    # Historii držíme v seznamu `messages` a při každém dotazu ji posíláme celou.
    # Model sám žádný stav nemá – "paměť" je jen tento seznam.
    print("\n=== 4) Chat with history (type 'exit' to quit) ===")
    messages = [{"role": "system", "content": "You are a helpful assistant. Answer briefly."}]
    while True:
        try:
            question = input("You> ").strip()
        except (EOFError, KeyboardInterrupt):  # Ctrl+D / Ctrl+C
            break
        if not question:
            continue
        if question in ("exit", "quit"):
            break

        messages.append({"role": "user", "content": question})
        answer = chat(messages)
        messages.append({"role": "assistant", "content": answer})  # Uložíme i odpověď.
        print("AI>", answer)

    print("Bye.")


if __name__ == "__main__":
    main()
