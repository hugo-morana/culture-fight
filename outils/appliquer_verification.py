"""Applique les résultats de vérification (verification/resultats*.json) aux sources des questions
et remplit les colonnes statut, source et note de verification/faits.csv.

Corrections appliquées automatiquement : contexte, fait (énoncé), reponse, faux.
Usage : python3 outils/appliquer_verification.py [fichiers de résultats dont appliquer les corrections]
Sans argument, seuls les statuts sont mis à jour ; les corrections ne sont appliquées que pour les
fichiers donnés (pour ne pas réappliquer celles d'une passe précédente).
"""
import csv
import glob
import json
import os
import sys

RACINE = os.path.join(os.path.dirname(__file__), "..")
SOURCES = [os.path.join(RACINE, "outils", f) for f in
           ("contextes.py", "ajouts_vivant.py", "ajouts_corps_terre_arts.py")]
RES = os.path.join(RACINE, "CultureFight.swiftpm", "Resources")


def litteral(texte):
    return json.dumps(texte, ensure_ascii=False)


def remplacer_dans_sources(ancien, nouveau):
    """Remplace un texte Python littéral unique dans les sources ; renvoie True si fait."""
    vieux, neuf = litteral(ancien), litteral(nouveau)
    trouves = [(p, open(p, encoding="utf-8").read()) for p in SOURCES]
    trouves = [(p, s) for p, s in trouves if vieux in s]
    total = sum(s.count(vieux) for _, s in trouves)
    if total != 1:
        return False
    p, s = trouves[0]
    open(p, "w", encoding="utf-8").write(s.replace(vieux, neuf))
    return True


def remplacer_question(enonce, bonne=None, faux=None, nouvel_enonce=None):
    """Corrige une question fixe q(...) repérée par son énoncé."""
    for p in SOURCES:
        s = open(p, encoding="utf-8").read()
        debut = s.find("q(" + litteral(enonce))
        if debut < 0:
            continue
        fin = s.find("\n        q(", debut + 1)
        fin = s.find("    ]}", debut) if fin < 0 else fin
        bloc = s[debut:fin]
        neuf = bloc
        if faux is not None:
            i, j = neuf.find("["), neuf.find("]")
            neuf = neuf[:i] + "[" + ", ".join(litteral(f) for f in faux) + neuf[j:]
        if bonne is not None:
            ancienne = neuf.split(",", 1)[1].split(",", 1)[0].strip()
            neuf = neuf.replace(ancienne, litteral(bonne), 1)
        if nouvel_enonce is not None:
            neuf = neuf.replace(litteral(enonce), litteral(nouvel_enonce), 1)
        open(p, "w", encoding="utf-8").write(s[:debut] + neuf + s[fin:])
        return True
    return False


def main():
    chemin_csv = os.path.join(RACINE, "verification", "faits.csv")
    lignes = list(csv.DictReader(open(chemin_csv, encoding="utf-8")))
    par_n = {l["n"]: l for l in lignes}
    resultats = {}
    fichiers = sorted(glob.glob(os.path.join(RACINE, "verification", "resultats*.json")), key=os.path.getmtime)
    a_appliquer = {os.path.abspath(f) for f in sys.argv[1:]}
    for f in fichiers:
        for n, r in json.load(open(f, encoding="utf-8")).items():
            if os.path.abspath(f) not in a_appliquer:
                r = {k: v for k, v in r.items() if k != "correction"}
            if r.get("statut") in ("non trouvé", ""):
                continue  # pas encore cherché : la ligne reste « à vérifier »
            resultats[n] = r

    pays_p = os.path.join(RES, "pays_afrique.json")
    elements_p = os.path.join(RES, "elements.json")
    pays, elements = json.load(open(pays_p)), json.load(open(elements_p))
    a_faire_a_la_main = []

    for n, r in resultats.items():
        ligne = par_n.get(n)
        if not ligne:
            continue
        ligne["statut"], ligne["source"], ligne["note"] = r.get("statut", ""), r.get("source", ""), r.get("note", "")
        c = r.get("correction") or {}
        if not c:
            continue
        theme = ligne["theme"]
        if theme == "capitales" and set(c) <= {"contexte"}:
            next(p for p in pays if p["pays"] == ligne["fait"])["note"] = c["contexte"]
            continue
        if theme == "elements" and set(c) <= {"contexte"}:
            num = int(ligne["fait"].split()[0])
            next(e for e in elements if e["numero"] == num)["anecdote"] = c["contexte"]
            continue
        ok = True
        if "contexte" in c:
            ok &= remplacer_dans_sources(ligne["contexte"], c["contexte"])
        if any(k in c for k in ("reponse", "faux", "fait")):
            ok &= remplacer_question(ligne["fait"], c.get("reponse"), c.get("faux"), c.get("fait"))
        if not ok:
            a_faire_a_la_main.append((n, theme, ligne["fait"], c))

    json.dump(pays, open(pays_p, "w"), ensure_ascii=False, indent=1)
    json.dump(elements, open(elements_p, "w"), ensure_ascii=False, indent=1)
    with open(chemin_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(lignes[0]))
        w.writeheader()
        w.writerows(lignes)
    for x in a_faire_a_la_main:
        print("À CORRIGER À LA MAIN :", x)
    comptes = {}
    for l in lignes:
        comptes[l["statut"] or "(pas encore)"] = comptes.get(l["statut"] or "(pas encore)", 0) + 1
    print(comptes)


if __name__ == "__main__":
    main()
