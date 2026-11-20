"""Vérifie tous les jeux de données de l'app (tâche 18).

Usage : python3 outils/verifier.py
Lit CultureFight.swiftpm/Resources/*.json, contrôle le format commun décrit dans
outils/FORMAT.md et s'arrête avec le code 1 à la première série d'erreurs :
champs manquants ou vides, types incorrects, doublons, questions ambiguës, source absente.
"""
import json
import os
import re
import sys
from collections import Counter

from sources import SOURCES

ICI = os.path.dirname(os.path.abspath(__file__))
RESSOURCES = os.path.join(ICI, "..", "CultureFight.swiftpm", "Resources")
FAMILLES_ELEMENTS = {"", "gaz noble", "halogène"}

erreurs = []


def erreur(jeu, message):
    erreurs.append(f"[{jeu}] {message}")


def charger(nom):
    with open(os.path.join(RESSOURCES, nom), encoding="utf-8") as fh:
        return json.load(fh)


def champs(jeu, ou, objet, schema):
    """schema : {champ: type} ; un texte doit être non vide."""
    for champ, attendu in schema.items():
        if champ not in objet:
            erreur(jeu, f"{ou} : champ « {champ} » manquant")
            continue
        valeur = objet[champ]
        if attendu is int and (not isinstance(valeur, int) or isinstance(valeur, bool)):
            erreur(jeu, f"{ou} : « {champ} » devrait être un entier")
        elif attendu is str and not isinstance(valeur, str):
            erreur(jeu, f"{ou} : « {champ} » devrait être un texte")
        elif attendu is str and champ != "famille" and not valeur.strip():
            erreur(jeu, f"{ou} : « {champ} » est vide")
        elif attendu is list and not isinstance(valeur, list):
            erreur(jeu, f"{ou} : « {champ} » devrait être une liste")


def doublons(jeu, quoi, valeurs):
    for valeur, n in Counter(valeurs).items():
        if n > 1:
            erreur(jeu, f"{quoi} en double : « {valeur} » ({n} fois)")


def normaliser(texte):
    return re.sub(r"\s+", " ", texte.strip().lower())


def verifier_elements():
    jeu = "elements"
    donnees = charger("elements.json")
    for e in donnees:
        champs(jeu, f"élément {e.get('numero', '?')}", e,
               {"numero": int, "symbole": str, "nom": str, "famille": str, "notoriete": int, "anecdote": str})
        if e.get("famille") not in FAMILLES_ELEMENTS:
            erreur(jeu, f"élément {e.get('numero')} : famille inconnue « {e.get('famille')} »")
        if e.get("notoriete") not in (1, 2, 3):
            erreur(jeu, f"élément {e.get('numero')} : notoriété hors de 1 à 3")
    numeros = [e.get("numero") for e in donnees]
    if sorted(numeros) != list(range(1, 119)):
        erreur(jeu, "les numéros atomiques doivent aller de 1 à 118 sans trou")
    doublons(jeu, "symbole", [e.get("symbole") for e in donnees])
    doublons(jeu, "nom", [e.get("nom") for e in donnees])
    return len(donnees)


def verifier_pays():
    jeu = "pays-afrique"
    donnees = charger("pays_afrique.json")
    for p in donnees:
        champs(jeu, f"pays « {p.get('pays', '?')} »", p,
               {"pays": str, "capitale": str, "notoriete": int, "note": str})
        if p.get("notoriete") not in (1, 2, 3):
            erreur(jeu, f"{p.get('pays')} : notoriété hors de 1 à 3")
    if len(donnees) != 54:
        erreur(jeu, f"{len(donnees)} pays au lieu des 54 États africains membres de l'ONU")
    doublons(jeu, "pays", [p.get("pays") for p in donnees])
    doublons(jeu, "capitale", [p.get("capitale") for p in donnees])
    return len(donnees)


def verifier_fiches():
    donnees = charger("fiches.json")
    doublons("fiches", "identifiant de fiche", [f.get("id") for f in donnees])
    tous_enonces = []
    total = 0
    for f in donnees:
        jeu = f.get("id", "?")
        champs(jeu, "fiche", f, {"id": str, "relations": list, "questions": list})
        for n, r in enumerate(f.get("relations", [])):
            ou = f"relation {n}"
            champs(jeu, ou, r, {"modele": str, "explication": str, "paires": list})
            if "{x}" not in r.get("modele", ""):
                erreur(jeu, f"{ou} : le modèle doit contenir {{x}}")
            inverse = r.get("inverse")
            if inverse is not None and "{y}" not in inverse:
                erreur(jeu, f"{ou} : la question inverse doit contenir {{y}}")
            paires = r.get("paires", [])
            for p in paires:
                if not isinstance(p, list) or len(p) != 3 or not all(isinstance(t, str) and t.strip() for t in p):
                    erreur(jeu, f"{ou} : paire incomplète {p} (attendu : x, y, contexte)")
            xs = [p[0] for p in paires if p]
            ys = [p[1] for p in paires if len(p) > 1]
            doublons(jeu, f"{ou} : x", xs)
            if len(set(ys)) < 4:
                erreur(jeu, f"{ou} : moins de 4 réponses différentes, impossible de faire un QCM")
            if inverse:
                doublons(jeu, f"{ou} : y (question inverse ambiguë)", ys)
            tous_enonces += [normaliser(r.get("modele", "").replace("{x}", x)) for x in xs]
            total += len(paires) * (2 if inverse else 1)
        for qq in f.get("questions", []):
            ou = f"question « {qq.get('enonce', '?')[:50]} »"
            champs(jeu, ou, qq, {"enonce": str, "bonne": str, "faux": list, "explication": str})
            faux = qq.get("faux", [])
            if len({normaliser(t) for t in faux}) < 3:
                erreur(jeu, f"{ou} : il faut au moins 3 mauvaises réponses différentes")
            if normaliser(qq.get("bonne", "")) in {normaliser(t) for t in faux}:
                erreur(jeu, f"{ou} : la bonne réponse figure parmi les mauvaises")
            tous_enonces.append(normaliser(qq.get("enonce", "")))
            total += 1
    doublons("fiches", "énoncé", tous_enonces)
    return donnees, total


