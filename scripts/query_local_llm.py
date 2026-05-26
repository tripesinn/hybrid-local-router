#!/usr/bin/env python3
import os
import sys
import json
import urllib.request
import urllib.error

def load_env(file_path=".env"):
    """Charge manuellement un fichier .env simple si présent, sans dépendance tierce."""
    if os.path.exists(file_path):
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                if "=" in line:
                    key, val = line.split("=", 1)
                    os.environ[key.strip()] = val.strip().strip('"').strip("'")

def query_local_llm(prompt):
    script_dir = os.path.dirname(os.path.realpath(__file__))
    plugin_dir = os.path.dirname(script_dir)
    
    # Charger d'abord le fichier .env du plugin
    load_env(os.path.join(plugin_dir, ".env"))

    # Variables de configuration avec valeurs par défaut
    url = os.environ.get("LOCAL_AI_URL", "http://127.0.0.1:8000/v1/chat/completions")
    model = os.environ.get("LOCAL_AI_MODEL", "mlx-community/phi-4-4bit")
    timeout = float(os.environ.get("LOCAL_AI_TIMEOUT", "60"))
    api_key = os.environ.get("LOCAL_AI_API_KEY", "")

    # Préparation du payload standard OpenAI chat completions
    payload = {
        "model": model,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,  # Température basse pour privilégier la fidélité et la structure
        "max_tokens": 4096   # Autorise des réponses substantielles
    }

    headers = {
        "Content-Type": "application/json"
    }
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            res_data = response.read().decode("utf-8")
            res_json = json.loads(res_data)
            
            if "choices" in res_json and len(res_json["choices"]) > 0:
                content = res_json["choices"][0]["message"]["content"]
                print(content)
                sys.exit(0)
            else:
                print("Erreur : Structure de réponse inattendue du serveur local.", file=sys.stderr)
                print(json.dumps(res_json, indent=2), file=sys.stderr)
                sys.exit(5)
                
    except urllib.error.URLError as e:
        print(f"Erreur de connexion à l'IA locale ({url}) : {e.reason}", file=sys.stderr)
        sys.exit(2)
    except urllib.error.HTTPError as e:
        try:
            err_body = e.read().decode("utf-8", errors="ignore")
        except Exception:
            err_body = "Impossible de lire le corps de l'erreur."
        print(f"Erreur HTTP du serveur local : Code {e.code} - {err_body}", file=sys.stderr)
        sys.exit(3)
    except Exception as e:
        print(f"Erreur inattendue lors de la requête : {e}", file=sys.stderr)
        sys.exit(4)

if __name__ == "__main__":
    prompt = ""
    if len(sys.argv) >= 2:
        if sys.argv[1] in ("-", "--stdin"):
            prompt = sys.stdin.read()
        else:
            prompt = sys.argv[1]
    else:
        # Lecture depuis l'entrée standard si redirigée (ex: cat log.txt | python3 script.py)
        if not sys.stdin.isatty():
            prompt = sys.stdin.read()
        else:
            print("Usage :", file=sys.stderr)
            print("  python3 query_local_llm.py \"Mon prompt de test\"", file=sys.stderr)
            print("  cat texte.txt | python3 query_local_llm.py", file=sys.stderr)
            sys.exit(1)
            
    if not prompt.strip():
        print("Erreur : Le prompt fourni est vide.", file=sys.stderr)
        sys.exit(1)
        
    query_local_llm(prompt)
