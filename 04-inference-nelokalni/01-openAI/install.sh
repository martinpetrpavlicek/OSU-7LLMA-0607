#!/usr/bin/env bash
# =============================================================================
# install.sh – vytvoří virtuální prostředí (venv) a nainstaluje knihovny
#
# Knihovny jsou v requirements.txt:
#   openai         – oficiální klient (funguje s OpenAI i OpenRouterem, vLLM…)
#   python-dotenv  – načte API klíč ze souboru .env
#
# Použití:  ./install.sh
# Potom:    .venv/bin/python hello_openai.py
#           (nebo: source .venv/bin/activate && python hello_openai.py)
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

echo "=== 1) Create venv in .venv ==="
python3 -m venv .venv

echo "=== 2) Install requirements.txt ==="
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt

echo
echo "Done. Run e.g.:  .venv/bin/python hello_openai.py"
