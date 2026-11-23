#!/usr/bin/env python3
"""Simulation de la répartition des stats par style (game design, « Stats selon le style et la spécialité »).

Le budget de stats dépend de la rareté et de la note de la spécialité (Facile, Moyenne, Pointue) ;
la famille de styles le répartit entre Attaque, Défense et PV (Haute +20 %, Moyenne, Basse −20 %).
Combats 3 contre 3 selon les règles de Combat.swift : seul l'attaquant fait mal (une bonne réponse
est une esquive totale), jauge d'Inspiration, effets de vitesse des familles (dont la Riposte et le Contre des Arts martiaux), bonus des Chevaliers (bouclier après un K.O.) et des Créatures
(secondes retirées sur leur première question), synergie, questionneur qui répond aussi (±20 %).
Hypothèses : l'adversaire répond juste à 80 % (Facile), 65 % (Moyenne) ou 50 % (Pointue) en difficulté 1,
8 points de moins par niveau ; difficulté tirée de 1 à 3 ; le questionneur connaît sa propre question
15 points mieux que le défenseur.

Usage : python3 outils/simulation.py  (lit et vérifie Resources/profils.json, ~10 min)
"""
import json, math, os, random

ICI = os.path.dirname(os.path.abspath(__file__))
PROFILS = os.path.join(ICI, "..", "CultureFight.swiftpm", "Resources", "profils.json")
REUSSITE = {"Facile": 0.80, "Moyenne": 0.65, "Pointue": 0.50}
EFFET = {"Guerriers lourds": "riposte", "Arts martiaux": "contre", "Tireurs": "riposte", "Créatures": "soin",
         "Morts-vivants": "soin", "Chevaliers": "bouclier", "Soldats": "bouclier", "Mages": "savoir",
         "Ombres": "pression", "Bretteurs": "pression"}
FAMILLES = list(EFFET)
NIVEAU = {"Haute": 1, "Moyenne": 0, "Basse": -1}


def arrondi(x):
    return math.floor(x + 0.5)


def stats(p, famille, rarete, note):
    """Stats de base d'un combattant : même calcul que ProfilStats.swift."""
    budget = p["budgets"][rarete][note]
    prix, parts, ecart = p["prix"], p["parts"], p["ecart"]
    att_n, def_n, pv_n = (NIVEAU[x] for x in p["repartition"][famille])
    niveaux = {"attaque": att_n, "defense": def_n, "pv": pv_n}
    ref = {k: budget * parts[k] / prix[k] for k in parts}
    poids = {k: parts[k] * (1 + ecart * niveaux[k]) for k in parts}
    total = sum(poids.values())
    brut = {k: budget * poids[k] / total / prix[k] for k in parts}
    borne = lambda k, v: min(ref[k] * (1 + ecart), max(ref[k] * (1 - ecart), v))
    attaque = borne("attaque", brut["attaque"])
    defense = min(p["plafondDefense"], borne("defense", brut["defense"]))
    pv = borne("pv", budget - prix["attaque"] * attaque - prix["defense"] * defense)
    return {"pv": arrondi(pv), "attaque": arrondi(attaque), "defense": arrondi(defense)}


def degats(a, d, diff):
    return max(5, round(a * (1 + 0.1 * (diff - 1))) - d)


def vitesse(malus):
    r = random.random()
    if malus >= 4: return "rapide" if r < 0.45 else "normale"
    if malus >= 2: return "eclair" if r < 0.12 else ("rapide" if r < 0.5 else "normale")
    return "eclair" if r < 0.25 else ("rapide" if r < 0.65 else "normale")


