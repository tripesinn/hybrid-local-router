---
name: hybrid-local-router
description: "Routeur hybride proactif. Delegue les taches lourdes (synthese, traduction, refactoring, formatage, parsing) au LLM local pour economiser le budget cloud. Adapte d'Antigravity 2.0. Fait partie de la strategie d'orchestration multi-modeles (voir skill cost-aware-orchestration)."
version: 2.0.2
author: tripesinn
platforms: [macos, linux]
---

# Routeur Hybride Proactif (Cloud -> Local LLM)

En tant qu'agent Hermes utilisant DeepSeek (cloud), tu disposes d'un **modele d'IA local haute performance** (Qwen3.5-9B-MLX-4bit) accessible via le provider custom `babaudus` sur `http://127.0.0.1:8000/v1`. Tu **dois** l'utiliser de maniere proactive pour optimiser la consommation de tokens cloud tout en garantissant des reponses rapides.

## 1. Criteres de Delegation Proactive

Delegue au modele local dans les cas suivants :

### Volume de donnees eleve
- Texte d'entree > **500 mots** ou ~**1500 tokens** (logs, longs fichiers, rapports)

### Types de taches eligibles

| Categorie | Exemples |
|-----------|----------|
| Correction / Refactoring | Nettoyage de code, correction de fautes, reecriture selon un standard, generation de tests unitaires |
| Synthese / Resume | Analyse de logs volumineux, extraction de points cles, resumes de documents |
| Traduction | Fichiers de localisation (JSON/YAML), articles, markdown volumineux |
| Documentation | Redaction de manuels, docstrings de modules entiers, documentation d'API |
| Parsing / Formatage | Conversion CSV vers JSON, logs bruts vers rapports structures, restructuration de donnees |
| Generation de code boilerplate | Tests unitaires repetitifs, stubs, fichiers de config standardises |

### Regle d'or
Si la tache peut etre faite par un modele local competent sans necessiter de raisonnement multi-etapes complexe, de diagnostic de bugs croises, ou de decision architecturale -> delegue-la.

Ne delegue PAS : choix d'architecture, debug de bugs complexes multi-fichiers, planification strategique.

## 2. Methode d'Appel (Hermes)

Utilise l'outil `terminal` pour interroger le LLM local via curl. Pour les prompts courts :

```bash
curl -s http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"Qwen3.5-9B-MLX-4bit\", \"messages\": [{\"role\": \"user\", \"content\": $(printf '%s' \"TON_PROMPT\" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')}], \"temperature\": 0.3, \"max_tokens\": 4096}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['choices'][0]['message']['content'])"
```

Pour les prompts longs (>200 caracteres), ecris le prompt dans un fichier temporaire puis :

```bash
python3 -c "
import json, urllib.request
prompt = open('/tmp/local_prompt.txt').read()
req = urllib.request.Request(
    'http://127.0.0.1:8000/v1/chat/completions',
    data=json.dumps({'model': 'Qwen3.5-9B-MLX-4bit', 'messages': [{'role': 'user', 'content': prompt}], 'temperature': 0.3, 'max_tokens': 4096}).encode(),
    headers={'Content-Type': 'application/json'}
)
resp = urllib.request.urlopen(req, timeout=60)
print(json.loads(resp.read())['choices'][0]['message']['content'])
"
```

### Alternative : script Python dedie

Un script `query_local_llm.py` est disponible dans `references/`. Pour l'utiliser :

```bash
python3 ~/.hermes/skills/hybrid-local-router/references/query_local_llm.py "Ton prompt ici"
```

## 3. Fallback et Gestion d'Echec

- Timeout : 60 secondes max. Si le serveur local ne repond pas, abandonne.
- Echec (serveur eteint, erreur) : **Ne bloque jamais le flux.** Reprends immediatement la main et execute la tache toi-meme via DeepSeek. Ajoute en fin de reponse :

  Information: L'IA locale n'a pas repondu (serveur eteint ou timeout), j'ai finalise le traitement via DeepSeek Cloud.

## 4. Format de Restitution

Encadre les reponses du LLM local :

[Traite par l'IA Locale - Qwen3.5-9B-MLX]

(contenu produit par le modele local)

## 5. Configuration et Provider Local

Le LLM local est deja configure dans `~/.hermes/config.yaml` sous `custom_providers` :

```yaml
custom_providers:
- name: babaudus
  base_url: http://127.0.0.1:8000/v1
  api_key: dummy
  model: Qwen3.5-9B-MLX-4bit
  api_mode: chat_completions
```

Les appels `terminal` de ce skill utilisent directement cette URL. Pas besoin de config supplementaire.

## 6. Verification Rapide du Service Local

Avant la premiere delegation d'une session, verifie que le serveur est vivant :

```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/v1/models
```

- **Code 200** : serveur OK, delegation possible.
- **Code 401** : serveur OK aussi — oMLX (le backend macOS utilise par jero) renvoie 401 sur `/v1/models` meme quand le serveur est operationnel. Les appels `/v1/chat/completions` fonctionnent normalement.
- **Tout autre code ou echec de connexion** : serveur indisponible. Ne tente pas de delegation et travaille en mode cloud uniquement.

### Alternative : script de deploiement

Un script `deploy_api.sh` est disponible dans le depot GitHub `tripesinn/hybrid-local-router` (`scripts/deploy_api.sh`) et en reference locale (`scripts/deploy_api.sh`). Il supporte trois backends (oMLX, Ollama, vLLM) et gere start/stop/status. Voir `references/deploy-api.md` pour les details.

## 7. Pièges et Bonnes Pratiques

### Ne jamais utiliser `hermes config set`
La commande `hermes config set` **ecrase integralement** le fichier `config.yaml` au lieu de merger la nouvelle cle. En session 01/06/2026, un `hermes config set` a reduit un fichier de 594 lignes a 8 lignes, detruisant toute la configuration (agents, gateway, memory, skills, TTS, STT, security, platform_toolsets, custom_providers...).

**Regle stricte pour toute modification de config.yaml** : ouvrir Xcode (`open -a Xcode ~/.hermes/config.yaml`) et donner le contenu a copier-coller manuellement. Meme regle pour les autres fichiers systeme sensibles (`~/.hermes/.env`, `config.yaml` de profils, etc.).

### Preference utilisateur
L'utilisateur (jero) prefere que les modifications de fichiers systeme sensibles passent par Xcode plutot que par des commandes shell directes. En cas de doute, ouvrir Xcode et fournir le contenu.
