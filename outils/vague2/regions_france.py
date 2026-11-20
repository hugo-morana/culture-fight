"""Fiche « Régions françaises » (Région-Air)."""
from ajouts_vivant import q, rel
from vague2.departements import DEPTS

# Pages réellement consultées le 20/11/2026
RG = "https://en.wikipedia.org/wiki/Regions_of_France"
WK = "https://www.weka.fr/actualite/?p=3294"
BT = "https://www.banquedesterritoires.fr/les-nouvelles-regions-ont-choisi-leur-siege-et-les-lieux-de-reunion-des-elus"
VP = "https://www.vie-publique.fr/eclairage/38658-reforme-territoriale-une-nouvelle-carte-des-regions"
NO = "https://wikiwand.com/fr/Normandie_(r%C3%A9gion_administrative)"
W = "https://areq.net/lang/fr/Liste_des_d%C3%A9partements_fran%C3%A7ais.html"   # copie de Wikipédia

SOURCES_GENERALES = [
    ("Regions of France (Wikipédia en anglais)", RG),
    ("Le nom des nouvelles grandes régions officialisé (Weka, 2016)", WK),
    ("Les nouvelles régions ont choisi leur siège (Banque des Territoires, 2016)", BT),
    ("Réforme territoriale : une nouvelle carte des régions (Vie publique)", VP),
    ("Liste des départements français et de leurs régions (copie de Wikipédia)", W),
]

CHEFS_LIEUX = [
    ("Auvergne-Rhône-Alpes", "Lyon", "Fusion de l'Auvergne et de Rhône-Alpes ; environ 69 700 km².", RG),
    ("Bourgogne-Franche-Comté", "Dijon", "L'hôtel de région, siège du conseil régional, est à Besançon.", BT),
    ("Bretagne", "Rennes", "La Bretagne fait partie des régions inchangées par la réforme de 2016.", RG),
    ("Centre-Val de Loire", "Orléans", "Simple région Centre auparavant, elle a changé de nom sans changer de limites.", VP),
    ("Corse", "Ajaccio", "Collectivité unique, elle exerce à la fois les fonctions de région et de département.", RG),
    ("Grand Est", "Strasbourg", "Les séances plénières du conseil régional se tiennent à Metz.", BT),
    ("Hauts-de-France", "Lille", "Le conseil régional se réunit en séance plénière à Amiens.", BT),
    ("Île-de-France", "Paris", "C'est la région la plus peuplée de France.", RG),
    ("Normandie", "Rouen", "Rouen accueille la préfecture, mais l'hôtel de région est à Caen.", NO),
    ("Nouvelle-Aquitaine", "Bordeaux", "C'est la plus vaste région de France, avec environ 84 000 km².", RG),
    ("Occitanie", "Toulouse", "Les assemblées plénières se tiennent dans l'aire urbaine de Montpellier.", BT),
    ("Pays de la Loire", "Nantes", "Région inchangée par la réforme de 2016, elle compte cinq départements dont la Vendée.", W),
    ("Provence-Alpes-Côte d'Azur", "Marseille", "Elle n'a pas été fusionnée en 2016 ; elle couvre environ 31 400 km².", RG),
    ("Guadeloupe", "Basse-Terre", "Basse-Terre est aussi la préfecture du département de la Guadeloupe, numéro 971.", W),
    ("Guyane", "Cayenne", "Collectivité unique, presque aussi vaste que la Nouvelle-Aquitaine : environ 83 500 km².", RG),
    ("La Réunion", "Saint-Denis", "Saint-Denis est aussi la préfecture du département de La Réunion, numéro 974.", W),
    ("Martinique", "Fort-de-France", "Collectivité unique qui réunit les fonctions de région et de département.", RG),
    ("Mayotte", "Mamoudzou", "C'est la plus petite et la moins peuplée des régions françaises.", RG),
]

