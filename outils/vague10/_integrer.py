"""Ajoute les 26 combattants de la vague 10 au jeu, une fois toutes leurs fiches prêtes.

Usage (depuis la racine du dépôt), après python3 outils/fiches.py et python3 outils/sources.py :
    python3 outils/vague10/_integrer.py
- refuse s'il manque une fiche, si une fiche n'a pas son minimum de questions ou a une question sans source,
  ou s'il manque une illustration ;
- copie les illustrations dans Resources/combattant-<id>.jpg ;
- ajoute les combattants à Catalogue.prototype (bloc « Vague 10 ») et leurs histoires à histoires.json.
"""
import json
import os
import shutil
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
RACINE = os.path.join(ICI, "..", "..")
sys.path.insert(0, ICI)
sys.path.insert(0, os.path.dirname(ICI))

from _combattants import COMBATTANTS  # noqa: E402
from fiches import COMPLEMENTS, MINIMUM  # noqa: E402

RES = os.path.join(RACINE, "CultureFight.swiftpm", "Resources")
CATALOGUE = os.path.join(RACINE, "CultureFight.swiftpm", "Moteur", "Catalogue.swift")
MARQUE = "        // Vague 10 (outils/vague10)"


def swift(texte):
    return json.dumps(texte, ensure_ascii=False)


def entree(c):
    commun = (f"id: {swift(c['id'])}, nom: {swift(c['nom'])}, style: {swift(c['style'])}, "
              f"familleStyle: .{c['familleStyle']},\n")
    if c["generateur"] is None:
        return (f"        aFiche({commun}"
                f"               specialite: {swift(c['specialite'])}, famille: {swift(c['famille'])}, "
                f"domaine: {swift(c['domaine'])}, fiche: {swift(c['fiche'])},\n"
                f"               apparence: {swift(c['apparence'])},\n"
                f"               questions: {swift(c['questions'])}"
                + (", rarete: .rare" if c.get("rare") else "") + "),")
    return (f"        aGenerateur({commun}"
            f"                    specialite: {swift(c['specialite'])}, famille: {swift(c['famille'])}, "
            f"domaine: {swift(c['domaine'])}, idSpecialite: {swift(c['fiche'] or c['id'])},\n"
            f"                    difficulte: {c['difficulte']}, apparence: {swift(c['apparence'])},\n"
            f"                    questions: {swift(c['questions'])},\n"
            f"                    generateur: {c['generateur']}),")


def main():
    fiches = {f["id"]: f for f in json.load(open(os.path.join(RES, "fiches.json"), encoding="utf-8"))}
    erreurs = []
    for c in COMBATTANTS:
        if c["fiche"]:
            f = fiches.get(c["fiche"])
            if not f:
                erreurs.append(f"fiche « {c['fiche']} » absente de fiches.json")
            else:
                n = len(f["questions"]) + sum(len(r["paires"]) * (2 if r["inverse"] else 1) for r in f["relations"])
                sans = sum(1 for r in f["relations"] for p in r["paires"] if len(p) < 4) + \
                    sum(1 for q in f["questions"] if not q.get("source"))
                minimum = MINIMUM - COMPLEMENTS.get(c["fiche"], 0)
                if n < minimum or sans:
                    erreurs.append(f"fiche « {c['fiche']} » : {n} questions (minimum {minimum}), {sans} sans source")
        if not os.path.exists(os.path.join(RACINE, "illustrations", f"{c['id']}.jpg")):
            erreurs.append(f"illustration de {c['id']} absente")
    if erreurs:
        print("\n".join("ERREUR : " + e for e in erreurs))
        sys.exit(1)

    for c in COMBATTANTS:
        shutil.copyfile(os.path.join(RACINE, "illustrations", f"{c['id']}.jpg"),
                        os.path.join(RES, f"combattant-{c['id']}.jpg"))

    source = open(CATALOGUE, encoding="utf-8").read()
    if MARQUE not in source:
        bloc = "\n".join([MARQUE] + [entree(c) for c in COMBATTANTS])
        fin = source.rindex("    ]\n}")
        source = source[:fin] + bloc + "\n" + source[fin:]
        open(CATALOGUE, "w", encoding="utf-8").write(source)

    chemin = os.path.join(RES, "histoires.json")
    histoires = json.load(open(chemin, encoding="utf-8"))
    deja = {h["id"] for h in histoires}
    for c in COMBATTANTS:
        if c["id"] not in deja:
            histoires.append({"id": c["id"], "pays": c["pays"], "lieu": c["lieu"],
                              "histoire": c["histoire"], "liens": c["liens"]})
    json.dump(histoires, open(chemin, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"{len(COMBATTANTS)} combattants ajoutés au jeu.")


if __name__ == "__main__":
    main()
