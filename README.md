# Culture Fight

Jeu iPhone et iPad de combats de culture générale : chaque combattant pose des questions de sa spécialité,
une mauvaise réponse coûte des PV, une bonne réponse déclenche une contre-attaque.

Ce dépôt contient le **prototype du combat** (phase 1 de la feuille de route) : 6 combattants,
combat à 3 contre 3 contre une IA, sans boutique ni sauvegarde.

## Ouvrir et lancer

- **Sur Mac** : double-clic sur `CultureFight.swiftpm` (Xcode 15 ou plus), choisir un simulateur, puis ▶︎.
- **Sur iPad** : ouvrir le dossier dans Swift Playgrounds 4.4 ou plus, puis ▶︎.
- **Sur iPhone** : via TestFlight (voir plus bas).

iOS 17 minimum.

## Organisation du code

| Dossier / fichier | Rôle |
|---|---|
| `Package.swift` | Description de l'app (nom, identifiant, icône, orientations) |
| `Modeles/Question.swift` | Spécialité, question, affinités entre spécialités |
| `Modeles/Combattant.swift` | Combattant du catalogue, combattant en jeu, camp |
| `Generateurs/` | Un générateur de questions par type de spécialité (calcul, éléments, capitales) |
| `Moteur/Catalogue.swift` | Chargement des données et les 6 combattants du prototype |
| `Moteur/Combat.swift` | Règles du combat (`Regles`) et état d'un combat, sans interface |
| `Moteur/IAAdverse.swift` | L'adversaire : taux de réussite selon son niveau et la difficulté |
| `Moteur/CombatController.swift` | Chronomètre, réponse de l'IA, enchaînement des tours |
| `Vues/` | Accueil, choix de l'équipe, écran de combat |
| `Resources/` | `elements.json` (118 éléments), `pays_afrique.json` (54 pays et capitales) |

## Combattants du prototype

| Combattant | Spécialité | Questions |
|---|---|---|
| Multiplicator | Multiplications | Générées à l'infini |
| Divisator | Divisions | Générées à l'infini |
| Néonja | Gaz nobles | Nom, symbole, numéro atomique |
| Mendéléviking | Symboles des éléments | Nom ↔ symbole, 118 éléments |
| Iodiateur | Halogènes | Nom, symbole, numéro atomique |
| Afrodecapitator | Capitales d'Afrique | Pays ↔ capitale, 54 pays |

## Combattants à fiche

18 combattants (Orquebusier, Druidérable, Golemagma, Da Vincible…) tirent leurs questions de
`Resources/fiches.json`, généré par `outils/fiches.py`. Pour modifier ou ajouter des questions :
éditer `outils/fiches.py`, puis lancer `python3 outils/fiches.py` (le script vérifie chaque fiche).

## Équilibrage

Les valeurs sont dans `Regles` (`Moteur/Combat.swift`) et dans les fiches de `Catalogue.swift`.
Une simulation a montré qu'avec 100 PV et 20 d'attaque (valeurs du game design), presque tous les combats
atteignaient la limite de 30 tours à cause de la contre-attaque. Le prototype utilise donc 100 PV et 50 d'attaque
(110 PV, 54 d'attaque et 4 de défense pour les combattants rares) : un combat dure environ 15 tours.

## TestFlight

Chaque modification de `CultureFight.swiftpm` sur la branche `main` est compilée, signée et envoyée
sur TestFlight par `.github/workflows/testflight.yml`. Le numéro de build augmente à chaque envoi.

Il faut, une seule fois :

1. Ajouter les secrets du dépôt (Settings → Secrets and variables → Actions) : `ASC_KEY_ID`, `ASC_ISSUER_ID`,
   `ASC_KEY_P8`, `TEAM_ID` — les mêmes valeurs que pour PM Chimie.
2. Créer l'app dans App Store Connect avec l'identifiant `fr.hugomorana.culturefight`.

Les journaux sont publiés sur les branches `build-log` (compilation) et `testflight-log` (envoi).

## Licence

Ce dépôt est public pour être compilé gratuitement par GitHub Actions, mais il **n'est pas open source** :
tous droits réservés. Voir le fichier `LICENSE`.

## Illustrations

Les illustrations des combattants sont dans `illustrations/` (512 px de large). Celles des combattants du
prototype sont aussi copiées dans `CultureFight.swiftpm/Resources/combattant-<id>.jpg`, d'où l'app les charge.
Un combattant sans illustration affiche ses initiales.
