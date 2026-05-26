# Hybrid Router Agent (Gemini + Local AI) for Antigravity 2.0

> 🚀 **An intelligent hybrid router plugin that proactively delegates token-heavy tasks (summarization, bulk translation, documentation, and code correction) to a local LLM to save cloud costs, with seamless cloud fallback.**

*Read this in: [English](#english-documentation) | [Français (French)](#documentation-en-français)*

---

## English Documentation

### Overview
**Hybrid Router Agent** is a plugin designed for the Antigravity 2.0 autonomous agent framework. 
It enables the cloud-hosted Gemini LLM to act as a **Smart Router**, delegating heavy computation, massive text processing, and standard code formatting/corrections to a local LLM (such as Phi-4, Llama-3, or Mistral running on vLLM, Ollama, LM Studio, etc.) through a standard OpenAI-compatible API.

By offloading these heavy tasks, the agent saves significant cloud credits while keeping Gemini as the high-level reasoning "orchestrator" for complex architecture and multi-file logic.

### Key Features
- 🧠 **Proactive Routing**: Gemini automatically identifies and intercepts heavy workloads (inputs > 500 words / 1500 tokens).
- 🛠️ **Code Correction & Formatting**: Offloads lint fixes, standard refactoring, and unit test generation to the local model.
- 📂 **Zero-Dependency Python Script**: The query runner uses Python's standard `urllib` library, requiring no `pip install requests` or extra packages.
- 🛡️ **Seamless Fallback**: If the local AI is offline, timed out, or returns an error, the agent gracefully falls back to Gemini Cloud to complete the task without user friction.

### Project Structure
```text
hybrid-router-plugin/
├── plugin.json                    # Plugin metadata
├── README.md                      # Documentation (this file)
├── .gitignore                     # Git ignore rules
├── .env.example                   # Environment configuration template
├── scripts/
│   └── query_local_llm.py         # Universal Python script to query local LLMs
└── skills/
    └── hybrid-local-router/
        └── SKILL.md               # System instructions giving Gemini routing behavior
```

### Setup & Installation

1. **Clone/Copy the plugin** into your Antigravity plugins directory (usually `~/.gemini/config/plugins/`):
   ```bash
   cp -r hybrid-router-plugin ~/.gemini/config/plugins/
   ```

2. **Configure your Local LLM Server**:
   Ensure you have a local server running. Common setups include:
   - **Ollama**: Run `ollama run phi4` (Ollama exposes an OpenAI-compatible API on `http://localhost:11434/v1/chat/completions`).
   - **LM Studio**: Start the Local Server on port `1234`.
   - **vLLM / LocalAI**: Start your model exposing standard port `8000`.

3. **Configure Environment Variables**:
   Copy `.env.example` to `.env` in the plugin directory and set your parameters:
   ```bash
   cp .env.example .env
   ```
   Edit `.env`:
   ```ini
   LOCAL_AI_URL=http://127.0.0.1:8000/v1/chat/completions
   LOCAL_AI_MODEL=mlx-community/phi-4-4bit
   LOCAL_AI_TIMEOUT=60
   LOCAL_AI_API_KEY=
   ```

### Command Line Usage
You can test the Python script manually from your terminal:
```bash
# Pass the prompt as an argument
python3 scripts/query_local_llm.py "Summarize this code function..."

# Or pipe long text/logs into the script via stdin
cat logs.txt | python3 scripts/query_local_llm.py
```

---

## Documentation en Français

### Présentation
**Hybrid Router Agent** est un plugin conçu pour le framework d'agents autonomes Antigravity 2.0.
Il permet à l'IA hébergée dans le Cloud (Gemini) d'agir comme un **Routeur Intelligent**. Gemini délègue de manière proactive les tâches lourdes en tokens, les analyses de gros fichiers de données et les corrections de code standards à un modèle de langage local (ex: Phi-4, Llama-3, Mistral tournant sous Ollama, LM Studio, vLLM) via une API locale compatible OpenAI.

Cette approche permet de préserver vos crédits Cloud tout en conservant la puissance d'analyse stratégique de Gemini pour les tâches de haut niveau.

### Fonctionnalités Clés
- 🧠 **Routage Proactif** : Interception automatique des requêtes volumineuses (> 500 mots ou ~1500 tokens).
- 🛠️ **Correction de Code & Refactoring** : Délégation des résolutions de lint, génération de tests unitaires et réécritures simples au LLM local.
- 📂 **Script Python Universel Sans Dépendance** : Écrit en pur Python avec la bibliothèque standard `urllib`, aucun `pip install` n'est nécessaire.
- 🛡️ **Gestion de Panne Transparente (Fallback)** : Si le serveur local est éteint ou met trop de temps à répondre, Gemini prend le relais de manière invisible pour finaliser votre demande.

### Configuration et Installation

1. **Copiez le dossier du plugin** dans le répertoire des plugins d'Antigravity (généralement `~/.gemini/config/plugins/`) :
   ```bash
   cp -r hybrid-router-plugin ~/.gemini/config/plugins/
   ```

2. **Démarrez votre serveur d'IA local** :
   - **Ollama** : `ollama run phi4` (exposé par défaut sur `http://localhost:11434/v1/chat/completions`).
   - **LM Studio** : Lancez le serveur local sur le port `1234`.
   - **vLLM / LocalAI** : Lancez votre modèle sur le port `8000`.

3. **Configurez les variables d'environnement** :
   Créez un fichier `.env` basé sur `.env.example` dans le dossier du plugin :
   ```bash
   cp .env.example .env
   ```
   Exemple de configuration dans `.env` :
   ```ini
   LOCAL_AI_URL=http://localhost:11434/v1/chat/completions
   LOCAL_AI_MODEL=phi4
   LOCAL_AI_TIMEOUT=60
   ```

### Test Manuel du Script
Vous pouvez tester le script directement dans votre terminal :
```bash
# Envoyer le prompt en argument
python3 scripts/query_local_llm.py "Donne-moi 5 idées de projets Python"

# Envoyer un fichier texte ou des logs via l'entrée standard (stdin)
cat server.log | python3 scripts/query_local_llm.py
```

---

## Contributors & Co-Creators

- **@tripesinn** (Lead Architect & Visionary)
- **Antigravity AI** (Autonomous Coding Agent & Co-Creator)

---

## License
MIT License. Feel free to use, share, and improve this plugin!
Disponible pour toute la communauté Antigravity.