ANCIENNES = [
    ("Alsace", "Grand Est", "Fusionnée avec la Champagne-Ardenne et la Lorraine ; chef-lieu Strasbourg.", WK),
    ("Champagne-Ardenne", "Grand Est", "Châlons-en-Champagne accueille la commission des finances du Grand Est.", BT),
    ("Lorraine", "Grand Est", "Metz, en Lorraine, accueille les séances plénières du Grand Est.", BT),
    ("Aquitaine", "Nouvelle-Aquitaine", "Fusionnée avec le Limousin et le Poitou-Charentes ; chef-lieu Bordeaux.", WK),
    ("Limousin", "Nouvelle-Aquitaine", "Limoges peut accueillir la commission permanente de la nouvelle région.", BT),
    ("Poitou-Charentes", "Nouvelle-Aquitaine", "Poitiers peut accueillir la commission permanente de la nouvelle région.", BT),
    ("Auvergne", "Auvergne-Rhône-Alpes", "Clermont-Ferrand n'accueille que des commissions permanentes ; Lyon l'a emporté.", BT),
    ("Rhône-Alpes", "Auvergne-Rhône-Alpes", "Fusionnée avec l'Auvergne ; chef-lieu Lyon.", WK),
    ("Bourgogne", "Bourgogne-Franche-Comté", "Dijon, en Bourgogne, accueille l'assemblée régionale.", BT),
    ("Franche-Comté", "Bourgogne-Franche-Comté", "Besançon, en Franche-Comté, accueille l'hôtel de région.", BT),
    ("Languedoc-Roussillon", "Occitanie", "Montpellier, en Languedoc, accueille les commissions permanentes de l'Occitanie.", BT),
    ("Midi-Pyrénées", "Occitanie", "Fusionnée avec le Languedoc-Roussillon ; chef-lieu Toulouse.", WK),
    ("Nord-Pas-de-Calais", "Hauts-de-France", "Fusionnée avec la Picardie ; chef-lieu Lille.", WK),
    ("Picardie", "Hauts-de-France", "Amiens, en Picardie, accueille les séances plénières de la région.", BT),
    ("Haute-Normandie", "Normandie", "Rouen, en Haute-Normandie, est le chef-lieu de la région réunifiée.", NO),
    ("Basse-Normandie", "Normandie", "Caen, en Basse-Normandie, accueille l'hôtel de région.", NO),
]

CHOISIS = ["Ain", "Aisne", "Allier", "Ardennes", "Aveyron", "Calvados", "Cher", "Corrèze", "Côte-d'Or",
           "Creuse", "Dordogne", "Doubs", "Essonne", "Finistère", "Gers", "Hautes-Alpes", "Indre", "Isère",
           "Jura", "Landes", "Loire-Atlantique", "Lozère", "Manche", "Meuse", "Nièvre", "Oise", "Puy-de-Dôme",
           "Sarthe", "Somme", "Var", "Vaucluse", "Vendée", "Vosges", "Yonne", "Mayenne", "Eure-et-Loir"]
DEPT_REGION = [(nom, region, f"Département n° {code}, de préfecture {pref}.", W)
               for code, nom, pref, region in DEPTS if nom in CHOISIS]