def verifier_sources(identifiants):
    for jeu in identifiants:
        liste = SOURCES.get(jeu)
        if not liste:
            erreur(jeu, "aucune source dans outils/sources.py")
            continue
        for titre, url in liste:
            if not titre.strip() or not url.startswith("https://"):
                erreur(jeu, f"source mal formée : {titre} {url}")
    for jeu in sorted(set(SOURCES) - set(identifiants)):
        erreur(jeu, "source pour un jeu de données qui n'existe pas")


def verifier_sources_json():
    exporte = {d["id"]: [(x["titre"], x["url"]) for x in d["sources"]] for d in charger("sources.json")}
    attendu = {jeu: list(liste) for jeu, liste in SOURCES.items()}
    if exporte != attendu:
        erreur("sources", "Resources/sources.json n'est pas à jour : lancer python3 outils/sources.py")


def ids_du_catalogue():
    chemin = os.path.join(ICI, "..", "CultureFight.swiftpm", "Moteur", "Catalogue.swift")
    with open(chemin, encoding="utf-8") as fh:
        return re.findall(r'id: "([a-z0-9-]+)", nom: "[^"]*", style:', fh.read())


def verifier_monde_et_histoires():
    monde = charger("monde.json")
    champs("monde", "monde", monde, {"nom": str, "description": str, "pays": list})
    lieux = {}
    for p in monde.get("pays", []):
        ou = f"pays « {p.get('id', '?')} »"
        champs("monde", ou, p, {"id": str, "nom": str, "domaine": str, "capitale": str,
                                "description": str, "lieux": list})
        noms = [l.get("nom") for l in p.get("lieux", [])]
        for l in p.get("lieux", []):
            champs("monde", f"{ou}, lieu", l, {"nom": str, "description": str})
        if p.get("capitale") not in noms:
            erreur("monde", f"{ou} : la capitale doit figurer parmi les lieux")
        doublons("monde", f"{ou} : lieu", noms)
        lieux[p.get("id")] = set(noms)
    doublons("monde", "identifiant de pays", [p.get("id") for p in monde.get("pays", [])])
    doublons("monde", "domaine", [p.get("domaine") for p in monde.get("pays", [])])

    histoires = charger("histoires.json")
    ids = ids_du_catalogue()
    doublons("histoires", "histoire du combattant", [h.get("id") for h in histoires])
    for h in histoires:
        ou = f"histoire de « {h.get('id', '?')} »"
        champs("histoires", ou, h, {"id": str, "pays": str, "lieu": str, "histoire": str, "liens": list})
        if h.get("id") not in ids:
            erreur("histoires", f"{ou} : combattant absent du catalogue")
        if h.get("pays") not in lieux:
            erreur("histoires", f"{ou} : pays inconnu « {h.get('pays')} »")
        elif h.get("lieu") not in lieux[h.get("pays")]:
            erreur("histoires", f"{ou} : lieu « {h.get('lieu')} » absent du pays « {h.get('pays')} »")
        for lien in h.get("liens", []):
            if lien not in ids or lien == h.get("id"):
                erreur("histoires", f"{ou} : lien vers « {lien} » invalide")
        if len(h.get("histoire", "")) > 420:
            erreur("histoires", f"{ou} : plus de 420 caractères, trop long pour la fiche")
    for manquant in sorted(set(ids) - {h.get("id") for h in histoires}):
        erreur("histoires", f"« {manquant} » n'a pas d'histoire")
    return len(monde.get("pays", [])), len(histoires), len(ids)


if __name__ == "__main__":
    n_elements = verifier_elements()
    n_pays = verifier_pays()
    fiches, n_questions = verifier_fiches()
    verifier_sources(["elements", "pays-afrique"] + [f["id"] for f in fiches])
    verifier_sources_json()
    n_pays_monde, n_histoires, n_combattants = verifier_monde_et_histoires()
    print(f"elements.json      {n_elements} éléments")
    print(f"pays_afrique.json  {n_pays} pays")
    print(f"fiches.json        {len(fiches)} fiches, {n_questions} questions")
    print(f"{2 + len(fiches)} jeux de données, {len(SOURCES)} avec sources")
    print(f"monde.json         {n_pays_monde} pays ; histoires.json {n_histoires} histoires pour {n_combattants} combattants")
    if erreurs:
        for e in erreurs:
            print("ERREUR", e)
        print(f"{len(erreurs)} erreur(s)")
        sys.exit(1)
    print("Aucune erreur.")
