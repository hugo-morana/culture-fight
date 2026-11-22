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

from sources import FICHES_ANTERIEURES, SOURCES

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
                if not isinstance(p, list) or len(p) not in (3, 4) or not all(isinstance(t, str) and t.strip() for t in p):
                    erreur(jeu, f"{ou} : paire incomplète {p} (attendu : x, y, contexte, source)")
                elif len(p) == 4 and not p[3].startswith("https://"):
                    erreur(jeu, f"{ou} : source mal formée pour « {p[0]} » (URL https attendue)")
                elif len(p) == 3 and jeu not in FICHES_ANTERIEURES:
                    erreur(jeu, f"{ou} : pas de source pour « {p[0]} » (obligatoire pour une nouvelle fiche)")
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
            source = qq.get("source")
            if source is not None and not str(source).startswith("https://"):
                erreur(jeu, f"{ou} : source mal formée (URL https attendue)")
            elif source is None and jeu not in FICHES_ANTERIEURES:
                erreur(jeu, f"{ou} : pas de source (obligatoire pour une nouvelle fiche)")
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


def domaines_du_catalogue():
    """Domaine de chaque combattant du catalogue : {identifiant: domaine}."""
    chemin = os.path.join(ICI, "..", "CultureFight.swiftpm", "Moteur", "Catalogue.swift")
    with open(chemin, encoding="utf-8") as fh:
        texte = fh.read()
    specialites = {m.group(1): m.group(2) for m in re.finditer(
        r'static let (\w+) = Specialite\(id: "[^"]+", nom: "[^"]*",\s*famille: "[^"]*", domaine: "([^"]+)"\)', texte)}
    debuts = list(re.finditer(r'id: "([a-z0-9-]+)", nom: "[^"]*", style:', texte))
    domaines = {}
    for i, m in enumerate(debuts):
        bloc = texte[m.end():debuts[i + 1].start() if i + 1 < len(debuts) else len(texte)]
        d = re.search(r'domaine: "([^"]+)"', bloc)
        s = re.search(r'specialite: (?:Self\.|Catalogue\.)?(\w+)', bloc)
        if d:
            domaines[m.group(1)] = d.group(1)
        elif s and s.group(1) in specialites:
            domaines[m.group(1)] = specialites[s.group(1)]
        else:
            erreur("histoires", f"domaine du combattant « {m.group(1)} » introuvable dans Catalogue.swift")
    return domaines


A_PLACER = "lancer python3 outils/placer_carte.py"


