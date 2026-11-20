"""Teste une seule fiche de la vague 2 : python3 vague2/_tester.py <module> (depuis outils/)."""
import importlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import fiches as F  # noqa: E402

module = importlib.import_module(f"vague2.{sys.argv[1]}")
fiche = module.FICHE
F.ajouter_contextes(fiche)
total, erreurs = F.verifier(fiche)
manque = F.sans_source(fiche)
if total < 60:
    erreurs.append(f"{total} questions, il en faut au moins 60")
if manque:
    erreurs.append(f"{manque} paires ou questions sans source")
if not module.SOURCES_GENERALES:
    erreurs.append("SOURCES_GENERALES est vide")
print(f"{fiche['id']} : {total} questions, {manque} sans source")
for e in erreurs:
    print("   ERREUR :", e)
sys.exit(1 if erreurs else 0)
