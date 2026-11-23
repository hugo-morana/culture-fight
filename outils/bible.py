"""Bible de Culturia (tâche 147) : document de référence pour écrire les aventures.

Génère aventures/bible-culturia.md à partir de Resources/monde.json, Resources/histoires.json et du catalogue
(Catalogue.swift, Legendaires.swift). À relancer après chaque vague : python3 outils/bible.py

Pour chaque pays : sa description, ses lieux, puis chaque combattant jouable avec son lieu, son caractère et
ses manies (son histoire) et ses liens (amitiés, rivalités, jumeaux) vers d'autres combattants.
La chronologie de Culturia est remplie par les aventures (aventures.json), dans l'ordre de leur champ « ordre ».
"""
import json
import os
import re

ICI = os.path.dirname(os.path.abspath(__file__))
RES = os.path.join(ICI, "..", "CultureFight.swiftpm", "Resources")
MOTEUR = os.path.join(ICI, "..", "CultureFight.swiftpm", "Moteur")
SORTIE = os.path.join(ICI, "..", "aventures", "bible-culturia.md")


def charger(nom):
    with open(os.path.join(RES, nom), encoding="utf-8") as fh:
        return json.load(fh)


def catalogue():
    """{id: (nom, style, spécialité, famille, domaine)} des combattants jouables et des Légendaires."""
    fiches = {}
    for fichier in ("Catalogue.swift", "Legendaires.swift"):
        with open(os.path.join(MOTEUR, fichier), encoding="utf-8") as fh:
            texte = fh.read()
        for m in re.finditer(r'id: "([a-z0-9-]+)", nom: "([^"]*)", style: "([^"]*)"(.*?)domaine: "([^"]*)"', texte, re.S):
            bloc = m.group(4)
            spe = re.search(r'specialite: "([^"]*)"', bloc)
            fam = re.search(r'famille: "([^"]*)"', bloc)
            fiches.setdefault(m.group(1), (m.group(2), m.group(3), spe.group(1) if spe else "",
                                           fam.group(1) if fam else "", m.group(5)))
    return fiches


def main():
    monde = charger("monde.json")
    histoires = {h["id"]: h for h in charger("histoires.json")}
    fiches = catalogue()
    try:
        aventures = charger("aventures.json")
    except FileNotFoundError:
        aventures = []
    nom = lambda i: fiches.get(i, (i,))[0]

    l = ["# Bible de Culturia", "",
         "_Document généré par `outils/bible.py` à partir de `monde.json`, `histoires.json` et du catalogue. "
         "Ne pas modifier à la main : corriger les données, puis relancer le script._", "",
         "Règles d'écriture des aventures : rester fidèle au lieu, au caractère et aux liens de chaque combattant ; "
         "chaque fait appris est réel et sourcé ; une touche d'humour, jamais aux dépens d'une personne réelle ; chaque date est encodée en MemoHugoDate (matière = siècle, objet = année, couleur = mois, motifs = jour) et l'objet joue un rôle dans la case (dans l'app, 81 = fumée au lieu de la cigarette).", "",
         f"## {monde['nom']}", "", monde["description"], ""]
    agora = monde.get("agora") or {}
    if agora:
        l += [f"**{agora.get('nom', 'Agora')}** : {agora.get('description', '')}", ""]

    l += ["## Chronologie", ""]
    if aventures:
        for a in sorted(aventures, key=lambda a: a.get("ordre", 0)):
            l.append(f"{a.get('ordre')}. **{a.get('titre')}** ({a.get('lieu')}) : {a.get('objectif')}")
    else:
        l.append("_Aucune aventure pour l'instant : la chronologie se remplit avec `aventures.json`._")
    l.append("")

    total = 0
    for p in monde["pays"]:
        membres = sorted((h for h in histoires.values() if h["pays"] == p["id"]), key=lambda h: (h["lieu"], nom(h["id"])))
        l += [f"## {p['nom']} — domaine {p['domaine']}", "", p["description"], "", f"Capitale : **{p['capitale']}**", "",
              "### Lieux", ""]
        for lieu in p["lieux"]:
            l.append(f"- **{lieu['nom']}** : {lieu['description']}")
        l += ["", f"### Habitants ({len(membres)})", ""]
        for h in membres:
            f = fiches.get(h["id"], (h["id"], "", "", "", ""))
            liens = ", ".join(nom(x) for x in h.get("liens", [])) or "aucun"
            l += [f"#### {f[0]}", "",
                  f"- {f[1]}, spécialité « {f[2]} » ({f[3]}) ; vit à {h['lieu']}.",
                  f"- Caractère et manies : {h['histoire']}",
                  f"- Liens : {liens}.", ""]
            total += 1
    l.insert(3, f"_{len(monde['pays'])} pays, {sum(len(p['lieux']) for p in monde['pays'])} lieux, {total} habitants._")
    os.makedirs(os.path.dirname(SORTIE), exist_ok=True)
    with open(SORTIE, "w", encoding="utf-8") as fh:
        fh.write("\n".join(l) + "\n")
    print(f"{total} habitants dans {os.path.relpath(SORTIE, os.path.join(ICI, '..'))}")


if __name__ == "__main__":
    main()
