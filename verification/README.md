# Vérification des questions (tâche 47 de la feuille de route)

`faits.csv` liste les 975 faits écrits aux tâches 20 et 21 (questions ajoutées, explications, notes des
capitales, anecdotes des éléments), avec pour chacun :

- `statut` : `vérifié`, `corrigé`, `corrigé (logique), source à trouver` ou `à vérifier` ;
- `source` : l'URL consultée ;
- `note` : ce qui a été corrigé ou nuancé.

La colonne `contexte` garde le texte d'origine ; le texte corrigé est dans les sources (`outils/`, `Resources/`).

## Reprendre la vérification

Les lignes `à vérifier` n'ont pas encore été cherchées : la limite de recherches web d'une session a été
atteinte. Pour reprendre, suivre `CONSIGNES.md` sur ces lignes, écrire les résultats dans un nouveau
`resultats_<groupe>.json`, puis lancer :

```
python3 outils/appliquer_verification.py
python3 outils/fiches.py
```

Le premier script applique les corrections et met à jour `faits.csv` ; le second régénère `fiches.json`.
