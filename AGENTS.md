# Hybrid Local Router - Configurations des Agents

Ce fichier contient les règles et les configurations des agents pour utiliser l'IA locale (oMLX) dans le processus de correction de code.

<RULE[local_ai_corrector]>
## Correcteur Automatique avec IA Locale

Vous pouvez déléguer des corrections ou modifications de fichiers à l'IA locale via le script `apply_local_ai.py`.

**Étapes à suivre :**
1. Utilisez la commande suivante pour appliquer la correction :
   ```bash
   python3 scripts/apply_local_ai.py <chemin_du_fichier> "<instructions_de_modification>"
   ```
2. Inspectez obligatoirement les différences avec git pour vous assurer de la cohérence :
   ```bash
   git diff <chemin_du_fichier>
   ```
3. Validez la correction en exécutant le build local et les tests pertinents du projet.
</RULE[local_ai_corrector]>
