# Culture Fight

Jeu iPhone et iPad de combats de culture générale : chaque combattant pose des questions de sa spécialité,
une mauvaise réponse coûte des PV, une bonne réponse déclenche une contre-attaque.

Ce dépôt contient le **prototype du combat** (phase 1 de la feuille de route) : combat à 3 contre 3
contre une IA, avec la sauvegarde du joueur (Pièces, réserve, bilan), sans boutique pour l'instant.

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
| `Modeles/Sauvegarde.swift` | Sauvegarde SwiftData : joueur, réserve de combattants, gains de fin de combat |
| `Generateurs/` | Un générateur de questions par type de spécialité (calcul, éléments, capitales) |
| `Moteur/Catalogue.swift` | Chargement des données et les 6 combattants du prototype |
| `Moteur/Combat.swift` | Règles du combat (`Regles`) et état d'un combat, sans interface |
| `Moteur/IAAdverse.swift` | L'adversaire : taux de réussite selon son niveau et la difficulté |
| `Moteur/CombatController.swift` | Chronomètre, réponse de l'IA, enchaînement des tours |
| `Vues/` | Accueil, choix de l'équipe, écran de combat, collection (`CollectionView.swift`, `CollectionModes.swift`) |
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

## Nombre de questions

Chaque combattant pose au moins 60 questions différentes. Les questions ajoutées aux fiches sont dans
`outils/ajouts_vivant.py` et `outils/ajouts_corps_terre_arts.py` ; `fiches.py` refuse une fiche sous 60
questions. Néonja et Iodiateur mêlent les questions sur les éléments et une fiche de culture
(`GenerateurMixte`) ; Multiplicator et Divisator tirent dans au moins 60 opérations à chaque difficulté.

## Explications après chaque réponse

Après chaque réponse, l'écran de combat affiche une ligne de contexte (`Question.explication`) qui ne se
contente pas de redonner la réponse :

- **Fiches** : chaque paire d'une relation a son contexte dans `outils/contextes.py` ; `fiches.py` refuse
  une paire ou une question sans contexte.
- **Éléments** : champ `anecdote` de `Resources/elements.json` (origine du nom, usage), pour les 118 éléments.
- **Capitales** : champ `note` de `Resources/pays_afrique.json`, rempli pour les 54 pays.
- **Calcul et conversions** : l'explication détaille le calcul.

## Jeux de données et vérification

25 jeux de données : `elements.json`, `pays_afrique.json` et les 23 fiches de `fiches.json`.
Leur format commun est décrit dans [`outils/FORMAT.md`](outils/FORMAT.md) et leurs sources dans
`outils/sources.py`. `python3 outils/verifier.py` détecte les champs manquants, les doublons, les
questions ambiguës et les jeux sans source ; la compilation dans le cloud le lance à chaque envoi.

## Ma collection

Le menu « Grouper par » (en haut à droite) range les combattants par **domaine**, par **famille** de
spécialités ou par **style de combat** (les 10 familles de styles) ; le champ de recherche filtre sur le nom,
la spécialité, la famille, le domaine, le style ou la rareté, sans tenir compte des accents. Le regroupement
et la recherche valent pour les trois affichages, au choix en haut de l'écran (le choix est mémorisé) :

- **Liste** : une ligne par combattant (vignette, rareté, PV, attaque, défense), groupée par domaine ;
  toucher une ligne ouvre la fiche.
- **Tuiles** : la grille de cartes, chaque carte se retourne au toucher.
- **Paquet** : les cartes empilées. On effeuille la carte du dessus en la faisant glisser : elle s'envole
  et repasse sous le paquet, pendant que les cartes du dessous s'ouvrent en éventail. Toucher la carte la
  retourne, la réglette feuillette vite, et des puces filtrent le paquet par groupe.

## Sauvegarde

La progression est stockée sur l'appareil avec SwiftData (`Modeles/Sauvegarde.swift`) :

- **`Joueur`** : Pièces, niveau de compte, combats joués, victoires, défaites, nuls, inventaire de consommables.
- **`CombattantPossede`** : un combattant de la réserve (identifiant du catalogue, niveau, XP, équipement).
  Le nom, la spécialité et les statistiques de base restent dans `Catalogue.swift`.

- **`PartieJouee`** (`Modeles/Statistiques.swift`) : l'historique, une entrée par partie rattachée à son joueur
  (résultat, niveau de l'IA, les deux équipes, tours, PV restants, réponses du joueur, Pièces, XP de compte
  et niveau après la partie). Il nourrit les statistiques et se consulte dans le profil (`Vues/HistoriqueView.swift`).

