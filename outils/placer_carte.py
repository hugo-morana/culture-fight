"""Place les pays et les lieux de Culturia sur la carte (tâche 55).

Usage : python3 outils/placer_carte.py
Écrit dans CultureFight.swiftpm/Resources/monde.json les positions de la carte, en coordonnées
de 0 à 1 (x vers la droite, y vers le bas) :
- l'Agora au centre ;
- chaque pays sur un anneau autour de l'Agora (champs x, y et rayon), d'autant plus grand
  qu'il a de lieux et de combattants ;
- chaque lieu dans son pays (champs x, y) : la capitale au centre, les autres en spirale.

Le calcul est déterministe : relancer le script après avoir ajouté un lieu ou un pays
replace tout proprement. outils/verifier.py contrôle le résultat à chaque compilation.
"""
import json
import math
import os
from collections import Counter

ICI = os.path.dirname(os.path.abspath(__file__))
RESSOURCES = os.path.join(ICI, "..", "CultureFight.swiftpm", "Resources")

# Ordre des pays autour de l'Agora, dans le sens des aiguilles d'une montre depuis le haut :
# des voisins qui se parlent (la Matière près de l'Univers et du Corps, l'Histoire près du Monde…).
ORDRE = ["atomie", "astralis", "calculie", "fabulie", "palettia",
         "chronie", "mappemondie", "geonie", "sylvanie", "anatomia"]

CENTRE = (0.5, 0.5)
ANNEAU = 0.335          # distance de l'Agora au centre des pays
RAYON_MIN, RAYON_MAX = 0.075, 0.15
ECART = 0.012           # mer minimale entre deux pays voisins


def arrondi(v):
    return round(v, 4)


def placer(monde, histoires):
    combattants = Counter(h["pays"] for h in histoires)
    pays = {p["id"]: p for p in monde["pays"]}
    ordre = [i for i in ORDRE if i in pays] + [i for i in pays if i not in ORDRE]

    # Taille : selon le nombre de lieux et de combattants (racine, pour rester lisible).
    poids = {i: math.sqrt(len(pays[i]["lieux"]) + combattants[i] / 3) for i in ordre}
    pmin, pmax = min(poids.values()), max(poids.values())
    rayons = {i: RAYON_MIN + (RAYON_MAX - RAYON_MIN) * ((poids[i] - pmin) / ((pmax - pmin) or 1)) for i in ordre}

    # Angles : chaque pays occupe sur l'anneau une part proportionnelle à son diamètre.
    perimetre = 2 * math.pi * ANNEAU
    besoin = sum(2 * r + ECART for r in rayons.values())
    if besoin > perimetre:
        echelle = (perimetre - ECART * len(ordre)) / sum(2 * r for r in rayons.values())
        rayons = {i: r * echelle for i, r in rayons.items()}
    marge = (perimetre - sum(2 * r for r in rayons.values())) / len(ordre)
    angle = -math.pi / 2 - (rayons[ordre[0]] + marge / 2) / ANNEAU
    for i in ordre:
        part = (2 * rayons[i] + marge) / ANNEAU
        milieu = angle + part / 2
        angle += part
        p = pays[i]
        p["x"] = arrondi(CENTRE[0] + ANNEAU * math.cos(milieu))
        p["y"] = arrondi(CENTRE[1] + ANNEAU * math.sin(milieu))
        p["rayon"] = arrondi(rayons[i])

        # Lieux : capitale au centre, puis spirale de Fermat (angle d'or) jusqu’à 78 % du rayon.
        autres = [l for l in p["lieux"] if l["nom"] != p["capitale"]]
        for l in p["lieux"]:
            if l["nom"] == p["capitale"]:
                l["x"], l["y"] = p["x"], p["y"]
        for k, l in enumerate(autres, start=1):
            d = 0.78 * rayons[i] * math.sqrt(k / len(autres))
            a = k * math.radians(137.508) + milieu
            l["x"] = arrondi(p["x"] + d * math.cos(a))
            l["y"] = arrondi(p["y"] + d * math.sin(a))

    monde["agora"]["x"], monde["agora"]["y"] = CENTRE
    return monde


def main():
    chemin = os.path.join(RESSOURCES, "monde.json")
    with open(chemin, encoding="utf-8") as fh:
        monde = json.load(fh)
    with open(os.path.join(RESSOURCES, "histoires.json"), encoding="utf-8") as fh:
        histoires = json.load(fh)
    placer(monde, histoires)
    with open(chemin, "w", encoding="utf-8") as fh:
        json.dump(monde, fh, ensure_ascii=False, indent=1)
        fh.write("\n")
    for p in monde["pays"]:
        print(f"{p['nom']:<12} x={p['x']:.3f} y={p['y']:.3f} rayon={p['rayon']:.3f} · {len(p['lieux'])} lieux")


if __name__ == "__main__":
    main()
