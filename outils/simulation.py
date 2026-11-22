#!/usr/bin/env python3
"""Simulation des profils de stats (Tank, Équilibré, Canon de verre).

Combats 3 contre 3 selon les règles de Combat.swift (dégâts, contre-attaque à 50 %, jauge de Savoir,
camp qui ouvre tiré au sort, 30 tours au plus). Hypothèse : l'adversaire répond juste à 80 % (Facile),
65 % (Moyenne) ou 50 % (Pointue) en difficulté 1, 8 points de moins par niveau ; difficulté tirée de 1 à 3.
Usage : python3 outils/simulation.py  → taux de victoire de chaque profil de Resources/profils.json.
"""
import json, os, random

ICI = os.path.dirname(os.path.abspath(__file__))
REUSSITE = {"Facile": 0.80, "Moyenne": 0.65, "Pointue": 0.50}


def degats(att, defense, diff):
    return max(5, round(att * (1 + 0.1 * (diff - 1))) - defense)


def combat(A, B, n=3):
    camps = [[dict(A, j=0, cap=False) for _ in range(n)], [dict(B, j=0, cap=False) for _ in range(n)]]
    actif, premier = [0, 0], random.randint(0, 1)
    for t in range(30):
        a = (t + premier) % 2; d = 1 - a
        at, df = camps[a][actif[a]], camps[d][actif[d]]
        diff = random.randint(1, 3)
        if random.random() < REUSSITE[at["note"]] - 0.08 * (diff - 1):
            at["pv"] -= max(5, round(degats(df["attaque"], at["defense"], diff) * 0.5))
            df["j"] += 1
            if df["j"] >= 3:
                df["j"], df["cap"] = 0, True
        else:
            x = degats(at["attaque"], df["defense"], diff)
            if at["cap"]:
                x, at["cap"] = x * 2, False
            df["pv"] -= x
        for c in (0, 1):
            while actif[c] < n and camps[c][actif[c]]["pv"] <= 0:
                actif[c] += 1
        if n in actif:
            break
    if actif[1] >= n > actif[0]: return 1
    if actif[0] >= n > actif[1]: return 0
    s = [sum(max(0, x["pv"]) for x in camps[c]) for c in (0, 1)]
    return 1 if s[0] > s[1] else 0 if s[0] < s[1] else 0.5


def taux(A, B, n=20000):
    return sum(combat(A, B) for _ in range(n)) / n


if __name__ == "__main__":
    profils = json.load(open(os.path.join(ICI, "..", "CultureFight.swiftpm", "Resources", "profils.json")))
    for rarete, table in profils["stats"].items():
        stats = {note: dict(pv=s["pv"], attaque=s["attaque"], defense=s["defense"], note=note) for note, s in table.items()}
        ref = stats["Moyenne"]
        for note in ("Facile", "Pointue"):
            print(f"{rarete:8} {profils['profils'][note]:15} contre Équilibré : {taux(stats[note], ref):.1%}")
        print(f"{rarete:8} Tank contre Canon de verre : {taux(stats['Facile'], stats['Pointue']):.1%}")
