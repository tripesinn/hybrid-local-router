#!/usr/bin/env bash
# =============================================================================
# deploy_api.sh — Deploie le serveur LLM local pour Hybrid Router Agent
# =============================================================================
# Supporte : oMLX (macOS), Ollama, vLLM
# Usage :
#   ./scripts/deploy_api.sh              # Démarre avec le backend détecté/configuré
#   ./scripts/deploy_api.sh --stop       # Arrête le serveur
#   ./scripts/deploy_api.sh --status     # Vérifie si le serveur tourne
#   ./scripts/deploy_api.sh --backend ollama  # Force un backend spécifique
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PLUGIN_DIR/.env"

# === Couleurs ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# === Chargement du .env ===
load_env() {
    if [[ -f "$ENV_FILE" ]]; then
        set -a
        source "$ENV_FILE"
        set +a
    fi
}

# === Détection automatique du backend ===
detect_backend() {
    local os
    os="$(uname -s)"

    # 1. Backend explicite dans .env
    if [[ -n "${LOCAL_AI_BACKEND:-}" ]]; then
        echo "$LOCAL_AI_BACKEND"
        return
    fi

    # 2. oMLX — macOS uniquement
    if [[ "$os" == "Darwin" ]] && ls /Applications/oMLX.app >/dev/null 2>&1; then
        echo "omlx"
        return
    fi

    # 3. Ollama — vérifié par la présence du binaire
    if command -v ollama >/dev/null 2>&1; then
        echo "ollama"
        return
    fi

    # 4. vLLM — tentative (le module Python doit être installé)
    if python3 -c "import vllm" >/dev/null 2>&1; then
        echo "vllm"
        return
    fi

    echo "unknown"
}

# === Configuration par backend ===
config_for_backend() {
    local backend="$1"
    case "$backend" in
        omlx)
            OMX_PORT="${LOCAL_AI_PORT:-8000}"
            OMX_MODEL="${LOCAL_AI_MODEL:-Qwen3.5-9B-MLX-4bit}"
            OMX_BASE_PATH="${LOCAL_AI_BASE_PATH:-$HOME/.omlx}"
            OMX_APP="/Applications/oMLX.app"
            OMX_PYTHON="$OMX_APP/Contents/MacOS/python3"
            ;;
        ollama)
            OL_PORT="${LOCAL_AI_PORT:-11434}"
            OL_MODEL="${LOCAL_AI_MODEL:-phi4}"
            ;;
        vllm)
            VL_PORT="${LOCAL_AI_PORT:-8000}"
            VL_MODEL="${LOCAL_AI_MODEL:-mlx-community/phi-4-4bit}"
            VL_GPU="${LOCAL_AI_GPU_MEM:-0.9}"
            VL_TENSOR="${LOCAL_AI_TENSOR_PARALLEL:-1}"
            ;;
    esac
}

# === Actions ===

start_omlx() {
    echo -e "${CYAN}[oMLX] Démarrage du serveur MLX sur le port $OMX_PORT...${NC}"

    if [[ ! -d "$OMX_APP" ]]; then
        echo -e "${RED}[oMLX] Application introuvable : $OMX_APP${NC}"
        echo "  Télécharger oMLX : https://github.com/nickwild/omlx"
        exit 1
    fi

    if ! pgrep -f "omlx.cli serve" >/dev/null 2>&1; then
        nohup "$OMX_PYTHON" -m omlx.cli serve \
            --base-path "$OMX_BASE_PATH" \
            --port "$OMX_PORT" \
            > "$PLUGIN_DIR/logs/omlx.log" 2>&1 &

        echo -e "${YELLOW}[oMLX] Attente du démarrage (max 30s)...${NC}"
        for i in $(seq 1 30); do
            if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$OMX_PORT/v1/models" 2>/dev/null | grep -q "200\|401"; then
                echo -e "${GREEN}[oMLX] Serveur prêt — http://127.0.0.1:$OMX_PORT/v1${NC}"
                echo "  Modèle : $OMX_MODEL"
                return 0
            fi
            sleep 1
        done
        echo -e "${RED}[oMLX] Timeout — le serveur n'a pas démarré dans les 30s${NC}"
        echo "  Logs : $PLUGIN_DIR/logs/omlx.log"
        exit 1
    else
        echo -e "${YELLOW}[oMLX] Déjà en cours d'exécution${NC}"
    fi
}

start_ollama() {
    echo -e "${CYAN}[Ollama] Démarrage du serveur...${NC}"

    if ! command -v ollama >/dev/null 2>&1; then
        echo -e "${RED}[Ollama] Binaire 'ollama' introuvable${NC}"
        echo "  Installer : curl -fsSL https://ollama.com/install.sh | sh"
        exit 1
    fi

    # Démarrer le service si besoin
    if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
        nohup ollama serve > "$PLUGIN_DIR/logs/ollama.log" 2>&1 &
        sleep 2
    fi

    # Pull le modèle s'il n'est pas déjà là
    if ! ollama list 2>/dev/null | grep -q "$OL_MODEL"; then
        echo -e "${YELLOW}[Ollama] Téléchargement du modèle $OL_MODEL...${NC}"
        ollama pull "$OL_MODEL"
    fi

    echo -e "${GREEN}[Ollama] Prêt — http://127.0.0.1:$OL_PORT/v1${NC}"
    echo "  Modèle : $OL_MODEL"
}

