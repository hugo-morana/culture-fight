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

## Une source par fait

Toute fiche créée après la tâche 52 doit donner, pour **chaque** paire et **chaque** question, l'URL https
de la source consultée pour vérifier la réponse, les mauvaises réponses et le contexte :

```python
rel("Quel est le plus long fleuve de {x} ?", "{x} : {y}.",
    [("France", "Loire", "Environ 1 000 km, de l'Ardèche à l'Atlantique.", "https://fr.wikipedia.org/wiki/Loire_(fleuve)")])
q("Combien de pattes a un insecte ?", "6", ["4", "8", "10"],
  "Trois paires, fixées au thorax.", source="https://fr.wikipedia.org/wiki/Insecte")
```

`fiches.py` et `verifier.py` refusent une nouvelle fiche à laquelle il manque une source, et la
compilation dans le cloud échoue. Les fiches antérieures (`FICHES_ANTERIEURES` dans `sources.py`)
reprennent les sources trouvées dans `verification/faits.csv` ; leurs faits restants sont à vérifier.

## Ajouter un combattant à fiche

1. Écrire la fiche (au moins 60 questions) dans un fichier `outils/ajouts_*.py`.
2. Vérifier chaque fait un à un dans une source (méthode : `verification/CONSIGNES.md`) : bonne réponse
   exacte, aucune mauvaise réponse elle aussi juste, chaque affirmation du contexte confirmée. Corriger ou
   retirer ce qui n'est pas confirmé, puis noter l'URL consultée sur la paire ou la question.
3. Ajouter les sources générales de la fiche dans `outils/sources.py` et lancer `python3 outils/sources.py`.
4. Déclarer le combattant dans `Moteur/Catalogue.swift` (`aFiche(…)`).
5. Lancer `python3 outils/fiches.py` puis `python3 outils/verifier.py` : aucune erreur ne doit rester.

## Ajouter un autre jeu de données

1. Écrire les données (nouveau fichier JSON + générateur Swift), avec une source par entrée.
2. Ajouter ses sources dans `outils/sources.py`.
3. Lancer `python3 outils/fiches.py` puis `python3 outils/verifier.py`.

## Aventures de Culturia (`aventures.json`)

Petites histoires entre les habitants de Culturia (idée n° 13, tâches 147 à 150). Chaque aventure a un objectif
d'apprentissage et s'écrit avec la bible (`aventures/bible-culturia.md`, générée par `outils/bible.py`).

```json
{
  "id": "chaine-des-planetes",
  "titre": "La course des huit planètes",
  "type": "chaine",
  "objectif": "Retenir l'ordre des planètes du Soleil à Neptune",
  "pays": "cosmie",
  "lieu": "Le Belvédère des Orbites",
  "ordre": 1,
  "combattants": ["mercurion", "venus-de-mille-lames"],
  "deblocage": {"victoires": 5},
  "cases": [
    {"lieu": "Le Belvédère des Orbites", "narration": "…", "bulles": [{"combattant": "mercurion", "texte": "…"}]}
  ],
  "faits": [{"texte": "…", "source": "https://…"}],
  "quiz": [
    {"enonce": "…", "bonne": "…", "faux": ["…", "…", "…"], "explication": "…", "source": "https://…"}
  ]
}
```

- `type` : `chaine` (chaîne mémotechnique d'un combattant à l'autre), `palais` (palais mental : un lieu visité pièce
  par pièce) ou `points` (points culturels glissés dans le récit).
- `pays` et `lieu` viennent de `monde.json` ; chaque case peut changer de `lieu`, toujours un lieu de la carte.
- `combattants` : au moins 2 habitants du catalogue ; chaque bulle est dite par l'un d'eux.
- `ordre` : place de l'aventure dans la chronologie de Culturia, unique (la bible la reprend).
- `deblocage.victoires` : nombre de victoires qui débloque le chapitre (1 ou plus).
- `faits` : au moins 1 fait réel par aventure, chacun avec une source https.
- `quiz` : exactement 3 questions de fin, au format des questions de fiche (3 mauvaises réponses différentes,
  source https, explication qui apporte un fait de plus que la question).
- Dates : chaque date citée dans une case est encodée avec le système MemoHugoDate et mise en scène, l'objet jouant un
  rôle dans la case : matière = siècle (18xx acier clouté, 16xx miroir…), objet = 2 derniers chiffres de l'année
  (46 coussin, 98 tournevis…), couleur = mois (janvier rouge… décembre bleu ciel), motifs = objet du numéro du jour.
  Le combattant donne le décodage dans sa bulle (ex. « acier clouté pour les années 1800, coussin pour 46, gris pour
  septembre, ballons de basket pour le 23 »).
- `outils/verifier.py` contrôle tout cela ; le fichier peut rester vide (`[]`) tant qu'aucune aventure n'est prête.
