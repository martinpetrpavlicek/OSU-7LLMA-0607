#!/usr/bin/env python3
"""
chat_stateful.py – konverzace, kterou si pamatuje SERVER (OpenAI Responses API).

Srovnání s chat.py:
  chat.py           historii držíme my a posíláme ji pokaždé celou (Chat Completions)
  chat_stateful.py  OpenAI si odpovědi uloží; posíláme jen NOVOU otázku
                    a ID předchozí odpovědi (previous_response_id)

Pozor:
  - je to specialita OpenAI – OpenRouter, vLLM ani Ollama to neumí,
  - model stejně "čte" celou historii, takže vstupní tokeny (a cena) rostou
    úplně stejně – jen je nemusíme posílat po síti my,
  - konverzace je uložená u OpenAI (soukromí!).

Instalace: ./install.sh
Použití:   .venv/bin/python chat_stateful.py
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv(Path(__file__).parent / ".env")

MODEL = os.environ.get("MODEL", "gpt-6-luna")
client = OpenAI(api_key=os.environ["KEY"])


def main() -> None:
    previous_id = None  # ID poslední odpovědi = "ukazatel" na konverzaci na serveru
    print(f"Stateful chat with {MODEL} (Responses API). Type 'exit' to quit.")

    while True:
        try:
            question = input("\nYou> ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not question:
            continue
        if question in ("exit", "quit"):
            break

        response = client.responses.create(
            model=MODEL,
            instructions="You are a friendly tutor. Answer briefly, in 1-3 sentences.",
            input=question,                     # posíláme JEN novou otázku
            previous_response_id=previous_id,   # server si dohledá zbytek konverzace
        )
        previous_id = response.id

        print("AI>", response.output_text)
        print(f"   [response id: {response.id}, input tokens: {response.usage.input_tokens}, "
              f"output tokens: {response.usage.output_tokens}]")

    print("Bye.")


if __name__ == "__main__":
    main()
