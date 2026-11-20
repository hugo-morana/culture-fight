"""Liste des faits écrits aux tâches 20 et 21, à vérifier un à un (verification/faits.csv)."""
import csv, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from ajouts_vivant import AJOUTS as A1
from ajouts_corps_terre_arts import AJOUTS as A2
from contextes import CONTEXTES

RES = os.path.join(os.path.dirname(__file__), "..", "CultureFight.swiftpm", "Resources")
lignes = []
def ajout(theme, fait, reponse, contexte):
    lignes.append({"n": len(lignes) + 1, "theme": theme, "fait": fait, "reponse": reponse,
                   "contexte": contexte, "statut": "", "source": "", "note": ""})

# Tâche 21 : contextes des paires existantes, notes des capitales, anecdotes des éléments
fiches = {f["id"]: f for f in json.load(open(os.path.join(RES, "fiches.json")))}
for (fid, n), ctx in CONTEXTES.items():
    for x, texte in ctx.items():
        y = next(p[1] for p in fiches[fid]["relations"][n]["paires"] if p[0] == x)
        ajout(fid, x, y, texte)
for p in json.load(open(os.path.join(RES, "pays_afrique.json"))):
    ajout("capitales", p["pays"], p["capitale"], p["note"])
for e in json.load(open(os.path.join(RES, "elements.json"))):
    ajout("elements", f"{e['numero']} {e['symbole']}", e["nom"], e["anecdote"])
# Tâche 20 : relations et questions ajoutées
for A in (A1, A2):
    for fid, c in A.items():
        for r in c["relations"]:
            for p in r["paires"]:
                ajout(fid, r["modele"].replace("{x}", p[0]), p[1], p[2])
        for qq in c["questions"]:
            ajout(fid, qq["enonce"], qq["bonne"], qq["explication"])

with open(os.path.join(os.path.dirname(__file__), "..", "verification", "faits.csv"), "w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(lignes[0]))
    w.writeheader(); w.writerows(lignes)
print(len(lignes), "faits")