start_vllm() {
    echo -e "${CYAN}[vLLM] Démarrage du serveur sur le port $VL_PORT...${NC}"

    if ! python3 -c "import vllm" >/dev/null 2>&1; then
        echo -e "${RED}[vLLM] Module Python 'vllm' introuvable${NC}"
        echo "  Installer : pip install vllm"
        exit 1
    fi

    if ! pgrep -f "vllm.entrypoints.openai.api_server" >/dev/null 2>&1; then
        nohup python3 -m vllm.entrypoints.openai.api_server \
            --model "$VL_MODEL" \
            --port "$VL_PORT" \
            --gpu-memory-utilization "$VL_GPU" \
            --tensor-parallel-size "$VL_TENSOR" \
            > "$PLUGIN_DIR/logs/vllm.log" 2>&1 &

        echo -e "${YELLOW}[vLLM] Chargement du modèle (peut prendre plusieurs minutes)...${NC}"
        for i in $(seq 1 120); do
            if curl -s -o /dev/null "http://127.0.0.1:$VL_PORT/v1/models" 2>/dev/null; then
                echo -e "${GREEN}[vLLM] Prêt — http://127.0.0.1:$VL_PORT/v1${NC}"
                echo "  Modèle : $VL_MODEL"
                return 0
            fi
            sleep 2
        done
        echo -e "${RED}[vLLM] Timeout (4 min)${NC}"
        exit 1
    else
        echo -e "${YELLOW}[vLLM] Déjà en cours d'exécution${NC}"
    fi
}

stop_server() {
    echo -e "${YELLOW}Arrêt du serveur local...${NC}"

    if pgrep -f "omlx.cli serve" >/dev/null 2>&1; then
        pkill -f "omlx.cli serve" && echo "  oMLX arrêté"
    fi
    if pgrep -f "ollama serve" >/dev/null 2>&1; then
        pkill -f "ollama serve" && echo "  Ollama arrêté"
    fi
    if pgrep -f "vllm.entrypoints.openai.api_server" >/dev/null 2>&1; then
        pkill -f "vllm.entrypoints.openai.api_server" && echo "  vLLM arrêté"
    fi
}

check_status() {
    local port="${LOCAL_AI_PORT:-8000}"

    if curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$port/v1/models" 2>/dev/null; then
        echo -e "${GREEN}✓ Serveur local actif — http://127.0.0.1:$port/v1${NC}"
        curl -s "http://127.0.0.1:$port/v1/models" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data.get('data', data) if isinstance(data, dict) else data
if isinstance(models, list):
    for m in models:
        name = m.get('id', m) if isinstance(m, dict) else str(m)
        print(f'  Modèle: {name}')
" 2>/dev/null || true
        return 0
    else
        echo -e "${RED}✗ Aucun serveur local détecté sur le port $port${NC}"
        return 1
    fi
}

# === Main ===
main() {
    load_env
    mkdir -p "$PLUGIN_DIR/logs"

    local action="${1:-start}"
    local backend="${2:-}"

    case "$action" in
        --stop|stop)
            stop_server
            exit 0
            ;;
        --status|status)
            check_status
            exit $?
            ;;
        --backend|-b)
            shift
            backend="${1:-}"
            action="start"
            ;;
        --help|-h)
            echo "Usage: $0 [start|--stop|--status] [--backend omlx|ollama|vllm]"
            echo ""
            echo "Backends supportés :"
            echo "  omlx    — macOS avec l'app oMLX"
            echo "  ollama  — Ollama (multi-plateforme)"
            echo "  vllm    — vLLM (Linux recommandé)"
            echo ""
            echo "Configuration via .env :"
            echo "  LOCAL_AI_BACKEND   — Force un backend"
            echo "  LOCAL_AI_PORT      — Port du serveur (défaut: 8000)"
            echo "  LOCAL_AI_MODEL     — Nom du modèle à charger"
            echo "  LOCAL_AI_GPU_MEM   — vLLM uniquement (défaut: 0.9)"
            exit 0
            ;;
    esac

    # Si aucun backend spécifié, détection automatique
    if [[ -z "$backend" ]]; then
        backend="$(detect_backend)"
    fi

    if [[ "$backend" == "unknown" ]]; then
        echo -e "${RED}Aucun backend compatible détecté.${NC}"
        echo ""
        echo "Installez l'un des serveurs suivants :"
        echo "  • oMLX (macOS) : https://github.com/nickwild/omlx"
        echo "  • Ollama       : curl -fsSL https://ollama.com/install.sh | sh"
        echo "  • vLLM         : pip install vllm"
        echo ""
        echo "Ou forcez un backend : $0 --backend ollama"
        exit 1
    fi

    echo -e "${CYAN}Backend détecté : $backend${NC}"
    config_for_backend "$backend"

    case "$backend" in
        omlx)   start_omlx ;;
        ollama) start_ollama ;;
        vllm)   start_vllm ;;
        *)
            echo -e "${RED}Backend inconnu : $backend${NC}"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}═══ Serveur local prêt ═══${NC}"
    echo "  URL à configurer dans .env :"
    echo "  LOCAL_AI_URL=http://127.0.0.1:${LOCAL_AI_PORT:-8000}/v1/chat/completions"
}

main "$@"
