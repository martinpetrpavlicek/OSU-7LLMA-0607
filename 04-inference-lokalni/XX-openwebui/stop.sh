#!/usr/bin/env bash
# =============================================================================
# stop.sh – zastaví a odstraní kontejner Open WebUI
#
# Data (chaty, nastavení) zůstanou ve svazku "open-webui".
# Úplné smazání včetně dat:  docker compose down -v
# =============================================================================

set -euo pipefail
cd "$(dirname "$0")"

docker compose down
