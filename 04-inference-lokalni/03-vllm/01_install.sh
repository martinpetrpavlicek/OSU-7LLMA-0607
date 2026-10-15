#!/usr/bin/env bash
# =============================================================================
# 01_install.sh – instalace vLLM do virtuálního prostředí (venv) pomocí pip
#
# vLLM je Python knihovna + server pro rychlé inferování LLM na GPU (NVIDIA).
# Nainstalujeme ji do vlastního venv, aby nekolidovala se systémovým Pythonem.
#
# Použití:  ./01_install.sh
# Potom:    source .venv/bin/activate
# =============================================================================

set -euo pipefail

VENV_DIR="${VENV_DIR:-.venv}"

# vLLM má hotové balíčky (wheels) jen pro některé verze Pythonu.
# Nejbezpečnější volba je Python 3.12 – pokud ho máme, použijeme ho.
if command -v python3.12 >/dev/null; then
    PYTHON=python3.12
else
    PYTHON=python3
fi
echo "=== Using $($PYTHON --version) ==="

# -----------------------------------------------------------------------------
# 1) Vytvoření virtuálního prostředí
# venv = samostatná složka s vlastním Pythonem a vlastními balíčky.
# -----------------------------------------------------------------------------
echo "=== 1) Create venv in $VENV_DIR ==="
"$PYTHON" -m venv "$VENV_DIR"

# Aktivace: od teď `python` a `pip` znamenají ty z .venv.
source "$VENV_DIR/bin/activate"

# -----------------------------------------------------------------------------
# 2) Instalace balíčků
#   vllm   – server + knihovna (stáhne i PyTorch s CUDA, několik GB!)
#   openai – oficiální klient; vLLM má API kompatibilní s OpenAI,
#            takže stejný kód funguje s OpenAI, vLLM, LM Studiem, Ollamou…
# -----------------------------------------------------------------------------
echo "=== 2) Install vllm + openai (this takes a few minutes) ==="
pip install --upgrade pip
pip install vllm openai

# -----------------------------------------------------------------------------
# 3) Kontrola
# -----------------------------------------------------------------------------
echo "=== 3) Check ==="
python -c "import vllm, torch; print('vllm', vllm.__version__, '| torch', torch.__version__, '| CUDA available:', torch.cuda.is_available())"

echo
echo "Done. Activate the environment with:  source $VENV_DIR/bin/activate"