FICHE = {"id": "regions-france", "relations": [
    rel("Quelle ville est le chef-lieu de la région {x} ?", "Le chef-lieu de la région {x} est {y}.",
        CHEFS_LIEUX, inverse="De quelle région cette ville est-elle le chef-lieu : {y} ?"),
    rel("Dans quelle région actuelle l'ancienne région {x} a-t-elle été fusionnée ?",
        "Depuis 2016, l'ancienne région {x} fait partie de la région {y}.", ANCIENNES),
    rel("À quelle région appartient ce département : {x} ?", "Le département {x} fait partie de la région {y}.",
        DEPT_REGION),
], "questions": [
    q("Combien de régions la France compte-t-elle depuis 2016, outre-mer compris ?", "18",
      ["13", "22", "27"], "Treize régions en métropole et cinq en outre-mer.", source=RG),
    q("Combien de régions la France métropolitaine compte-t-elle depuis 2016 ?", "13",
      ["12", "18", "22"], "La Corse est comptée parmi ces treize régions métropolitaines.", source=RG),
    q("Combien de régions la France métropolitaine comptait-elle juste avant la réforme de 2016 ?", "22",
      ["13", "18", "30"], "Ce découpage en 22 régions a duré de 1982 à 2015.", source=RG),
    q("Quand la nouvelle carte des régions est-elle entrée en vigueur ?", "Le 1er janvier 2016",
      ["Le 1er janvier 2014", "Le 14 juillet 2015", "Le 1er janvier 2020"],
      "La loi qui a réduit les régions métropolitaines de 22 à 13 date de 2014.", source=RG),
    q("Quelle loi de 1982 a fait des régions des collectivités à part entière ?", "La loi de décentralisation",
      ["La loi NOTRe", "La loi Pasqua", "La loi sur la laïcité"],
      "Elle date du 2 mars 1982 ; elle a aussi créé le terme de « région » au sens actuel.", source=RG),
    q("En quelle année les Français ont-ils élu leurs conseils régionaux pour la première fois ?", "1986",
      ["1958", "1972", "2004"], "Ces premières élections régionales au suffrage direct ont eu lieu le 16 mars 1986.", source=RG),
    q("Quelle est la plus vaste région de France ?", "La Nouvelle-Aquitaine",
      ["L'Occitanie", "La Guyane", "Auvergne-Rhône-Alpes"],
      "Avec environ 84 000 km², elle devance de peu la Guyane.", source=RG),
    q("Quelle est la plus petite région de France ?", "Mayotte",
      ["La Martinique", "La Guadeloupe", "La Corse"], "Elle couvre environ 374 km², et c'est aussi la moins peuplée.", source=RG),
    q("Quelle est la région la plus peuplée de France ?", "L'Île-de-France",
      ["Auvergne-Rhône-Alpes", "Les Hauts-de-France", "La Nouvelle-Aquitaine"],
      "Son chef-lieu, Paris, est aussi la capitale du pays.", source=RG),
    q("Laquelle de ces régions n'est pas une collectivité unique ?", "La Réunion",
      ["La Guyane", "La Martinique", "La Corse"],
      "Les collectivités uniques exercent à la fois les compétences de la région et du département.", source=RG),
    q("Combien d'anciennes régions ont fusionné pour former le Grand Est ?", "Trois",
      ["Deux", "Quatre", "Cinq"], "L'Alsace, la Champagne-Ardenne et la Lorraine.", source=WK),
    q("Laquelle de ces régions n'a pas été modifiée par la réforme de 2016 ?", "La Bretagne",
      ["La Normandie", "L'Occitanie", "Les Hauts-de-France"],
      "Bretagne, Île-de-France, Pays de la Loire et Provence-Alpes-Côte d'Azur sont restées inchangées.", source=VP),
    q("Quelle région a seulement changé de nom en 2016, sans changer de limites ?", "Le Centre, devenu Centre-Val de Loire",
      ["La Bretagne, devenue Grande Bretagne", "La Picardie, devenue Somme", "Le Midi, devenu Occitanie"],
      "Son chef-lieu reste Orléans.", source=VP),
    q("Dans quelle ville siège l'hôtel de région de Normandie ?", "Caen",
      ["Rouen", "Le Havre", "Cherbourg"], "Rouen garde la préfecture de région, Caen le conseil régional.", source=BT),
    q("Dans quelle ville siège l'hôtel de région de Bourgogne-Franche-Comté ?", "Besançon",
      ["Dijon", "Belfort", "Auxerre"], "Dijon, chef-lieu, accueille l'assemblée et les commissions.", source=BT),
    q("Dans quelle ville se réunissent les séances plénières du conseil régional du Grand Est ?", "Metz",
      ["Strasbourg", "Nancy", "Reims"], "La commission des finances, elle, se réunit à Châlons-en-Champagne.", source=BT),
    q("Quelle est la commune la plus peuplée de la région Normandie ?", "Le Havre",
      ["Rouen", "Caen", "Cherbourg-en-Cotentin"], "Le chef-lieu régional est pourtant Rouen.", source=NO),
    q("Quelle part de la production mondiale de flacons de luxe vient de Normandie ?", "Environ 75 %",
      ["Environ 10 %", "Environ 30 %", "Environ 95 %"],
      "La Normandie est le premier pôle mondial du flaconnage de luxe.", source=NO),
    q("En quelle année les noms Grand Est, Occitanie ou Hauts-de-France ont-ils été officialisés ?", "2016",
      ["2012", "2014", "2019"], "Sept décrets ont été publiés au Journal officiel le 29 septembre 2016.", source=WK),
    q("Combien de départements compte la région Normandie ?", "Cinq",
      ["Trois", "Quatre", "Huit"], "Calvados, Eure, Manche, Orne et Seine-Maritime.", source=NO),
    q("Combien de régions d'outre-mer la France compte-t-elle ?", "Cinq",
      ["Trois", "Quatre", "Huit"], "Mayotte est devenue la cinquième en 2011.", source=RG),
]}
