# Vérification des faits (tâche 47 de la feuille de route)

Jeu iPhone « Culture Fight » : quiz de culture générale en français. Le fichier `verification/faits.csv`
liste 975 faits écrits sans source. Chaque ligne : `n`, `theme`, `fait` (question ou description),
`reponse` (bonne réponse), `contexte` (phrase affichée après la réponse).

Pour les questions à choix multiples, les mauvaises réponses se trouvent dans `outils/ajouts_vivant.py`
et `outils/ajouts_corps_terre_arts.py` (fonction `q(énoncé, bonne, [faux…], explication)`). Pour une
relation (`rel`), les mauvaises réponses sont les autres réponses de la même relation.

## Ce qu'il faut vérifier, ligne par ligne

1. La bonne réponse est exacte.
2. Aucune mauvaise réponse proposée n'est elle aussi correcte (question ambiguë).
3. Chaque affirmation du contexte est exacte (chiffres, dates, records, attributions, étymologies).

## Méthode

**Budget : 30 recherches WebSearch au maximum** (la limite de la session est partagée entre 6 agents).
Pour tenir le budget, une recherche doit servir à plusieurs faits : chercher la page qui couvre un thème
(article Wikipédia du sujet, liste, page de musée…), puis l'ouvrir avec WebFetch en demandant de confirmer
ou d'infirmer toute une série de faits d'un coup. WebFetch ne compte pas dans le budget de recherches.

Ne traiter que les lignes dont le `statut` est `à vérifier`, `incertain` ou `corrigé (logique), source à trouver`. Ce sont souvent des faits difficiles : chercher une source précise par fait. Si un fait reste introuvable, proposer une `correction` qui le retire ou le remplace par un fait vérifié (statut `corrigé`), pour qu'il ne reste rien sans source.
Utiliser un dossier temporaire à ton nom (par exemple `/tmp/verif_<groupe>`), jamais un dossier partagé.
La colonne `note` peut contenir des doutes relevés lors d'une première passe : les vérifier en priorité.
Le texte à vérifier est celui des sources actuelles (`outils/`, `CultureFight.swiftpm/Resources/`), qui
peut avoir été corrigé depuis la création du CSV.

- Une source par fait au minimum : WebSearch, puis WebFetch d'un lien des résultats si l'extrait ne suffit pas.
  Préférer Wikipédia (fr ou en, ou ses copies), les sites officiels, scientifiques ou de musées.
- Ne citer que des sources réellement consultées dans cette session (URL exacte).
- Ne pas modifier les fichiers du dépôt : écrire seulement le fichier de résultats indiqué.

## Résultat

Fichier JSON indiqué dans ta mission (`verification/resultats_<groupe>.json`) : un objet dont les clés sont les `n` (texte) :

```json
{"12": {"statut": "vérifié", "source": "https://…", "note": ""},
 "13": {"statut": "corrigé", "source": "https://…", "note": "ce qui était faux",
        "correction": {"contexte": "nouvelle phrase"}}}
```

- `statut` : `vérifié`, `corrigé`, `incertain` (sources en désaccord) ou `non trouvé`.
- `correction` (si `corrigé`) : un ou plusieurs champs parmi `contexte`, `reponse`, `faux`
  (liste complète des 3 mauvaises réponses) ou `fait`. Même style : français, phrase courte, sans
  affirmation non vérifiée. Si une partie du contexte ne peut pas être confirmée, la retirer ou la
  remplacer par un fait vérifié.
- Écrire le fichier au fur et à mesure (toutes les 10 lignes environ) pour ne rien perdre.

À la fin, répondre en quelques lignes : nombre de faits vérifiés, corrigés, incertains, non trouvés,
et la liste des corrections.
