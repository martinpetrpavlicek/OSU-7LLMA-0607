#!/usr/bin/env bash
# =============================================================================
# 02_serve.sh – spuštění vLLM serveru s OpenAI-kompatibilním API
#
# `vllm serve` stáhne model z Hugging Face (při prvním spuštění), načte ho
# do GPU a spustí HTTP server na http://localhost:8000/v1
# Server běží v popředí – ukončíme ho Ctrl+C.
# Dotazy posíláme z jiného terminálu (03_curl.sh, 04_client.py).
#
# Použití:  ./02_serve.sh [model]
#           (výchozí model: Qwen/Qwen2.5-1.5B-Instruct, ~3 GB)
# =============================================================================

set -euo pipefail

MODEL="${1:-Qwen/Qwen2.5-1.5B-Instruct}"
PORT="${PORT:-8000}"
GPU_MEM="${GPU_MEM:-0.5}"       # Podíl VRAM pro vLLM, např. GPU_MEM=0.3 ./02_serve.sh

# Použijeme venv z 01_install.sh (pokud ještě není aktivní).
source "$(dirname "$0")/.venv/bin/activate"

# Máme-li víc GPU, vybereme jen jednu (číslování od 0).
export CUDA_VISIBLE_DEVICES="${CUDA_VISIBLE_DEVICES:-0}"

# Sampler z FlashInfer se při prvním dotazu kompiluje a potřebuje nainstalovaný
# CUDA toolkit (nvcc). Vypneme ho – vLLM pak použije sampler z PyTorch.
export VLLM_USE_FLASHINFER_SAMPLER=0

# Parametry:
#   --max-model-len           maximální délka kontextu (prompt + odpověď) v tokenech;
#                             menší = méně paměti na KV cache
#   --gpu-memory-utilization  kolik VRAM si vLLM zabere (0.0–1.0). vLLM si paměť
#                             alokuje předem: váhy modelu + KV cache pro dávky.
#                             Chyba "Free memory ... is less than desired" = GPU
#                             používá někdo jiný -> sniž GPU_MEM (nvidia-smi ukáže kdo).
#   --served-model-name       jméno, kterým model oslovujeme v API (pole "model")
echo "=== Starting vLLM: $MODEL on http://localhost:$PORT/v1 (Ctrl+C to stop) ==="
vllm serve "$MODEL" \
    --port "$PORT" \
    --max-model-len 4096 \
    --gpu-memory-utilization "$GPU_MEM" \
    --served-model-name "$MODEL"