def combat(A, B, p):
    K, chev, crea, bq = p["synergie"], p["bouclierChevaliers"], p["secondesCreatures"], 0.2
    camps = [[dict(c, pvmax=c["pv"], j=0, cap=False, bou=0, abs=0, posee=False, rip=1) for c in X] for X in (A, B)]
    syn = [X[0]["fam"] if all(c["fam"] == X[0]["fam"] for c in X) else None for X in (A, B)]
    act, malus, prem, n = [0, 0], [0, 0], random.randint(0, 1), 3
    tours = 0
    for t in range(30):
        tours += 1
        a = (t + prem) % 2; d = 1 - a
        at, de = camps[a][act[a]], camps[d][act[d]]
        ka = K if syn[a] == at["fam"] else 1
        kd = K if syn[d] == de["fam"] else 1
        diff = random.randint(1, 3)
        m = malus[d]; malus[d] = 0
        if at["fam"] == "Créatures" and not at["posee"]:
            m += crea * ka
        at["posee"] = True
        reussite = REUSSITE[at["note"]] - 0.08 * (diff - 1) - 0.0125 * m
        q = min(0.95, REUSSITE[at["note"]] + 0.15 - 0.08 * (diff - 1))
        fq = 1 + bq if random.random() < q else 1 - bq
        riposte = at["rip"]; at["rip"] = 1  # la Riposte se dépense à la prochaine question posée
        if random.random() < reussite:
            # Bonne réponse : esquive totale, personne ne perd de PV (« seul l'attaquant fait mal »).
            v = vitesse(m); cases = 0
            if v != "normale":
                e = v == "eclair"; eff = EFFET[de["fam"]]
                if eff == "riposte": de["rip"] = max(de["rip"], 1 + p["riposte"][0 if e else 1] * kd)
                elif eff == "contre":
                    # Contre des Arts martiaux : coup immédiat sur le questionneur (25 % ou 12 % d'une attaque,
                    # +20 % de bonus de famille). Sans synergie et sans K.O. (il laisse au moins 1 PV) : avec,
                    # une équipe de 3 Arts martiaux gagnait 57 à 63 % (simulation du 23/11).
                    part = p["contre"][0 if e else 1] * (1 + p["bonusFamilleContre"])
                    y = max(1, round(degats(de["attaque"], at["defense"], diff) * part))
                    if at["abs"] > 0: z = min(at["abs"], y); at["abs"] -= z; y -= z
                    at["pv"] = max(min(at["pv"], 1), at["pv"] - y)
                elif eff == "soin": de["pv"] = min(de["pvmax"], de["pv"] + round((15 if e else 8) * kd))
                elif eff == "bouclier": de["bou"] = max(de["bou"], p.get("bouclierVitesse", [0.3, 0.15])[0 if e else 1] * kd)
                elif eff == "savoir": cases = int((2 if e else 1) * kd)  # arrondi vers le bas
                elif eff == "pression": malus[a] = (4 if e else 2) * kd
            de["j"] += 1 + cases
            if de["j"] >= 3: de["j"] = 0; de["cap"] = True
        else:
            x = degats(at["attaque"], de["defense"], diff)
            if at["cap"]: x *= 2; at["cap"] = False
            x = max(5, round(x * fq * riposte))
            if de["bou"] > 0: x -= round(x * de["bou"]); de["bou"] = 0
            if de["abs"] > 0: y = min(de["abs"], x); de["abs"] -= y; x -= y
            de["pv"] -= x
        for c in (0, 1):
            avant = act[c]
            while act[c] < n and camps[c][act[c]]["pv"] <= 0: act[c] += 1
            if act[c] != avant and act[c] < n and camps[c][act[c]]["fam"] == "Chevaliers":
                camps[c][act[c]]["abs"] += round(chev * (K if syn[c] == "Chevaliers" else 1))
        if n in act: break
    if act[1] >= n > act[0]: return 1, tours
    if act[0] >= n > act[1]: return 0, tours
    s = [sum(max(0, x["pv"]) for x in camps[c]) for c in (0, 1)]
    return (1 if s[0] > s[1] else 0 if s[0] < s[1] else 0.5), tours


def combattant(p, famille, rarete, note):
    return dict(stats(p, famille, rarete, note), fam=famille, note=note)


def equipe(p, rarete, note="Moyenne", famille=None, seule=False):
    if seule:
        return [combattant(p, famille, rarete, note) for _ in range(3)]
    premiers = [famille] if famille else []
    return [combattant(p, f, rarete, note) for f in premiers + [random.choice(FAMILLES) for _ in range(3 - len(premiers))]]


def mesurer(p, rarete, N=4000):
    """Taux de victoire de chaque famille (dans une équipe variée, puis à 3) et de chaque note."""
    familles = {}
    for f in FAMILLES:
        variee = sum(combat(equipe(p, rarete, famille=f), equipe(p, rarete), p)[0] for _ in range(N)) / N
        seule = sum(combat(equipe(p, rarete, famille=f, seule=True), equipe(p, rarete), p)[0] for _ in range(N)) / N
        familles[f] = (variee, seule)
    notes = {nt: sum(combat(equipe(p, rarete, nt), equipe(p, rarete), p)[0] for _ in range(N)) / N
             for nt in ("Facile", "Pointue")}
    tours = [combat(equipe(p, rarete), equipe(p, rarete), p)[1] for _ in range(N)]
    return familles, notes, sum(tours) / len(tours)


if __name__ == "__main__":
    p = json.load(open(PROFILS, encoding="utf-8"))
    for rarete in p["budgets"]:
        familles, notes, tours = mesurer(p, rarete)
        print(f"{rarete} : combats de {tours:.1f} tours en moyenne")
        for f, (v, s) in familles.items():
            print(f"  {f:17} {stats(p, f, rarete, 'Moyenne')}  variée {v:.1%}  seule {s:.1%}")
        for nt, v in notes.items():
            print(f"  équipe {nt} contre équipe Moyenne : {v:.1%}")