def dans_la_carte(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 1


def verifier_positions_pays(p, ou):
    """Position du pays et de ses lieux sur la carte de Culturia (tâche 55)."""
    if not all(dans_la_carte(p.get(c)) for c in ("x", "y", "rayon")) or not p.get("rayon"):
        erreur("monde", f"{ou} : position x, y, rayon absente ou hors de la carte ({A_PLACER})")
        return
    for l in p.get("lieux", []):
        if not (dans_la_carte(l.get("x")) and dans_la_carte(l.get("y"))):
            erreur("monde", f"{ou} : lieu « {l.get('nom')} » pas placé sur la carte ({A_PLACER})")
        elif ((l["x"] - p["x"]) ** 2 + (l["y"] - p["y"]) ** 2) ** 0.5 > 0.8 * p["rayon"]:
            erreur("monde", f"{ou} : lieu « {l.get('nom')} » placé hors du pays ({A_PLACER})")


def verifier_carte(monde):
    """L'Agora au centre, et des pays qui ne se chevauchent pas."""
    agora = monde.get("agora", {})
    if not (dans_la_carte(agora.get("x")) and dans_la_carte(agora.get("y"))):
        erreur("monde", f"l'Agora n'est pas placée sur la carte ({A_PLACER})")
    places = [p for p in monde.get("pays", []) if all(dans_la_carte(p.get(c)) for c in ("x", "y", "rayon"))]
    for i, a in enumerate(places):
        for b in places[i + 1:]:
            if ((a["x"] - b["x"]) ** 2 + (a["y"] - b["y"]) ** 2) ** 0.5 < a["rayon"] + b["rayon"]:
                erreur("monde", f"les pays « {a['id']} » et « {b['id']} » se chevauchent sur la carte ({A_PLACER})")


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
        verifier_positions_pays(p, ou)
    doublons("monde", "identifiant de pays", [p.get("id") for p in monde.get("pays", [])])
    doublons("monde", "domaine", [p.get("domaine") for p in monde.get("pays", [])])
    verifier_carte(monde)
    pays_du_domaine = {p.get("domaine"): p.get("id") for p in monde.get("pays", [])}
    domaines = domaines_du_catalogue()

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
        domaine = domaines.get(h.get("id"))
        if domaine is not None and pays_du_domaine.get(domaine) != h.get("pays"):
            erreur("histoires", f"{ou} : vient de « {h.get('pays')} », mais son domaine « {domaine} » "
                                f"est celui de « {pays_du_domaine.get(domaine)} » sur la carte")
        for lien in h.get("liens", []):
            if lien not in ids or lien == h.get("id"):
                erreur("histoires", f"{ou} : lien vers « {lien} » invalide")
        if len(h.get("histoire", "")) > 420:
            erreur("histoires", f"{ou} : plus de 420 caractères, trop long pour la fiche")
    for manquant in sorted(set(ids) - {h.get("id") for h in histoires}):
        erreur("histoires", f"« {manquant} » n'a pas d'histoire")
    return len(monde.get("pays", [])), len(histoires), len(ids)


def verifier_accroches():
    """Accroche (une ligne) et 1 ou 2 blagues pour chaque combattant du catalogue."""
    accroches = charger("accroches.json")
    ids = ids_du_catalogue()
    doublons("accroches", "accroche du combattant", [a.get("id") for a in accroches])
    for a in accroches:
        ou = f"accroche de « {a.get('id', '?')} »"
        champs("accroches", ou, a, {"id": str, "accroche": str, "blagues": list})
        if a.get("id") not in ids:
            erreur("accroches", f"{ou} : combattant absent du catalogue")
        if not 10 <= len(a.get("accroche", "")) <= 80:
            erreur("accroches", f"{ou} : l'accroche doit faire de 10 à 80 caractères (une ligne)")
        blagues = a.get("blagues", [])
        if not 1 <= len(blagues) <= 2:
            erreur("accroches", f"{ou} : il faut 1 ou 2 blagues")
        for b in blagues:
            if not isinstance(b, str) or not 15 <= len(b) <= 180:
                erreur("accroches", f"{ou} : chaque blague doit faire de 15 à 180 caractères")
    for manquant in sorted(set(ids) - {a.get("id") for a in accroches}):
        erreur("accroches", f"« {manquant} » n'a pas d'accroche")
    return len(accroches)


def verifier_profils():
    """Note de chaque combattant et stats de base par rareté (outils/simulation.py)."""
    profils = charger("profils.json")
    champs("profils", "profils", profils, {"methode": str, "profils": dict, "stats": dict, "notes": dict})
    notes_valides = {"Facile", "Moyenne", "Pointue"}
    ids = ids_du_catalogue()
    for i, note in profils.get("notes", {}).items():
        if i not in ids:
            erreur("profils", f"note de « {i} » : combattant absent du catalogue")
        if note not in notes_valides:
            erreur("profils", f"note de « {i} » : « {note} » n'est pas Facile, Moyenne ou Pointue")
    for manquant in sorted(set(ids) - set(profils.get("notes", {}))):
        erreur("profils", f"« {manquant} » n'a pas de note de difficulté")
    for rarete, table in profils.get("stats", {}).items():
        if set(table) != notes_valides:
            erreur("profils", f"{rarete} : il faut les stats des trois notes")
        for note, s in table.items():
            champs("profils", f"{rarete} {note}", s, {"pv": int, "attaque": int, "defense": int, "victoires": int})
            # Budget égal à rareté égale : chaque profil gagne autour de 50 % contre l'Équilibré.
            if not 45 <= s.get("victoires", 0) <= 55:
                erreur("profils", f"{rarete} {note} : {s.get('victoires')} % de victoires simulées, hors de 45 à 55 %")
        if table.get("Facile", {}).get("pv", 0) <= table.get("Moyenne", {}).get("pv", 0) \
                or table.get("Pointue", {}).get("pv", 0) >= table.get("Moyenne", {}).get("pv", 0):
            erreur("profils", f"{rarete} : le Tank doit avoir plus de PV que l'Équilibré, le Canon de verre moins")
    return len(profils.get("notes", {}))


if __name__ == "__main__":
    n_elements = verifier_elements()
    n_pays = verifier_pays()
    fiches, n_questions = verifier_fiches()
    verifier_sources(["elements", "pays-afrique"] + [f["id"] for f in fiches])
    verifier_sources_json()
    n_pays_monde, n_histoires, n_combattants = verifier_monde_et_histoires()
    n_accroches = verifier_accroches()
    n_notes = verifier_profils()
    print(f"elements.json      {n_elements} éléments")
    print(f"pays_afrique.json  {n_pays} pays")
    print(f"fiches.json        {len(fiches)} fiches, {n_questions} questions")
    print(f"{2 + len(fiches)} jeux de données, {len(SOURCES)} avec sources")
    print(f"monde.json         {n_pays_monde} pays ; histoires.json {n_histoires} histoires pour {n_combattants} combattants")
    print(f"accroches.json     {n_accroches} accroches")
    print(f"profils.json       {n_notes} notes de difficulté")
    if erreurs:
        for e in erreurs:
            print("ERREUR", e)
        print(f"{len(erreurs)} erreur(s)")
        sys.exit(1)
    print("Aucune erreur.")
