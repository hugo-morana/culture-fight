# Format commun des jeux de données

Tous les jeux de données sont des fichiers JSON en UTF-8 dans `CultureFight.swiftpm/Resources/`.
`python3 outils/verifier.py` contrôle ce format ; la compilation dans le cloud le lance à chaque envoi
et échoue s'il trouve une erreur.

## Règles communes

- Chaque jeu de données a un identifiant et au moins une source dans `outils/sources.py` (titre + lien https).
- Aucun champ texte vide, aucun doublon (identifiant, nom, énoncé de question).
- Toute question a une bonne réponse, au moins 3 mauvaises réponses différentes et une explication d'une ligne.

## Jeux à tableau (`elements.json`, `pays_afrique.json`)

Une liste d'objets, un par entrée, lus par un générateur Swift dédié.

| Fichier | Champs | Contrôles |
| --- | --- | --- |
| `elements.json` | `numero` (entier), `symbole`, `nom`, `famille` (« », « gaz noble », « halogène »), `notoriete` (1 à 3), `anecdote` | Numéros 1 à 118 sans trou, symboles et noms uniques |
| `pays_afrique.json` | `pays`, `capitale`, `notoriete` (1 à 3), `note` | 54 pays, pays et capitales uniques |

## Fiches (`fiches.json`)

Une liste de fiches, une par spécialité. Source : `outils/fiches.py` (+ `ajouts_*.py`, `contextes.py`),
qui écrit le fichier.

```json
{
  "id": "felins",
  "relations": [
    {
      "modele": "Quel félin correspond à cette description : « {x} » ?",
      "inverse": "Quelle description correspond à cet animal : {y} ?",
      "explication": "{y} : {x}.",
      "paires": [["Le plus grand félin du monde", "Tigre", "Ligne de contexte affichée après la réponse."]]
    }
  ],
  "questions": [
    {"enonce": "…", "bonne": "…", "faux": ["…", "…", "…"], "explication": "…"}
  ]
}
```

| Contrôle | Pourquoi |
| --- | --- |
| `modele` contient `{x}`, `inverse` (facultatif) contient `{y}` | Sinon la question ne change pas |
| Chaque paire = x, y, contexte, tous non vides | Le contexte est la ligne affichée après la réponse |
| Pas de x en double ; pas de y en double si la relation a une question inverse | Une question inverse à deux bonnes réponses serait ambiguë |
| Au moins 4 y différents par relation | Il faut 3 mauvaises réponses plausibles |
| Pas d'énoncé en double dans l'ensemble des fiches | Évite les questions répétées |

## Ajouter un jeu de données

1. Écrire les données (fiche dans `outils/fiches.py`, ou nouveau fichier JSON + générateur Swift).
2. Ajouter ses sources dans `outils/sources.py`.
3. Lancer `python3 outils/fiches.py` puis `python3 outils/verifier.py`.
