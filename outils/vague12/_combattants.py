"""Le combattant de la vague 12 : Exosquelette (Univers n° 22), avec sa nouvelle illustration.

Ajouté au catalogue quand sa fiche est prête : python3 outils/vague12/_integrer.py.
Même format que outils/vague11/_combattants.py.
"""

FORGE = ("astralis", "La Forge des Étoiles")


def c(id, nom, style, familleStyle, specialite, famille, fiche, lieu, apparence, questions, histoire, liens,
      rare=False, domaine="Univers"):
    return dict(id=id, nom=nom, style=style, familleStyle=familleStyle, rare=rare,
                specialite=specialite, famille=famille, domaine=domaine,
                fiche=fiche, generateur=None, difficulte=2, pays=lieu[0], lieu=lieu[1],
                apparence=apparence, questions=questions, histoire=histoire, liens=liens)


COMBATTANTS = [
    c("exosquelette", "Exosquelette", "Mécha", "creatures", "Exoplanètes", "Étoiles", "exoplanetes", FORGE,
      "Petit pilote extraterrestre bleu aux yeux jaunes perchés sur des antennes, aux commandes d'un mécha gris couvert d'autocollants de planètes, une antenne parabolique sur l'épaule.",
      "Les exoplanètes : types, zone habitable, exoplanètes célèbres, missions de recherche et biosignatures.",
      "Mécha de la Forge des Étoiles, Exosquelette part explorer les planètes qui tournent autour d'autres soleils, et colle un autocollant sur sa carlingue à chaque nouvelle découverte. Il cherche surtout celles de la zone habitable, ni trop chaudes ni trop froides. Proxima-Centaure lui garde une place chez elle ; Gladiaterre lui demande s'il a trouvé des voisins.",
      ["proxima-centaure", "gladiaterre"]),
]
assert len(COMBATTANTS[0]["histoire"]) <= 420
