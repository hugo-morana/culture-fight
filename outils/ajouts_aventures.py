"""Questions tirées des Aventures de Culturia (tâche 150) : les faits de chaque aventure entrent dans les questions
des combattants concernés quand leur fiche ne les contenait pas encore.
"""


def q(enonce, bonne, faux, explication, source=None):
    question = {"enonce": enonce, "bonne": bonne, "faux": faux, "explication": explication}
    if source:
        question["source"] = source
    return question


AJOUTS = {
    # Aventure 1 : La ronde des huit grelots
    "terre": {"relations": [], "questions": [
        q("Quelle part de la surface de la Terre l'océan couvre-t-il ?", "Environ 71 %",
          ["Environ 50 %", "Environ 90 %", "Environ 30 %"],
          "Profond en moyenne de 3,6 km, l'océan mondial contient 97 % de l'eau de la planète et cache presque tous ses volcans.",
          "https://science.nasa.gov/earth/facts/"),
    ]},
    "jupiter": {"relations": [], "questions": [
        q("Comment la masse de Jupiter se compare-t-elle à celle de toutes les autres planètes réunies ?", "Plus du double",
          ["La moitié", "À peu près autant", "Cent fois plus"],
          "Elle a pris l'essentiel de la matière restée après la naissance du Soleil, sans devenir assez lourde pour s'allumer comme une étoile.",
          "https://science.nasa.gov/jupiter/facts/"),
    ]},
    # Aventure 2 : Les six cloches de Néonja
    "gaz-nobles": {"relations": [], "questions": [
        q("Par où le radon entre-t-il surtout dans les maisons ?", "Par les sous-sols",
          ["Par les cheminées", "Par les fenêtres", "Par la toiture"],
          "Né de l'uranium et du radium de roches comme le granite, ce gaz radioactif plus lourd que l'air remonte à travers le sol.",
          "https://www.britannica.com/science/radon"),
        q("Quels chimistes ont isolé le néon, le krypton et le xénon en 1898 ?", "William Ramsay et Morris Travers",
          ["Marie et Pierre Curie", "Lavoisier et Berthollet", "Rayleigh et Cavendish"],
          "Au University College de Londres, ils les ont séparés en refroidissant de l'argon et de l'air jusqu'à les liquéfier.",
          "https://www.chem.ucl.ac.uk/resources/history/chemhistucl/hist15.html"),
    ]},
    # Aventure 3 : Le duel du centre du monde
    "astronomes-antiquite": {"relations": [], "questions": [
        q("Pendant combien de temps environ le système de Ptolémée, avec la Terre au centre, a-t-il dominé ?", "Environ 1 400 ans",
          ["Environ 140 ans", "Environ 400 ans", "Environ 3 000 ans"],
          "Exposé dans l'Almageste vers l'an 150, il n'a été remplacé qu'après le livre de Copernic, paru en 1543.",
          "https://mathshistory.st-andrews.ac.uk/Biographies/Ptolemy/"),
    ]},
    "copernic-heliocentrisme": {"relations": [], "questions": [
        q("Dans quelle ville a été imprimé « De revolutionibus », le grand livre de Copernic ?", "Nuremberg",
          ["Cracovie", "Rome", "Venise"],
          "L'imprimeur Johannes Petreius l'a publié en 1543, l'année de la mort de l'astronome ; l'ouvrage compte environ 400 pages.",
          "https://en.wikipedia.org/wiki/De_revolutionibus_orbium_coelestium"),
    ]},
    "physiciens-celebres": {"relations": [], "questions": [
        q("Quelle observation de Galilée montre que Vénus tourne autour du Soleil ?", "Ses phases, comme celles de la Lune",
          ["Ses anneaux", "Ses quatre lunes", "Sa grande tache rouge"],
          "Vénus passe du fin croissant au disque plein en rapetissant à l'œil, ce que le modèle de Ptolémée ne permet pas.",
          "https://www.cabinet.ox.ac.uk/node/6093"),
    ]},
}
