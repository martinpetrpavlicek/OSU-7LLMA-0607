#!/usr/bin/env bash
# =============================================================================
# run.sh – spustí FastAPI aplikaci (app.py) serverem uvicorn
#
#   app:app   = soubor app.py, proměnná `app` v něm
#   --reload  = po uložení změn v app.py se server sám restartuje
#   --port    = 8001 (port 8000 používá vLLM)
#
# Server běží v popředí – ukončíme ho Ctrl+C.
# Pak otevřete v prohlížeči http://localhost:8001/docs
# nebo spusťte ./send.sh "your message" v jiném terminálu.
#
# Použití:  ./run.sh
#           MODEL=mistral:7b ./run.sh
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

.venv/bin/uvicorn app:app --reload --port 8001
