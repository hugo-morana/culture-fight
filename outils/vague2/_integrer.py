"""Ajoute les 29 combattants de la vague 2 au jeu, une fois leurs 29 fiches prêtes.

Usage (depuis la racine du dépôt) : python3 outils/vague2/_integrer.py
- refuse s'il manque une fiche ou si une fiche a moins de 60 questions ou une question sans source ;
- copie les illustrations dans Resources/combattant-<id>.jpg ;
- ajoute les combattants à Catalogue.prototype (bloc « Vague 2 ») et leurs histoires à histoires.json.
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

RES = os.path.join(RACINE, "CultureFight.swiftpm", "Resources")
CATALOGUE = os.path.join(RACINE, "CultureFight.swiftpm", "Moteur", "Catalogue.swift")
MARQUE = "        // Vague 2 (outils/vague2)"


def swift(texte):
    return json.dumps(texte, ensure_ascii=False)


def main():
    fiches = {f["id"]: f for f in json.load(open(os.path.join(RES, "fiches.json"), encoding="utf-8"))}
    erreurs = []
    for c in COMBATTANTS:
        f = fiches.get(c[7])
        if not f:
            erreurs.append(f"fiche « {c[7]} » absente de fiches.json")
            continue
        n = len(f["questions"]) + sum(len(r["paires"]) * (2 if r["inverse"] else 1) for r in f["relations"])
        sans = sum(1 for r in f["relations"] for p in r["paires"] if len(p) < 4) + \
            sum(1 for q in f["questions"] if not q.get("source"))
        if n < 60 or sans:
            erreurs.append(f"fiche « {c[7]} » : {n} questions, {sans} sans source")
        if not os.path.exists(os.path.join(RACINE, "illustrations", f"{c[0]}.jpg")):
            erreurs.append(f"illustration de {c[0]} absente")
    if erreurs:
        print("\n".join("ERREUR : " + e for e in erreurs))
        sys.exit(1)

    for c in COMBATTANTS:
        shutil.copyfile(os.path.join(RACINE, "illustrations", f"{c[0]}.jpg"),
                        os.path.join(RES, f"combattant-{c[0]}.jpg"))

    source = open(CATALOGUE, encoding="utf-8").read()
    if MARQUE not in source:
        lignes = [MARQUE]
        for (id_, nom, style, famille_style, spec, famille, domaine, fiche, _p, _l, apparence, questions, _h, _li) in COMBATTANTS:
            lignes.append(
                f"        aFiche(id: {swift(id_)}, nom: {swift(nom)}, style: {swift(style)}, familleStyle: .{famille_style},\n"
                f"               specialite: {swift(spec)}, famille: {swift(famille)}, domaine: {swift(domaine)}, fiche: {swift(fiche)},\n"
                f"               apparence: {swift(apparence)},\n"
                f"               questions: {swift(questions)}),")
        fin = source.rindex("    ]\n}")
        source = source[:fin] + "\n".join(lignes) + "\n" + source[fin:]
        open(CATALOGUE, "w", encoding="utf-8").write(source)

    chemin = os.path.join(RES, "histoires.json")
    histoires = json.load(open(chemin, encoding="utf-8"))
    deja = {h["id"] for h in histoires}
    for c in COMBATTANTS:
        if c[0] not in deja:
            histoires.append({"id": c[0], "pays": c[8], "lieu": c[9], "histoire": c[12], "liens": c[13]})
    json.dump(histoires, open(chemin, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"{len(COMBATTANTS)} combattants ajoutés au jeu.")


if __name__ == "__main__":
    main()