Le joueur est créé au premier lancement. À la fin d'un combat, les Pièces gagnées et le résultat sont
enregistrés une seule fois ; un abandon compte comme une défaite, sans Pièces. L'app enregistre aussi
quand elle passe en arrière-plan. Toutes les propriétés ont une valeur par défaut, pour que SwiftData
puisse ajouter un champ dans une version suivante sans perdre la sauvegarde.

### Niveau de compte et ligue

En haut à gauche de l'accueil, un écusson aux couleurs de la ligue porte le niveau de compte, avec une
barre vers le niveau suivant (`Modeles/NiveauCompte.swift`). Comme une cote Elo, l'XP de compte se gagne
en victoire et se perd en défaite, et peut faire redescendre de niveau (jamais sous le niveau 1).
Battre une IA forte rapporte plus, perdre contre une IA faible coûte plus :

| IA | Victoire | Match nul | Défaite ou abandon |
|---|---|---|---|
| Facile | +20 | −5 | −30 |
| Moyen | +30 | +5 | −20 |
| Difficile | +40 | +15 | −10 |

Passer au niveau suivant demande 100 × niveau actuel. L'XP des combattants, elle, ne baisse jamais.
En attendant le classement Glicko-2, la ligue suit le niveau : Bronze (1 à 4), Argent (5 à 9),
Or (10 à 14), Platine (15 à 19), Savant (20 et plus).

Un nouveau joueur reçoit 3 Communs (`Sauvegarde.reserveDeDepart` : Néonja, Druidérable, Seinturion) et
achète les autres à la boutique. Les sauvegardes créées avant la boutique, où tout était offert, gardent
tous leurs combattants.

## Boutique

`Modeles/Boutique.swift` et `Vues/BoutiqueView.swift`, d'après la section « Économie et boutique » du game design :

- **Catalogue fixe** : tous les combattants Communs, 150 Pièces chacun.
- **Offre du jour** (dès le niveau de compte 3) : 2 combattants (les Rares sortent deux fois plus souvent) et
  2 objets, tirés avec une graine qui ne dépend que de la date. L'offre est la même toute la journée,
  achat ou relance compris, et se renouvelle à minuit. Chaque article s'achète une fois par jour.
- **Prix** : Commun 150, Rare 400, Épique 1 000, Légendaire 2 500 ; équipements 100 à 200 ;
  consommables 60 les 3.
- **Doublon** : un combattant déjà possédé, acheté dans l'offre du jour, devient de l'XP pour lui
  (la moitié de son prix).
- Les objets achetés vont dans l'inventaire ; leurs effets en combat arrivent avec la tâche 25.

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

## Propriété intellectuelle et mentions

Ce qui est protégé, et comment (tâche 63 de la feuille de route) :

| Élément | Protection | Ce qu'il faut faire |
|---|---|---|
| Code, textes, histoires, monde de Culturia | Droit d'auteur, automatique dès la création | Garder les preuves de date : historique Git, et au besoin dépôt e-Soleau à l'INPI |
| Base de questions (fiches, explications) | Droit d'auteur sur les textes + droit du producteur de base de données (CPI, L341-1) | Garder la trace de l'investissement (vérification, `verification/`) ; mention dans l'app |
| Nom « Culture Fight » et logo | Marque, seulement si elle est déposée | Recherche d'antériorité puis dépôt INPI (France) ou EUIPO (UE), classes 9, 28 et 41 |
| Noms des combattants | Pas protégés seuls ; risque s'ils ressemblent à une marque | Tâche 39 : vérifier les noms avant la sortie |
| Illustrations | Droit d'auteur sur ce qui vient d'un apport humain ; une image d'IA brute est mal protégée | Retoucher et composer les cartes ; garder prompts et fichiers de travail |
| Faits (dates, capitales, symboles) | Aucune, pour personne | Reformuler, ne pas copier les phrases des sources |
| Police Cinzel | Licence OFL de ses auteurs | Fournir le texte de la licence (fait, dans l'app) |

L'écran **Mentions légales et crédits** (`Vues/MentionsLegalesView.swift`, depuis le bas du profil) affiche
le © Hugo Morana, l'éditeur, l'absence de collecte de données, la licence de Cinzel avec son texte complet,
les sources des questions et les marques citées. L'année du © s'étend seule (« 2026–2027 »).

## Illustrations

Les illustrations des combattants sont dans `illustrations/` (512 px de large). Celles des combattants du
prototype sont aussi copiées dans `CultureFight.swiftpm/Resources/combattant-<id>.jpg`, d'où l'app les charge.
Un combattant sans illustration affiche ses initiales.
