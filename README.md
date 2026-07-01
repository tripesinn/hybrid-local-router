# Hybrid Router Agent (Cloud + Local AI)

> 🚀 **An intelligent hybrid router that proactively delegates token-heavy tasks (summarization, bulk translation, documentation, and code correction) to a local LLM to save cloud costs, with seamless cloud fallback.**
>
> 🧠 **Now adapted for Hermes Agent** — the open-source AI agent framework by Nous Research. Works with DeepSeek, Claude, Grok, and any OpenAI-compatible local LLM (oMLX, Ollama, vLLM).

*Read this in: [English](#english-documentation) | [Français (French)](#documentation-en-français)*

---

## English Documentation

### Overview
**Hybrid Router Agent** is a skill/plugin designed for AI agent frameworks (Antigravity 2.0 and **Hermes Agent**).
It enables the cloud-hosted LLM to act as a **Smart Router**, delegating heavy computation, massive text processing, and standard code formatting/corrections to a local LLM (such as oMLX, Phi-4, Llama-3, or Mistral running locally) through a standard OpenAI-compatible API.

By offloading these heavy tasks **only when justified**, the agent saves significant cloud credits while keeping the cloud model as the high-level reasoning "orchestrator" for complex architecture and multi-file logic.

### Key Features
- 🧠 **Proactive Routing**: Automatically identifies and intercepts heavy workloads (inputs > 500 words / 1500 tokens).
- 🛠️ **Automated Code Correction**: Offloads lint fixes and standard refactoring to the local model via `apply_local_ai.py`, which safely creates a `.bak` backup before writing.
- 📂 **Zero-Dependency Scripts**: The query scripts use `requests` and standard libraries.
- 🛡️ **Seamless Fallback**: If the local AI is offline, timed out, or returns an error, the agent gracefully falls back to the Cloud LLM to complete the task without user friction.
- 🚀 **Multi-Backend Deploy**: `deploy_api.sh` launches your local LLM server — supports oMLX (macOS), Ollama, and vLLM.

### Project Structure
```text
hybrid-router-plugin/
├── AGENTS.md                      # Gemini rules to proactively delegate tasks
├── README.md                      # Documentation (this file)
├── .env.example                   # Environment configuration template
├── scripts/
│   ├── query_local_ai.py          # Script for general queries to the local LLM
│   ├── apply_local_ai.py          # Script to safely apply local AI code edits
│   └── deploy_api.sh              # Deploy/local-launch the LLM server (oMLX, Ollama, vLLM)
└── .agents/
    └── skills/
        └── local-corrector/
            └── SKILL.md           # System instructions giving routing behavior
```

### Command Line Usage
You can test the Python scripts manually from your terminal:

**Query the Local AI:**
```bash
python3 scripts/query_local_ai.py "Explain how quantum computing works" "You are a helpful assistant"
```

**Apply a code correction via Local AI:**
```bash
python3 scripts/apply_local_ai.py src/main.js "Refactor this file to use arrow functions"
```

### Deploy API (Local LLM Server)

The `deploy_api.sh` script automates launching your local LLM server so the hybrid router can reach it. Supports three backends:

| Backend | Platform | Command |
|---------|----------|---------|
| **oMLX** | macOS | `./scripts/deploy_api.sh` (auto-detect) |
| **Ollama** | macOS / Linux / Windows | `./scripts/deploy_api.sh --backend ollama` |
| **vLLM** | Linux (GPU) | `./scripts/deploy_api.sh --backend vllm` |

```bash
# Auto-detect and start the server
./scripts/deploy_api.sh

# Check if the server is running
./scripts/deploy_api.sh --status

# Stop the server
./scripts/deploy_api.sh --stop

# Force a specific backend
./scripts/deploy_api.sh --backend ollama
```

**Configuration** (in `.env`):
```ini
# Force a backend (omlx, ollama, vllm) or leave empty for auto-detect
LOCAL_AI_BACKEND=

# Server port (default: 8000 for oMLX/vLLM, 11434 for Ollama)
LOCAL_AI_PORT=8000

# Model name (e.g., phi4, Qwen3.5-9B-MLX-4bit)
LOCAL_AI_MODEL=mlx-community/phi-4-4bit

# vLLM only: GPU memory fraction (default: 0.9)
LOCAL_AI_GPU_MEM=0.9
```

After starting, verify with:
```bash
curl http://127.0.0.1:8000/v1/models
```

---

## Documentation en Français

### Présentation
**Hybrid Router Agent** est un plugin conçu pour les frameworks d'agents autonomes (Antigravity 2.0 et Hermes Agent).
Il permet à l'IA hébergée dans le Cloud d'agir comme un **Routeur Intelligent**. L'agent délègue **lorsque c'est justifié** les tâches lourdes en tokens, les analyses de gros fichiers de données et les corrections de code standards à un modèle de langage local (ex: oMLX, Phi-4, Llama-3) via une API locale compatible OpenAI.

Cette approche permet de préserver vos crédits Cloud tout en conservant la puissance d'analyse stratégique du modèle Cloud pour les tâches de haut niveau. L'agent cloud décide lui-même de s'effacer au profit de l'IA locale pour le "sale boulot".

### Fonctionnalités Clés
- 🧠 **Routage Proactif** : Interception automatique des requêtes volumineuses et des opérations de refactoring massif.
- 🛠️ **Correction de Code Sécurisée** : Le script `apply_local_ai.py` demande à l'IA locale de corriger le code et crée automatiquement une sauvegarde `.bak` pour éviter toute perte de données.
- 🛡️ **Gestion de Panne (Fallback & OOM)** : Gestion automatique des erreurs 507 (Out of Memory) en divisant le nombre de tokens dynamiquement.
- 🚀 **Déploiement Multi-Backend** : `deploy_api.sh` gère oMLX, Ollama, et vLLM.

### Arborescence
```text
hybrid-router-plugin/
├── AGENTS.md                      # Règles pour la délégation locale
├── README.md                      # Ce fichier de documentation
├── .env.example                   # Template des variables d'environnement
├── scripts/
│   ├── query_local_ai.py          # Requêtes générales vers l'IA locale
│   ├── apply_local_ai.py          # Application automatique de corrections sur un fichier
│   └── deploy_api.sh              # Lanceur du serveur local LLM
└── .agents/
    └── skills/
        └── local-corrector/
            └── SKILL.md           # Instruction du skill de correction locale
```

### Utilisation Manuelle
Vous pouvez tester le système directement dans votre terminal :

**Poser une question à l'IA locale :**
```bash
python3 scripts/query_local_ai.py "Génère 5 idées de projets" "Tu es un expert"
```

**Corriger un fichier existant :**
```bash
python3 scripts/apply_local_ai.py index.html "Ajoute un pied de page avec copyright"
```

### Déploiement API (Serveur LLM Local)

Le script `deploy_api.sh` automatise le lancement de votre serveur LLM local. Trois backends supportés :

| Backend | Plateforme | Commande |
|---------|-----------|----------|
| **oMLX** | macOS | `./scripts/deploy_api.sh` (auto-détection) |
| **Ollama** | macOS / Linux / Windows | `./scripts/deploy_api.sh --backend ollama` |
| **vLLM** | Linux (GPU) | `./scripts/deploy_api.sh --backend vllm` |

```bash
# Détection automatique et démarrage
./scripts/deploy_api.sh

# Vérifier l'état du serveur
./scripts/deploy_api.sh --status

# Arrêter le serveur
./scripts/deploy_api.sh --stop

# Forcer un backend spécifique
./scripts/deploy_api.sh --backend ollama
```

**Configuration** (dans `.env`) :
```ini
# Forcer un backend (omlx, ollama, vllm) ou laisser vide pour auto-détection
LOCAL_AI_BACKEND=

# Port du serveur (défaut: 8000 pour oMLX/vLLM, 11434 pour Ollama)
LOCAL_AI_PORT=8000

# Nom du modèle (ex: phi4, Qwen3.5-9B-MLX-4bit)
LOCAL_AI_MODEL=mlx-community/phi-4-4bit

# vLLM uniquement : fraction de mémoire GPU (défaut: 0.9)
LOCAL_AI_GPU_MEM=0.9
```

Vérification après démarrage :
```bash
curl http://127.0.0.1:8000/v1/models
```

---

## Hermes Agent Adaptation (June 2026)

This skill has been fully adapted and ported to **[Hermes Agent](https://github.com/NousResearch/hermes-agent)** — the open-source AI agent framework by Nous Research. The shipped `SKILL.md` is the latest Hermes v2.0.2, not the original Antigravity version.

### What changed

| Original (Antigravity 2.0) | Hermes Adaptation |
|---|---|
| `run_command` tool | `terminal` tool with curl |
| Gemini Cloud only | Multi-provider (DeepSeek, Claude, Grok, local) |
| Plugin system | Native skill system (`~/.hermes/skills/`) |
| Script path: `~/.gemini/...` | Script path: `~/.hermes/skills/hybrid-local-router/references/` |

### Hermes Installation

```bash
# The skill is already created at:
~/.hermes/skills/mlops/hybrid-local-router/SKILL.md

# Load it in any session:
/skill hybrid-local-router
```

The local LLM is configured as a custom provider in Hermes config (`custom_providers.babaudus`), pointing to `http://127.0.0.1:8000/v1` (Qwen3.5-9B-MLX-4bit).

### Hermes-Specific Routing Logic

The adapted SKILL.md instructs Hermes to:
1. Detect eligible tasks (volume > 500 words, refactoring, translation, parsing, docs)
2. Query the local LLM via `terminal` + curl (or the bundled `query_local_llm.py`)
3. Fall back to cloud (DeepSeek) seamlessly if the local server is down
4. Frame local responses with `[Traité par l'IA Locale - Qwen3.5-9B-MLX]`

Adapted by **Hermes Agent** (@jero87).

## Contributors & Co-Creators

- **@tripesinn** (Lead Architect & Visionary)
- **Antigravity AI** (Autonomous Coding Agent & Co-Creator)

---

## License
MIT License. Feel free to use, share, and improve this plugin!
Disponible pour toute la communauté Antigravity.
