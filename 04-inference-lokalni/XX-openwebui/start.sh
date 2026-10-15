#!/usr/bin/env bash
# =============================================================================
# start.sh – stáhne (poprvé) a spustí Open WebUI v Dockeru
#
# Ollama musí běžet (systemctl status ollama) a mít stažený model (ollama list).
# První start trvá déle – obraz má několik GB a aplikace se inicializuje.
#
# Použití:  ./start.sh
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

echo "=== 1) Check Ollama ==="
curl -sf http://127.0.0.1:11434/api/version || { echo "Ollama is not running!"; exit 1; }
echo

# Docker smí ovládat jen root nebo členové skupiny "docker".
# Členství ve skupině se projeví až po novém přihlášení (odhlásit/přihlásit nebo `su - $USER`).
if ! docker info >/dev/null 2>&1; then
    echo "Cannot talk to Docker (permission denied?). Fix:"
    echo "  sudo usermod -aG docker \$USER   # add yourself to the docker group (once)"
    echo "  su - \$USER                     # new login shell with the group (or log out/in)"
    exit 1
fi

echo "=== 2) Start container (docker compose up -d) ==="
docker compose up -d     # -d = na pozadí

echo "=== 3) Wait until the web is ready ==="
until curl -sf http://localhost:3000/health >/dev/null; do
    printf "."
    sleep 2
done
echo
echo "Open WebUI is running:  http://localhost:3000"
echo "Logs:  docker compose logs -f      Stop:  ./stop.sh"
