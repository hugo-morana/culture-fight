"""Fiche « Préfectures » (Shérifecture)."""
from ajouts_vivant import q, rel
from vague2.departements import DEPTS

# Pages réellement consultées le 20/11/2026
W = "https://areq.net/lang/fr/Liste_des_d%C3%A9partements_fran%C3%A7ais.html"   # copie de Wikipédia
SP = "https://en.wikipedia.org/wiki/List_of_subprefectures_of_France"
PR = "https://ipfs.ssi.eecc.de/ipns/en.wikipedia-on-ipfs.org/wiki/Prefectures_in_France"
EN = "https://ipfs.ssi.eecc.de/ipns/en.wikipedia-on-ipfs.org/wiki/Departments_of_France"

SOURCES_GENERALES = [
    ("Liste des départements français et de leurs chefs-lieux (copie de Wikipédia)", W),
    ("List of subprefectures of France (Wikipédia en anglais)", SP),
    ("Prefectures in France (Wikipédia en anglais, copie IPFS)", PR),
]

SPECIAUX = {
    "Marne": ("Reims, quatre fois plus peuplée, n'est que sous-préfecture.", PR),
    "Val-d'Oise": ("Sa voisine Pontoise n'est qu'une sous-préfecture, comme Argenteuil et Sarcelles.", SP),
    "Mayotte": ("Mayotte est l'un des trois départements sans aucune sous-préfecture.", SP),
    "Territoire de Belfort": ("C'est l'un des trois départements sans aucune sous-préfecture, avec Paris et Mayotte.", SP),
    "Corse-du-Sud": ("Sartène est la seule sous-préfecture de la Corse-du-Sud.", SP),
    "Haute-Corse": ("Le département a deux sous-préfectures : Calvi et Corte.", SP),
    "Bouches-du-Rhône": ("Aix-en-Provence, Arles et Istres en sont les sous-préfectures.", SP),
    "Pas-de-Calais": ("Ni Calais ni Boulogne-sur-Mer : elles ne sont que sous-préfectures.", SP),
    "Nord": ("Dunkerque, Valenciennes, Douai et Cambrai en sont des sous-préfectures.", SP),
    "Finistère": ("Brest, la plus grande ville du département, n'en est qu'une sous-préfecture.", SP),
    "Seine-Maritime": ("Le Havre et Dieppe en sont les sous-préfectures.", SP),
    "Haut-Rhin": ("Mulhouse n'est que sous-préfecture, comme Altkirch et Thann.", SP),
    "Essonne": ("Étampes et Palaiseau en sont les sous-préfectures.", SP),
    "La Réunion": ("Une autre Saint-Denis est sous-préfecture de la Seine-Saint-Denis.", SP),
    "Seine-Saint-Denis": ("Saint-Denis et Le Raincy en sont les sous-préfectures.", SP),
    "Hérault": ("Béziers et Lodève en sont les sous-préfectures.", SP),
    "Pyrénées-Atlantiques": ("Bayonne et Oloron-Sainte-Marie en sont les sous-préfectures.", SP),
    "Yvelines": ("Saint-Germain-en-Laye, Rambouillet et Mantes-la-Jolie en sont les sous-préfectures.", SP),
    "Charente": ("Cognac et Confolens en sont les sous-préfectures.", SP),
}


def _contexte(code, nom, region):
    if nom in SPECIAUX:
        return SPECIAUX[nom]
    if nom == region:
        return (f"Département n° {code}, c'est aussi une région à lui seul.", W)
    return (f"Département n° {code}, en région {region}.", W)


# Paris est exclu : sa préfecture porte le même nom que le département.
PAIRES = [(nom, pref) + _contexte(code, nom, region) for code, nom, pref, region in DEPTS if nom != "Paris"]


def _sp(ville, dept):
    pref = next(d[2] for d in DEPTS if d[1] == dept)
    return (ville, dept, f"La préfecture du département est {pref}.", SP)


