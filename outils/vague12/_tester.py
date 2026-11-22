"""Teste une seule fiche de la vague 12 : python3 vague12/_tester.py <module> (depuis outils/)."""
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import fiches as F  # noqa: E402

module = importlib.import_module(f"vague12.{sys.argv[1]}")
fiche = module.FICHE
F.ajouter_contextes(fiche)
total, erreurs = F.verifier(fiche)
manque = F.sans_source(fiche)
minimum = F.MINIMUM - F.COMPLEMENTS.get(fiche["id"], 0)
if total < minimum:
    erreurs.append(f"{total} questions, il en faut au moins {minimum}")
if manque:
    erreurs.append(f"{manque} paires ou questions sans source")
if not module.SOURCES_GENERALES:
    erreurs.append("SOURCES_GENERALES est vide")
enonces = [q["enonce"] for q in fiche["questions"]]
for e in sorted({e for e in enonces if enonces.count(e) > 1}):
    erreurs.append(f"question en double : « {e} »")
print(f"{fiche['id']} : {total} questions (minimum {minimum}), {manque} sans source")
for e in erreurs:
    print("   ERREUR :", e)
sys.exit(1 if erreurs else 0)
