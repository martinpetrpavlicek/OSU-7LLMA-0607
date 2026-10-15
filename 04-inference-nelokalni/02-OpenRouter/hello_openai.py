#!/usr/bin/env python3
"""
hello_openai.py – "Hello world" s OpenRouter API pomocí knihovny `openai`.

Totéž co hello.py, ale knihovna za nás řeší HTTP, hlavičky, JSON a chyby.
Navíc ukážeme streamování (odpověď přichází po kouscích).

Instalace: ./install.sh
Použití:   .venv/bin/python hello_openai.py ["your question"]
"""

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

# Načte .env (KEY=...) ze složky skriptu do proměnných prostředí.
load_dotenv(Path(__file__).parent / ".env")

MODEL = os.environ.get("MODEL", "deepseek/deepseek-v4-flash")

# OpenRouter je kompatibilní s OpenAI – stačí změnit adresu (base_url).
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=os.environ["KEY"])


def main() -> None:
    prompt = sys.argv[1] if len(sys.argv) > 1 else \
        "Say hello world and tell me which model you are, in one sentence."

    # 1) Celá odpověď najednou
    print("=== 1) Chat completion ===")
    response = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": prompt}],
    )
    print("Model: ", response.model)
    print("Answer:", response.choices[0].message.content)
    print(f"Tokens: prompt={response.usage.prompt_tokens}, "
          f"answer={response.usage.completion_tokens}")

    # 2) Streamování – stejné volání, jen stream=True.
    # Každý `chunk` nese v delta.content kousek textu.
    print("\n=== 2) Streaming ===")
    stream = client.chat.completions.create(
        model=MODEL,
        messages=[{"role": "user", "content": "Count from 1 to 10, words only."}],
        stream=True,
    )
    for chunk in stream:
        if chunk.choices and chunk.choices[0].delta.content:
            print(chunk.choices[0].delta.content, end="", flush=True)
    print()


if __name__ == "__main__":
    main()
