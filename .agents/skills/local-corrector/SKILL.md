---
name: local-corrector
description: >
  Déléguer des corrections ou modifications de fichiers à l'IA locale (oMLX) et vérifier le résultat.
---
# local-corrector — Correcteur Automatique avec IA Locale

Ce skill permet d'utiliser l'IA locale active (port 8888) pour effectuer des modifications de code, puis de lancer automatiquement des vérifications pour valider les modifications.

## Utilisation

```bash
python3 scripts/apply_local_ai.py <chemin_du_fichier> "<instructions>"
```

### Phase de Vérification (Obligatoire)

1. Inspecter les différences : 
```bash
git diff <chemin_du_fichier>
```
2. Valider le build local / tests du projet.