SOUS_PREF = [
    ("Reims", "Marne", "Quatre fois plus peuplée que Châlons-en-Champagne, la préfecture.", PR),
    _sp("Le Havre", "Seine-Maritime"), _sp("Brest", "Finistère"), _sp("Lorient", "Morbihan"),
    _sp("Cognac", "Charente"), _sp("Arles", "Bouches-du-Rhône"), _sp("Aix-en-Provence", "Bouches-du-Rhône"),
    _sp("Grasse", "Alpes-Maritimes"), _sp("Béziers", "Hérault"), _sp("Bayonne", "Pyrénées-Atlantiques"),
    _sp("Dunkerque", "Nord"), _sp("Valenciennes", "Nord"), _sp("Calais", "Pas-de-Calais"),
    _sp("Boulogne-sur-Mer", "Pas-de-Calais"), _sp("Mulhouse", "Haut-Rhin"), _sp("Vichy", "Allier"),
    _sp("Montluçon", "Allier"), _sp("Fontainebleau", "Seine-et-Marne"), _sp("Saint-Nazaire", "Loire-Atlantique"),
    _sp("Beaune", "Côte-d'Or"), _sp("Épernay", "Marne"), _sp("Saint-Germain-en-Laye", "Yvelines"),
    _sp("Sedan", "Ardennes"), _sp("Thionville", "Moselle"), _sp("Arcachon", "Gironde"),
    _sp("Libourne", "Gironde"), _sp("Chinon", "Indre-et-Loire"), _sp("Compiègne", "Oise"),
    _sp("Saint-Quentin", "Aisne"), _sp("Abbeville", "Somme"), _sp("Alès", "Gard"),
    ("Saint-Denis", "Seine-Saint-Denis", "Homonyme de Saint-Denis, préfecture de La Réunion ; ici, la préfecture est Bobigny.", SP),
    _sp("Rochefort", "Charente-Maritime"), _sp("Thonon-les-Bains", "Haute-Savoie"), _sp("Vienne", "Isère"),
    _sp("Corte", "Haute-Corse"), _sp("Sartène", "Corse-du-Sud"), _sp("Bayeux", "Calvados"),
    _sp("Lisieux", "Calvados"), _sp("Carpentras", "Vaucluse"), _sp("Vierzon", "Cher"),
]

FICHE = {"id": "prefectures", "relations": [
    rel("Quelle ville est la préfecture de ce département : {x} ?", "La préfecture du département {x} est {y}.",
        PAIRES, inverse="De quel département cette ville est-elle la préfecture : {y} ?"),
    rel("Dans quel département se trouve la sous-préfecture de {x} ?", "{x} est une sous-préfecture du département {y}.",
        SOUS_PREF),
], "questions": [
    q("Combien la France compte-t-elle de préfectures de département ?", "101",
      ["96", "100", "110"], "Une par département, outre-mer compris.", source=PR),
    q("Lequel de ces départements n'a aucune sous-préfecture ?", "Le Territoire de Belfort",
      ["L'Ain", "Le Cher", "Le Vaucluse"], "Paris et Mayotte n'en ont pas non plus.", source=SP),
    q("Quelle grande ville de la Marne n'est pourtant qu'une sous-préfecture ?", "Reims",
      ["Châlons-en-Champagne", "Troyes", "Charleville-Mézières"],
      "La préfecture, Châlons-en-Champagne, est environ quatre fois moins peuplée.", source=PR),
    q("Pourquoi les préfectures sont-elles souvent au centre de leur département ?",
      "Pour être à une journée de cheval de tout le département",
      ["Pour être loin des frontières", "Parce qu'elles étaient les plus grandes villes",
       "Pour être sur une rivière navigable"],
      "C'est pourquoi la préfecture n'est pas toujours la plus grande ville.", source=PR),
    q("Quelle préfecture est commune à Paris et aux trois départements de la petite couronne ?",
      "La préfecture de police", ["La préfecture de région", "La préfecture maritime", "La préfecture du Grand Paris"],
      "Elle gère l'ordre public de Paris, des Hauts-de-Seine, de la Seine-Saint-Denis et du Val-de-Marne.", source=PR),
    q("Laquelle de ces villes bretonnes n'est pas une préfecture ?", "Brest",
      ["Rennes", "Quimper", "Vannes"], "Brest est une sous-préfecture du Finistère, dont la préfecture est Quimper.", source=SP),
    q("Laquelle de ces villes normandes n'est pas une préfecture ?", "Le Havre",
      ["Rouen", "Caen", "Saint-Lô"], "Le Havre est une sous-préfecture de la Seine-Maritime.", source=SP),
    q("Laquelle de ces villes des Hauts-de-France n'est pas une préfecture ?", "Dunkerque",
      ["Lille", "Arras", "Amiens"], "Dunkerque est une sous-préfecture du Nord.", source=SP),
    q("Laquelle de ces villes d'Occitanie n'est pas une préfecture ?", "Béziers",
      ["Montpellier", "Nîmes", "Perpignan"], "Béziers est une sous-préfecture de l'Hérault.", source=SP),
    q("Laquelle de ces villes de Provence n'est pas une préfecture ?", "Arles",
      ["Marseille", "Avignon", "Toulon"], "Arles est une sous-préfecture des Bouches-du-Rhône.", source=SP),
    q("Laquelle de ces villes du Grand Est n'est pas une préfecture ?", "Mulhouse",
      ["Strasbourg", "Colmar", "Metz"], "Mulhouse est une sous-préfecture du Haut-Rhin, dont la préfecture est Colmar.", source=SP),
    q("Quelle est la ville principale d'un arrondissement, quand ce n'est pas la préfecture ?", "La sous-préfecture",
      ["Le bureau de poste principal", "Le chef-lieu de canton", "La préfecture de région"],
      "Chaque arrondissement a pour chef-lieu une sous-préfecture, sauf celui de la préfecture.", source=EN),
]}
