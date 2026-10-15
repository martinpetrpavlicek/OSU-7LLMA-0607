#!/usr/bin/env python3
"""
chat.py – delší konverzace s pamětí (historii držíme my, na straně klienta).

Důležité: API je BEZESTAVOVÉ – model si mezi dotazy nic nepamatuje.
"Paměť" vzniká tak, že při každém dotazu pošleme CELOU dosavadní konverzaci
(seznam `messages`). Proto s každým kolem roste počet vstupních tokenů
(prompt tokens) – a tím i cena a doba odpovědi. Sledujte čísla po každé odpovědi!

Příkazy:  /history  vypíše, co se posílá modelu
          /reset    smaže historii (model "zapomene")
          exit      konec

Instalace: ./install.sh
Použití:   .venv/bin/python chat.py
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv(Path(__file__).parent / ".env")

MODEL = os.environ.get("MODEL", "deepseek/deepseek-v4-flash")
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=os.environ["KEY"])

# Systémová zpráva – instrukce, jak se má model chovat. Posílá se vždy jako první.
SYSTEM = {"role": "system", "content": "You are a friendly tutor. Answer briefly, in 1-3 sentences."}


def main() -> None:
    messages = [SYSTEM]
    total_tokens = 0
    print(f"Chat with {MODEL}. Commands: /history, /reset, exit")

    while True:
        try:
            question = input("\nYou> ").strip()
        except (EOFError, KeyboardInterrupt):  # Ctrl+D / Ctrl+C
            break
        if not question:
            continue
        if question in ("exit", "quit"):
            break
        if question == "/reset":
            messages = [SYSTEM]
            print("(history cleared – the model forgot everything)")
            continue
        if question == "/history":
            for m in messages:
                print(f"  [{m['role']}] {m['content']}")
            continue

        messages.append({"role": "user", "content": question})

        # Posíláme CELOU historii. Odpověď streamujeme;
        # include_usage = na konci streamu přijde i počet tokenů.
        stream = client.chat.completions.create(
            model=MODEL,
            messages=messages,
            stream=True,
            stream_options={"include_usage": True},
        )

        print("AI> ", end="", flush=True)
        answer = ""
        usage = None
        for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                text = chunk.choices[0].delta.content
                print(text, end="", flush=True)
                answer += text
            if chunk.usage:  # poslední chunk nese statistiky
                usage = chunk.usage
        print()

        # Odpověď modelu musíme uložit taky – jinak by ji příště "neviděl".
        messages.append({"role": "assistant", "content": answer})

        if usage:
            total_tokens += usage.total_tokens
            print(f"   [messages sent: {len(messages) - 1}, "
                  f"prompt tokens: {usage.prompt_tokens}, answer tokens: {usage.completion_tokens}, "
                  f"total so far: {total_tokens}]")

    print("Bye.")


if __name__ == "__main__":
    main()
