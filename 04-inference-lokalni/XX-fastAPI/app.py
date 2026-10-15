"""
app.py – vlastní API endpoint, který přeposílá zprávy Ollamě.

Tok dat:
    klient (curl / prohlížeč)  --POST /chat-->  naše FastAPI aplikace
    FastAPI aplikace           --POST /api/chat-->  Ollama (localhost:11434)
    odpověď Ollamy se uloží do fastapichat.txt a vrátí se klientovi

Endpointy:
    POST /chat      pošle zprávu modelu, vrátí odpověď
    GET  /history   vrátí obsah fastapichat.txt
    GET  /docs      automaticky vygenerovaná dokumentace – lze odtud i zkoušet!

Spuštění:  ./run.sh   (nebo .venv/bin/uvicorn app:app --reload --port 8001)
"""

import os
from datetime import datetime
from pathlib import Path

import requests
from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel

OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434")
MODEL = os.environ.get("MODEL", "gemma3:1b")
CHAT_FILE = Path(__file__).parent / "fastapichat.txt"

app = FastAPI(title="Ollama proxy", description="Send a message, get an answer from Ollama.")


# Pydantic modely popisují, jak vypadá JSON na vstupu a výstupu.
# FastAPI podle nich sám kontroluje data (špatný vstup -> chyba 422)
# a generuje dokumentaci na /docs.
class ChatRequest(BaseModel):
    message: str
    model: str = MODEL  # volitelné – když chybí, použije se výchozí model


class ChatResponse(BaseModel):
    model: str
    message: str
    answer: str


# Pozn.: funkce je obyčejná `def` (ne `async def`), protože `requests` je
# blokující knihovna. FastAPI ji pak spustí v samostatném vlákně, takže
# server mezitím může obsluhovat další požadavky.
@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    """Přepošle zprávu Ollamě, odpověď uloží do souboru a vrátí ji."""
    try:
        r = requests.post(
            f"{OLLAMA_URL}/api/chat",
            json={
                "model": request.model,
                "messages": [{"role": "user", "content": request.message}],
                "stream": False,
            },
            timeout=300,
        )
        r.raise_for_status()
    except requests.RequestException as e:
        # 502 Bad Gateway = chyba na straně serveru "za námi" (Ollamy).
        raise HTTPException(status_code=502, detail=f"Ollama error: {e}")

    answer = r.json()["message"]["content"]

    # Uložení do souboru – režim "a" (append) = připisuje na konec.
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with CHAT_FILE.open("a", encoding="utf-8") as f:
        f.write(f"[{timestamp}] model: {request.model}\n")
        f.write(f"You: {request.message}\n")
        f.write(f"AI:  {answer}\n\n")

    # Výpis do terminálu, kde běží server.
    print(f"\n>>> You: {request.message}\n<<< AI ({request.model}): {answer}\n")

    return ChatResponse(model=request.model, message=request.message, answer=answer)


@app.get("/history", response_class=PlainTextResponse)
def history() -> str:
    """Vrátí celý obsah fastapichat.txt jako prostý text."""
    if not CHAT_FILE.exists():
        return "(no messages yet)\n"
    return CHAT_FILE.read_text(encoding="utf-8")
