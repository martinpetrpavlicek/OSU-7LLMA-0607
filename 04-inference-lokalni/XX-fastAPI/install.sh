#!/usr/bin/env bash
# =============================================================================
# install.sh – vytvoří virtuální prostředí (venv) a nainstaluje knihovny
#
# Knihovny jsou v requirements.txt:
#   fastapi   – framework pro tvorbu webového API (endpointů)
#   uvicorn   – webový server, který FastAPI aplikaci spustí
#   requests  – posílání HTTP požadavků (my je posíláme dál Ollamě)
#
# Použití:  ./install.sh
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

echo "=== 1) Create venv in .venv ==="
python3 -m venv .venv

echo "=== 2) Install requirements.txt ==="
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo
echo "Done. Start the server with:  ./run.sh"
