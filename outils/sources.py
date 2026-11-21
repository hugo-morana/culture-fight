"""Sources de chaque jeu de données (tâche 19).

Clé = identifiant du jeu : « elements », « pays-afrique » ou l'identifiant d'une fiche.
outils/verifier.py refuse un jeu de données sans source.
"""

W = "https://fr.wikipedia.org/wiki/"
WEN = "https://en.wikipedia.org/wiki/"

SOURCES = {
    "elements": [("Tableau périodique de l'IUPAC", "https://iupac.org/what-we-do/periodic-table-of-elements/"),
                 ("Tableau périodique des éléments", W + "Tableau_p%C3%A9riodique_des_%C3%A9l%C3%A9ments")],
    "pays-afrique": [("The World Factbook (CIA)", "https://www.cia.gov/the-world-factbook/"),
                     ("Liste des capitales du monde", W + "Liste_des_capitales_du_monde")],
    "cetaces": [("Cetacea", W + "Cetacea")],
    "arbres": [("Arbre", W + "Arbre")],
    "fleurs": [("Fleur", W + "Fleur"), ("Liste des emblèmes floraux", WEN + "List_of_national_flowers")],
    "champignons": [("Fungi", W + "Fungi")],
    "rapaces": [("Rapace", W + "Rapace"), ("Oiseaux de France, LPO", "https://www.oiseaux.net/")],
    "felins": [("Felidae", W + "Felidae")],
    "primates": [("Primates", W + "Primates")],
    "insectes": [("Insecta", W + "Insecta")],
    "reptiles": [("Reptilia", W + "Reptilia")],
    "dinosaures": [("Dinosauria", W + "Dinosauria")],
    "eres-geologiques": [("Charte chronostratigraphique internationale (ICS)", "https://stratigraphy.org/chart"),
                         ("Échelle des temps géologiques", W + "%C3%89chelle_des_temps_g%C3%A9ologiques")],
    "os": [("Squelette humain", W + "Squelette_humain")],
    "organes": [("Anatomie humaine", W + "Anatomie_humaine")],
    "muscles": [("Liste des muscles du corps humain", W + "Liste_des_muscles_du_corps_humain")],
    "volcans": [("Global Volcanism Program (Smithsonian)", "https://volcano.si.edu/"),
                ("Volcan", W + "Volcan")],
    "seismes": [("Earthquake Hazards Program (USGS)", "https://earthquake.usgs.gov/"),
                ("Séisme", W + "S%C3%A9isme")],
    "fleuves-europe": [("List of rivers of Europe", WEN + "List_of_rivers_of_Europe")],
    "fleuves-monde": [("List of river systems by length", WEN + "List_of_river_systems_by_length")],
    "lacs": [("List of lakes by area", WEN + "List_of_lakes_by_area")],
    "oceans-mers": [("Limites des océans et des mers (OHI)", "https://iho.int/"),
                    ("Océan", W + "Oc%C3%A9an")],
    "peintres-renaissance": [("Italian Renaissance painting", WEN + "Italian_Renaissance_painting"),
                             ("Northern Renaissance", WEN + "Northern_Renaissance")],
    "gaz-nobles": [("Gaz noble", W + "Gaz_noble")],
    "halogenes": [("Halogène", W + "Halog%C3%A8ne")],
}


# Fiches créées avant la règle « une source par question » (tâche 52). Leurs questions sans source
# sont signalées sans bloquer ; verification/faits.csv suit leur vérification. Toute nouvelle fiche
# doit donner une source pour chaque paire et chaque question.
FICHES_ANTERIEURES = {
    "cetaces", "arbres", "fleurs", "champignons", "rapaces", "felins", "primates", "insectes",
    "reptiles", "dinosaures", "eres-geologiques", "os", "organes", "muscles", "volcans", "seismes",
    "fleuves-europe", "fleuves-monde", "lacs", "oceans-mers", "peintres-renaissance",
    "gaz-nobles", "halogenes",
}


def _ajouter_vague2():
    import os
    import sys
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import vague2
    import vague3
    import vague4
    import vague5
    import vague6
    import vague7
    import vague8
    import vague9
    import vague10
    for vague in (vague2, vague3, vague4, vague5, vague6, vague7, vague8, vague9, vague10):
        for module in vague.modules():
            SOURCES[module.FICHE["id"]] = list(module.SOURCES_GENERALES)


_ajouter_vague2()


def exporter():
    """Écrit Resources/sources.json, lu par la fiche des combattants."""
    import json
    import os
    sortie = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "CultureFight.swiftpm",
                          "Resources", "sources.json")
    donnees = [{"id": jeu, "sources": [{"titre": t, "url": u} for t, u in liste]}
               for jeu, liste in SOURCES.items()]
    with open(sortie, "w", encoding="utf-8") as fh:
        json.dump(donnees, fh, ensure_ascii=False, indent=1)
    return donnees


if __name__ == "__main__":
    print(f"{len(exporter())} jeux de données écrits dans Resources/sources.json")
