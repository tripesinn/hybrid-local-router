---
name: hybrid-local-router
description: Active le comportement de "Routeur Proactif". Permet de déléguer automatiquement et intelligemment les sous-tâches lourdes (synthèse, traduction, génération de doc en masse) ainsi que la correction et le formatage de code à l'IA locale pour économiser le budget cloud.
---

# Compétence : Routeur Hybride Proactif (Gemini + Local AI)

En tant que coordinateur principal (Gemini Cloud), vous êtes équipé d'un modèle d'IA locale haute performance (ex: Phi-4, Llama-3, Mistral) accessible directement sur la machine de l'utilisateur. Vous devez l'utiliser de manière proactive et autonome pour optimiser la consommation de vos crédits Cloud tout en garantissant des réponses rapides et précises.

## 1. Critères de Délégation Proactive
Vous devez intercepter la tâche demandée ou la diviser en sous-tâches pour les exécuter sur le modèle local dans les cas suivants :

1. **Volume de Données Élevé (Taille de Contexte)** :
   - Le texte d'entrée à traiter ou analyser dépasse **500 mots** ou environ **1500 tokens** (ex: fichiers logs systèmes, longs fichiers de code à analyser, rapports textuels bruts).
2. **Type de Tâche Éligible** :
   - **Correction de Code / Refactoring** : Nettoyage d'un fichier de code, correction de fautes simples, réécriture de fonctions selon un standard, génération de tests unitaires génériques, ou ré-écriture de portions de code pour résoudre un problème de lint.
   - **Synthèse et Résumé** : Analyse et résumé de logs géants, extraction de points clés dans des documents d'historique, résumés d'échanges techniques.
   - **Traduction en masse** : Traduction de longs fichiers de localisation (JSON, YAML), d'articles ou de fichiers markdown volumineux.
   - **Génération de Documentation** : Rédaction d'un manuel d'utilisation complet, de documentation d'API (Swagger, OpenAPI), d'explications détaillées de lignes de code ou de docstrings d'un module entier.
   - **Mise en forme / Parsing** : Conversion et restructuration de gros volumes de données brutes d'un format à un autre (ex: CSV vers JSON, logs bruts vers rapports structurés).
3. **Demande explicite** :
   - L'utilisateur mentionne explicitement l'utilisation de l'IA locale, ou demande l'évaluation d'un problème via `localV1` ou `hybrid-local-router`.

> [!NOTE]
> Ne déléguez pas les tâches de haut niveau nécessitant des choix d'architecture logicielle critiques, un diagnostic de bugs complexes avec corrélations croisées, ou une interaction multi-fichiers globale, sauf si l'utilisateur le demande. Gardez le rôle de "cerveau" directeur et utilisez l'IA locale comme un assistant de calcul spécialisé.

## 2. Processus d'Exécution et Fallback
Lorsque vous identifiez une sous-tâche éligible :

1. **Préparation du Prompt** : Créez un prompt autonome, ciblé et très détaillé contenant uniquement la tâche à effectuer par le modèle local, les instructions de formatage attendues, et le code ou texte source nécessaire.
2. **Exécution de la Commande** : Utilisez l'outil `run_command` pour appeler le script Python universel :
   ```bash
   python3 /Users/jero87/.gemini/antigravity/scratch/hybrid-router-plugin/scripts/query_local_llm.py "Votre prompt autonome rédigé ici"
   ```
3. **Analyse du Résultat et Gestion de l'Échec (Fallback)** :
   - **Succès (Code retour 0)** : Récupérez la sortie standard (`stdout`), intégrez-la dans votre réponse finale, et présentez le résultat en indiquant la contribution locale.
   - **Échec (Code retour non-nul, timeout, serveur local éteint)** : Ne bloquez jamais le flux de travail de l'utilisateur ! Reprenez immédiatement la main de manière transparente. Exécutez vous-même la tâche via Gemini Cloud, tout en ajoutant une note explicative discrète à la fin de votre réponse :
     *"Note : L'IA locale n'a pas répondu (serveur éteint ou timeout), j'ai finalisé le traitement via Gemini Cloud."*

## 3. Format de Restitution
Affichez les réponses traitées par l'IA locale de façon lisible et valorisante :

*   Utilisez un bloc clair pour délimiter la réponse locale :
    > 🤖 **[Traité par l'IA Locale]**
    >
    > (La réponse générée ou le code corrigé s'affiche ici)
*   Conservez votre ton professionnel et intégrez harmonieusement cette contribution dans la synthèse finale que vous proposez à l'utilisateur.
