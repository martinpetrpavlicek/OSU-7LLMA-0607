#!/usr/bin/env python3
"""
04_client.py – volání vLLM serveru z Pythonu pomocí knihovny `openai`.

vLLM má API kompatibilní s OpenAI, takže použijeme oficiálního klienta
`openai` – jen mu změníme adresu (base_url). Stejný kód by fungoval
i proti OpenAI, LM Studiu nebo Ollamě.

Server musí běžet (./02_serve.sh v jiném terminálu).

Použití:  source .venv/bin/activate
          python 04_client.py ["your question"]
"""

import os
import sys
import time

from openai import OpenAI

VLLM_URL = os.environ.get("VLLM_URL", "http://localhost:8000")

# api_key je povinný parametr, ale vLLM ho (bez --api-key) nekontroluje.
client = OpenAI(base_url=f"{VLLM_URL}/v1", api_key="not-needed")


def get_model() -> str:
    """Vrátí jméno modelu, který server obsluhuje (GET /v1/models)."""
    return client.models.list().data[0].id


def ask(model: str, prompt: str) -> None:
    """Jeden dotaz, celá odpověď najednou."""
    start = time.time()
    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are a helpful assistant. Answer briefly."},
            {"role": "user", "content": prompt},
        ],
        max_tokens=200,
        temperature=0.7,
    )
    elapsed = time.time() - start

    print("Answer:", response.choices[0].message.content)
    tokens = response.usage.completion_tokens
    print(f"Tokens generated: {tokens}, speed: {tokens / elapsed:.0f} tokens/s")


def ask_stream(model: str, prompt: str) -> None:
    """Streamovaná odpověď – vypisuje text průběžně, jak přichází."""
    stream = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=200,
        stream=True,
    )
    # Každý `chunk` nese v delta.content kousek textu (jeden nebo pár tokenů).
    for chunk in stream:
        text = chunk.choices[0].delta.content
        if text:
            print(text, end="", flush=True)  # flush=True – vypsat hned
    print()


def chat_loop(model: str) -> None:
    """Interaktivní chat s pamětí a streamovanými odpověďmi.

    Model sám žádný stav nemá – "paměť" je jen seznam `messages`,
    který posíláme při každém dotazu celý.
    """
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

        print("AI> ", end="", flush=True)
        answer = ""
        stream = client.chat.completions.create(model=model, messages=messages, stream=True)
        for chunk in stream:
            text = chunk.choices[0].delta.content or ""
            print(text, end="", flush=True)
            answer += text
        print()

        messages.append({"role": "assistant", "content": answer})  # Uložíme i odpověď.

    print("Bye.")


def main() -> None:
    prompt = sys.argv[1] if len(sys.argv) > 1 else "Why is the sky blue? Answer in one sentence."

    print("=== 1) Model on the server ===")
    model = get_model()
    print(model)

    print("\n=== 2) Chat completion ===")
    print("Prompt:", prompt)
    ask(model, prompt)

    print("\n=== 3) Streaming ===")
    ask_stream(model, prompt)

    print("\n=== 4) Chat with history (type 'exit' to quit) ===")
    chat_loop(model)


if __name__ == "__main__":
    main()
