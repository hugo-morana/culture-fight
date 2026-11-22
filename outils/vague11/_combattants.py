"""Les 6 combattants de la vague 11 (Univers n° 3 à 8, fin du Système solaire).

Ajoutés au catalogue quand leurs 6 fiches sont prêtes : python3 outils/vague11/_integrer.py.
Même format que outils/vague10/_combattants.py ; « rare » : True pour un combattant Rare (110 PV, 54 Att, 4 Déf).
"""

PLANETES = ("astralis", "La Ronde des Planètes")


def c(id, nom, style, familleStyle, specialite, famille, fiche, lieu, apparence, questions, histoire, liens,
      rare=False, domaine="Univers"):
    return dict(id=id, nom=nom, style=style, familleStyle=familleStyle, rare=rare,
                specialite=specialite, famille=famille, domaine=domaine,
                fiche=fiche, generateur=None, difficulte=2, pays=lieu[0], lieu=lieu[1],
                apparence=apparence, questions=questions, histoire=histoire, liens=liens)


SYS = "Système solaire"

COMBATTANTS = [
    c("mercurion", "Mercurion", "Centurion", "soldats", "Mercure", SYS, "mercure", PLANETES,
      "Centurion au casque à cimier rouge et à l'armure criblée de cratères comme le sol de Mercure, caducée ailé à la main, devant un Soleil énorme qui se lève.",
      "Mercure : orbite, rotation, températures, glace aux pôles, bassin Caloris, transits et missions.",
      "Premier de la file dans la Ronde des Planètes, à Orbitopolis, Mercurion monte la garde au plus près du soleil de bronze, sans aucune lune pour le seconder. Il rappelle qu'une journée sur Mercure dure plus longtemps que son année. Sol-Dat le trouve trop collant ; Vénus de Mille-Lames le dépasse en chaleur, et il ne s'en remet pas.",
      ["sol-dat", "venus-de-mille-lames"]),
    c("venus-de-mille-lames", "Vénus de Mille-Lames", "Bretteuse", "bretteurs", "Vénus", SYS, "venus", PLANETES,
      "Bretteuse aux boucles dorées couronnées de laurier, en armure nacrée et voiles crème, qui croise deux sabres devant le disque laiteux de Vénus.",
      "Vénus : atmosphère, effet de serre, rotation rétrograde, phases, transits et missions Venera, Magellan et Venus Express.",
      "Bretteuse vedette de la Ronde des Planètes, à Orbitopolis, Vénus de Mille-Lames enchaîne les passes dans un nuage étouffant de gaz carbonique. Elle sait que Vénus, plus chaude que Mercure, tourne à l'envers : chez elle, le soleil se lève à l'ouest. Mercurion lui dispute le titre de planète la plus brûlante ; Marshal Martien lui envoie des fleurs rouges.",
      ["mercurion", "marshal-martien"], rare=True),
    c("gladiaterre", "Gladiaterre", "Gladiateur", "guerriersLourds", "La Terre", SYS, "terre", PLANETES,
      "Gladiateur barbu couronné de laurier, cape verte sur l'épaule, qui porte un bouclier rond à l'image de la Terre bordé de lauriers dorés, devant la planète bleue.",
      "La Terre, planète : forme, structure interne, champ magnétique, atmosphère, âge, mouvements et records.",
      "Gladiateur de la Ronde des Planètes, à Orbitopolis, Gladiaterre est le seul combattant de la Ronde à arroser ses plantes : c'est la seule planète connue où la vie existe. Il rappelle que la Terre est bleue parce que les océans couvrent l'essentiel de sa surface. Lunagarou ne le quitte jamais d'une orbite ; Marshal Martien l'accuse de garder toute l'eau liquide pour lui.",
      ["lunagarou", "marshal-martien"]),
    c("marshal-martien", "Marshal Martien", "Marshal", "tireurs", "Mars", SYS, "mars", PLANETES,
      "Marshal au chapeau de cow-boy étoilé et à la cape rouille, étoile de shérif sur la poitrine et cartouchières en bandoulière, revolver levé dans un désert rouge où roule un rover.",
      "Mars : Olympus Mons, Valles Marineris, calottes, eau passée, tempêtes, Phobos et Déimos, canaux et missions.",
      "Marshal de la Ronde des Planètes, à Orbitopolis, Marshal Martien fait régner l'ordre sur une planète rouge de rouille, car son sol est riche en oxyde de fer. Il se vante de veiller sur l'Olympus Mons, plus haut volcan connu du système solaire. Colonel Martien conteste son grade à chaque revue ; Rodéover laboure son désert sans jamais demander de permis.",
      ["colonel-martien", "rodeover"]),
    c("jupititan", "Jupititan", "Titan", "guerriersLourds", "Jupiter", SYS, "jupiter", PLANETES,
      "Titan colossal à la barbe blanche et couronné d'or, au corps de nuages rayés beige et orange, une Grande Tache rouge sur le ventre et une ceinture frappée du symbole de Jupiter.",
      "Jupiter : taille, bandes, Grande Tache rouge, champ magnétique, anneaux, impact de 1994 et missions.",
      "Plus grand résident de la Ronde des Planètes, à Orbitopolis, Jupititan occupe à lui seul plus de place que toutes les autres planètes réunies. Il connaît par cœur sa Grande Tache rouge, une tempête plus large que la Terre qui souffle depuis des siècles. Callistoréador agite ses lunes devant lui pour l'énerver ; Saturnchakram lui envie sa taille, mais pas ses manières.",
      ["callistoreador", "saturnchakram"]),
    c("saturnchakram", "Saturnchakram", "Guerrière au chakram", "tireurs", "Saturne", SYS, "saturne", PLANETES,
      "Guerrière au chignon noir et au diadème orné d'une gemme, cape violette étoilée au vent, qui lance un chakram doré tournoyant comme un anneau devant Saturne.",
      "Saturne : densité, anneaux et divisions, hexagone polaire, tempêtes, découverte des anneaux et Grand Final de Cassini.",
      "Guerrière de la Ronde des Planètes, à Orbitopolis, Saturnchakram lance ses anneaux plus vite que son ombre. Elle sait qu'ils sont faits de milliards de morceaux de glace et de poussière, et que Saturne est si peu dense qu'elle flotterait dans une baignoire géante. Jupititan voudrait bien lui emprunter un anneau ; Enceladin, sa protégée, lui offre des geysers glacés.",
      ["jupititan", "enceladin"], rare=True),
]

assert len(COMBATTANTS) == 6
assert all(len(x["histoire"]) <= 420 for x in COMBATTANTS), [(x["id"], len(x["histoire"])) for x in COMBATTANTS if len(x["histoire"]) > 420]
