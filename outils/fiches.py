"""Source des questions des combattants « à fiche ».

Génère CultureFight.swiftpm/Resources/fiches.json et vérifie chaque fiche.
Usage : python3 outils/fiches.py

Chaque fiche : un identifiant, des relations (paires x → y, avec question inverse facultative)
et des questions fixes (bonne réponse + mauvaises réponses écrites à la main).
"""
import json
import os
import sys

from ajouts_corps_terre_arts import AJOUTS as AJOUTS_CORPS_TERRE_ARTS
from ajouts_vivant import AJOUTS as AJOUTS_VIVANT
from contextes import CONTEXTES
from sources import FICHES_ANTERIEURES

# Nombre minimal de questions différentes par spécialité (tâche 20).
MINIMUM = 60
# Fiches qui complètent un autre générateur : nombre de questions que ce générateur apporte déjà
# (GenerateurElements : 6 éléments × 3 formes pour Néonja et Iodiateur).
COMPLEMENTS = {"gaz-nobles": 18, "halogenes": 18,
               # vague 3 : générateur d'éléments (nom, symbole, numéro) + fiche
               "metaux-alcalins": 18, "alcalino-terreux": 18, "metalloides": 18,
               "lanthanides": 45, "actinides": 45}


def rel(modele, explication, paires, inverse=None):
    return {"modele": modele, "inverse": inverse, "explication": explication,
            "paires": [list(p) for p in paires]}


def q(enonce, bonne, faux, explication, source=None):
    question = {"enonce": enonce, "bonne": bonne, "faux": faux, "explication": explication}
    if source:
        question["source"] = source
    return question


FICHES = [
    # ------------------------------------------------------------------ Vivant
    {"id": "cetaces", "relations": [
        rel("Quel cétacé correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Plus grand animal ayant jamais existé", "Baleine bleue"),
             ("Défense torsadée, surnommé la licorne des mers", "Narval"),
             ("Plus grand cétacé à dents, grand plongeur des abysses", "Cachalot"),
             ("Cétacé blanc de l'Arctique, surnommé le canari des mers", "Béluga"),
             ("Célèbre pour ses chants et ses très longues nageoires pectorales", "Baleine à bosse"),
             ("Prédateur noir et blanc qui chasse en groupe", "Orque"),
             ("Dauphin d'eau douce rose d'Amérique du Sud", "Dauphin de l'Amazone"),
             ("Plus petit cétacé, gravement menacé dans le golfe de Californie", "Vaquita"),
             ("Dauphin à bec court, le plus connu des côtes et des aquariums", "Grand dauphin"),
             ("Migre chaque année entre l'Arctique et la Basse-Californie", "Baleine grise"),
             ("Deuxième plus grand animal du monde", "Rorqual commun"),
             ("Petit cétacé sans bec des côtes européennes, cousin du dauphin", "Marsouin commun")],
            inverse="Quelle description correspond à cet animal : {y} ?"),
    ], "questions": [
        q("Comment s'appelle le petit de la baleine ?", "Baleineau", ["Baleinon", "Baleinet", "Cétaçon"],
          "Le petit de la baleine est le baleineau."),
        q("Par où respire un cétacé ?", "Par son évent", ["Par des branchies", "Par sa bouche uniquement", "Par sa peau"],
          "Les cétacés sont des mammifères : ils respirent de l'air par l'évent, sur le dessus de la tête."),
        q("Que filtrent les baleines à fanons pour se nourrir ?", "Du krill et du plancton",
          ["Des algues", "Du sable", "De l'eau douce"],
          "Les fanons filtrent l'eau pour retenir le krill et le petit plancton."),
        q("Les cétacés sont-ils des poissons ?", "Non, des mammifères",
          ["Oui, des poissons", "Non, des reptiles", "Non, des amphibiens"],
          "Les cétacés sont des mammifères marins : ils allaitent leurs petits et respirent de l'air."),
        q("Comment les dauphins repèrent-ils leurs proies dans l'eau trouble ?", "Par écholocation",
          ["Par l'odorat", "Grâce à la lumière", "Par magnétisme"],
          "Les dauphins émettent des clics et écoutent l'écho : c'est l'écholocation."),
    ]},
    {"id": "arbres", "relations": [
        rel("Quel arbre produit ce fruit : {x} ?",
            "Le fruit appelé {x} vient de cet arbre : {y}.",
            [("le gland", "Chêne"), ("la faîne", "Hêtre"), ("le marron d'Inde", "Marronnier"),
             ("la châtaigne", "Châtaignier"), ("la samare double, qui tournoie comme un hélicoptère", "Érable"),
             ("la pomme de pin", "Pin"), ("la noix", "Noyer"), ("la noisette", "Noisetier"),
             ("l'olive", "Olivier"), ("la figue", "Figuier")],
            inverse="Quel est le fruit de cet arbre : {y} ?"),
    ], "questions": [
        q("Quel conifère perd ses aiguilles en hiver ?", "Mélèze", ["Sapin", "Épicéa", "Pin"],
          "Le mélèze est l'un des rares conifères qui perdent leurs aiguilles en automne."),
        q("Quel arbre a une écorce blanche qui se détache en fines bandes ?", "Bouleau", ["Platane", "Hêtre", "Saule"],
          "L'écorce blanche du bouleau se détache en fines bandes."),
        q("Quel arbre a une écorce qui se détache en grandes plaques, souvent planté le long des routes ?", "Platane",
          ["Bouleau", "Chêne", "Peuplier"],
          "Le platane perd son écorce par plaques, ce qui lui donne un tronc tacheté."),
        q("Quel arbre des places de village donne des fleurs utilisées en tisane ?", "Tilleul", ["Érable", "Frêne", "Orme"],
          "Les fleurs de tilleul servent à faire une tisane apaisante."),
        q("Quel arbre au bord de l'eau a de longues branches tombantes ?", "Saule pleureur",
          ["Peuplier", "Bouleau", "Aulne"],
          "Le saule pleureur pousse près de l'eau, ses branches retombent jusqu'au sol."),
        q("Quel arbre d'Europe peut vivre plus de 2 000 ans et a des aiguilles toxiques ?", "If", ["Sapin", "Cèdre", "Pin"],
          "L'if est très longévif ; presque toutes ses parties sont toxiques, sauf la chair rouge de ses baies."),
        q("Quelle feuille figure sur le drapeau du Canada ?", "Érable", ["Chêne", "Platane", "Bouleau"],
          "La feuille d'érable est le symbole du Canada."),
    ]},
    {"id": "fleurs", "relations": [
        rel("De quel pays cette plante est-elle un symbole : {x} ?",
            "{x} est un symbole de ce pays : {y}.",
            [("la tulipe", "Pays-Bas"), ("la rose", "Angleterre"), ("le chardon", "Écosse"),
             ("la fleur de lys", "France"), ("la fleur de cerisier", "Japon"), ("le lotus", "Inde"),
             ("l'edelweiss", "Suisse"), ("le trèfle", "Irlande")],
            inverse="Quelle plante est un symbole de ce pays : {y} ?"),
    ], "questions": [
        q("Quelle fleur offre-t-on le 1er mai en France ?", "Muguet", ["Rose", "Tulipe", "Jonquille"],
          "Le 1er mai, on offre un brin de muguet, censé porter bonheur."),
        q("Quelle fleur dépose-t-on traditionnellement sur les tombes à la Toussaint ?", "Chrysanthème",
          ["Tournesol", "Lilas", "Glaïeul"],
          "En France, le chrysanthème est la fleur de la Toussaint."),
        q("Quelle fleur rouge est le symbole du souvenir des soldats de 14-18 au Royaume-Uni ?", "Coquelicot",
          ["Bleuet", "Rose", "Tulipe"],
          "Le coquelicot rappelle les champs de bataille des Flandres. En France, c'est le bleuet."),
        q("Quelle épice est faite avec les pistils d'une fleur, le crocus ?", "Safran", ["Vanille", "Cannelle", "Muscade"],
          "Le safran est formé des pistils séchés du crocus, récoltés à la main."),
        q("La vanille est le fruit de quelle famille de fleurs ?", "Orchidées", ["Roses", "Lys", "Tulipes"],
          "La vanille est la gousse d'une orchidée grimpante."),
        q("Quelle plante violette est cultivée en Provence pour son parfum ?", "Lavande", ["Bruyère", "Lilas", "Violette"],
          "La lavande est cultivée sur les plateaux de Provence pour les parfums et les savons."),
        q("Quelle grande fleur jaune donne des graines dont on fait de l'huile ?", "Tournesol",
          ["Colza", "Pissenlit", "Souci"],
          "Les graines de tournesol donnent l'huile de tournesol."),
    ]},
    {"id": "champignons", "relations": [
        rel("Quel champignon correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Responsable de la plupart des empoisonnements mortels en Europe", "Amanite phalloïde"),
             ("Chapeau rouge à points blancs, le champignon des contes", "Amanite tue-mouches"),
             ("Pousse sous terre, très recherché dans le Périgord", "Truffe noire"),
             ("Gros pied et chapeau brun, roi des sous-bois", "Cèpe de Bordeaux"),
             ("Jaune orangé en forme d'entonnoir, aussi appelé chanterelle", "Girolle"),
             ("Le champignon cultivé le plus vendu", "Champignon de Paris"),
             ("Chapeau alvéolé comme une éponge, cueilli au printemps", "Morille"),
             ("Noir en forme d'entonnoir, au nom inquiétant mais comestible", "Trompette de la mort"),
             ("Pousse en touffes sur le bois, très facile à cultiver", "Pleurote"),
             ("Grand chapeau écailleux sur un long pied, aussi appelé coulemelle", "Lépiote élevée")],
            inverse="Quelle description correspond à ce champignon : {y} ?"),
    ], "questions": [
        q("Quel champignon microscopique fait lever le pain ?", "La levure", ["La moisissure", "La truffe", "Le mycélium"],
          "La levure est un champignon : elle fait lever la pâte et fermenter la bière."),
        q("Quel antibiotique a été découvert grâce à une moisissure ?", "La pénicilline",
          ["L'aspirine", "La morphine", "L'insuline"],
          "Alexander Fleming a découvert la pénicilline en 1928 grâce à la moisissure Penicillium."),
        q("Comment s'appelle le réseau de filaments souterrains d'un champignon ?", "Le mycélium",
          ["Le pollen", "Le rhizome", "La sève"],
          "Le mycélium est la partie principale du champignon ; ce qu'on cueille n'en est que le fruit."),
        q("À quel règne appartiennent les champignons ?", "Un règne à part, les Fungi",
          ["Les végétaux", "Les animaux", "Les bactéries"],
          "Les champignons forment leur propre règne : ils ne font pas de photosynthèse."),
        q("Quel fromage doit ses veines bleues à un champignon ?", "Le roquefort", ["Le comté", "Le camembert", "La mozzarella"],
          "Les veines du roquefort viennent du champignon Penicillium roqueforti."),
    ]},
    {"id": "rapaces", "relations": [
        rel("Quel rapace correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Le plus rapide, plus de 300 km/h en piqué", "Faucon pèlerin"),
             ("Nocturne au visage blanc en forme de cœur", "Effraie des clochers"),
             ("Grand rapace nocturne aux aigrettes en forme d'oreilles", "Grand-duc d'Europe"),
             ("Emblème des États-Unis, à tête blanche", "Pygargue à tête blanche"),
             ("Fait du surplace au-dessus des champs pour repérer les campagnols", "Faucon crécerelle"),
             ("Vautour des montagnes qui brise les os pour en manger la moelle", "Gypaète barbu"),
             ("Pêcheur qui plonge pattes en avant pour attraper les poissons", "Balbuzard pêcheur"),
             ("Grand aigle des montagnes, présent sur de nombreux blasons", "Aigle royal"),
             ("Plus grand oiseau volant d'Amérique du Sud", "Condor des Andes"),
             ("Petite chouette symbole d'Athéna et de la sagesse", "Chevêche d'Athéna"),
             ("Roux à la queue fourchue, souvent vu au-dessus des campagnes", "Milan royal")],
            inverse="Quelle description correspond à ce rapace : {y} ?"),
    ], "questions": [
        q("Comment s'appellent les griffes des rapaces ?", "Les serres", ["Les ergots", "Les sabots", "Les rémiges"],
          "Les rapaces saisissent leurs proies avec leurs serres."),
        q("Comment appelle-t-on la boulette d'os et de poils recrachée par une chouette ?", "Une pelote de réjection",
          ["Une fiente", "Un jabot", "Un nid"],
          "Les rapaces recrachent les parties non digérées de leurs proies sous forme de pelotes de réjection."),
        q("Comment s'appelle la chasse avec des rapaces dressés ?", "La fauconnerie", ["La vénerie", "La pêche", "L'aviculture"],
          "La fauconnerie consiste à chasser avec des rapaces dressés."),
    ]},
    {"id": "felins", "relations": [
        rel("Quel félin correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Le plus grand félin du monde", "Tigre"),
             ("Le plus rapide, plus de 100 km/h en pointe", "Guépard"),
             ("Le seul félin qui vit en groupe", "Lion"),
             ("Félin d'Amérique du Sud à la morsure redoutable", "Jaguar"),
             ("Vit dans les montagnes d'Asie centrale, longue queue épaisse", "Panthère des neiges"),
             ("Félin d'Amérique aux nombreux noms, dont couguar", "Puma"),
             ("Félin d'Europe aux oreilles terminées par des pinceaux", "Lynx"),
             ("Félin tacheté d'Afrique et d'Asie, souvent appelé panthère", "Léopard"),
             ("Petit félin des forêts d'Europe, qui ressemble à un gros chat tigré", "Chat forestier"),
             ("Félin d'Afrique aux grandes oreilles et aux longues pattes", "Serval"),
             ("Félin aux oreilles noires et pointues, grand sauteur", "Caracal")],
            inverse="Quelle description correspond à ce félin : {y} ?"),
    ], "questions": [
        q("Comment s'appelle le petit du lion ?", "Le lionceau", ["Le lionnet", "Le lionçon", "Le louveteau"],
          "Le petit du lion est le lionceau."),
        q("Comment s'appelle le cri du lion ?", "Le rugissement", ["Le barrissement", "Le brame", "Le hurlement"],
          "Le lion rugit."),
        q("Quel félin ne peut pas rentrer complètement ses griffes ?", "Le guépard", ["Le lion", "Le tigre", "Le chat"],
          "Le guépard garde ses griffes sorties, qui l'aident à accrocher le sol quand il court."),
        q("Quel félin aime l'eau et nage très bien ?", "Le tigre", ["Le guépard", "Le lynx", "Le chat domestique"],
          "Contrairement à beaucoup de félins, le tigre aime l'eau et nage facilement."),
    ]},
    {"id": "primates", "relations": [
        rel("Quel primate correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Le plus grand primate vivant", "Gorille"),
             ("Grand singe d'Afrique qui fabrique et utilise des outils", "Chimpanzé"),
             ("Grand singe roux de Bornéo et de Sumatra", "Orang-outan"),
             ("Cousin pacifique du chimpanzé, vit au Congo", "Bonobo"),
             ("Lémurien de Madagascar à la queue annelée noir et blanc", "Maki catta"),
             ("Singe d'Amérique au cri très puissant", "Singe hurleur"),
             ("Le seul singe sauvage d'Europe, à Gibraltar", "Magot"),
             ("Singe qui se baigne dans les sources chaudes du Japon", "Macaque japonais"),
             ("Singe de Bornéo au nez énorme", "Nasique"),
             ("Singe au visage rouge et bleu", "Mandrill"),
             ("Petit primate nocturne d'Asie aux yeux énormes", "Tarsier"),
             ("Singe aux très longs bras qui se balance de branche en branche", "Gibbon")],
            inverse="Quelle description correspond à ce primate : {y} ?"),
    ], "questions": [
        q("Quelle primatologue a étudié les chimpanzés en Tanzanie pendant des décennies ?", "Jane Goodall",
          ["Dian Fossey", "Marie Curie", "Rachel Carson"],
          "Jane Goodall a observé les chimpanzés de Gombe, en Tanzanie, à partir de 1960."),
        q("Quelle primatologue a consacré sa vie aux gorilles des montagnes du Rwanda ?", "Dian Fossey",
          ["Jane Goodall", "Biruté Galdikas", "Jane Austen"],
          "Dian Fossey a étudié et protégé les gorilles des montagnes au Rwanda."),
        q("Combien de chromosomes a un chimpanzé ?", "48", ["46", "44", "52"],
          "Le chimpanzé a 48 chromosomes ; l'être humain en a 46."),
        q("Les grands singes (gorille, chimpanzé, orang-outan) ont-ils une queue ?", "Non, aucun",
          ["Oui, tous", "Seulement le gorille", "Seulement les jeunes"],
          "Les grands singes, comme l'humain, n'ont pas de queue."),
    ]},
    {"id": "insectes", "relations": [], "questions": [
        q("Combien de pattes a un insecte ?", "6", ["8", "4", "10"],
          "Tous les insectes ont 6 pattes."),
        q("Combien de pattes a une araignée ?", "8", ["6", "10", "12"],
          "L'araignée a 8 pattes : ce n'est pas un insecte, mais un arachnide."),
        q("En combien de parties se divise le corps d'un insecte ?", "3", ["2", "4", "5"],
          "Le corps d'un insecte se divise en tête, thorax et abdomen."),
        q("Quel insecte produit le miel ?", "L'abeille", ["La guêpe", "Le bourdon", "La fourmi"],
          "Les abeilles fabriquent le miel à partir du nectar des fleurs."),
        q("Comment s'appelle la larve du papillon ?", "La chenille", ["L'asticot", "La nymphe", "Le têtard"],
          "Le papillon passe par le stade de chenille, puis de chrysalide."),
        q("Comment s'appelle la larve de la mouche ?", "L'asticot", ["La chenille", "Le ver blanc", "La larve d'or"],
          "La larve de la mouche est l'asticot."),
        q("Quel insecte femelle dévore parfois le mâle après l'accouplement ?", "La mante religieuse",
          ["La coccinelle", "La libellule", "Le grillon"],
          "La femelle mante religieuse mange parfois le mâle pendant ou après l'accouplement."),
        q("Quel insecte produit de la lumière ?", "Le ver luisant", ["Le scarabée", "La cigale", "Le criquet"],
          "Le ver luisant (une luciole) produit de la lumière par bioluminescence."),
        q("Quel insecte transmet le paludisme ?", "Le moustique", ["La mouche tsé-tsé", "La puce", "La punaise"],
          "Le paludisme est transmis par la piqûre de certains moustiques, les anophèles."),
        q("Quel papillon migre chaque année du Canada jusqu'au Mexique ?", "Le monarque",
          ["Le machaon", "Le paon-du-jour", "La piéride"],
          "Les monarques parcourent des milliers de kilomètres pour hiverner au Mexique."),
        q("Quelle chenille fabrique la soie ?", "Le ver à soie", ["La chenille processionnaire", "Le ver de terre", "Le ver luisant"],
          "Le ver à soie, chenille du bombyx du mûrier, tisse son cocon en fil de soie."),
        q("Quel scarabée fait rouler des boules d'excréments ?", "Le bousier", ["Le hanneton", "La coccinelle", "Le charançon"],
          "Le bousier roule des boules de bouse pour s'en nourrir et y pondre."),
        q("Combien d'ailes a une mouche ?", "2", ["4", "6", "0"],
          "La mouche n'a qu'une paire d'ailes ; la seconde est réduite à de petits balanciers."),
        q("Quel insecte chante dans les pins de Provence en été ?", "La cigale", ["Le grillon", "La sauterelle", "Le bourdon"],
          "Le mâle cigale chante en faisant vibrer des membranes de son abdomen."),
        q("Quel insecte construit des termitières ?", "Le termite", ["La fourmi rouge", "La guêpe", "L'abeille"],
          "Les termites bâtissent des termitières qui peuvent dépasser plusieurs mètres de haut."),
    ]},
    {"id": "reptiles", "relations": [
        rel("Quel reptile correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Le plus grand reptile vivant, il vit aussi en eau salée", "Crocodile marin"),
             ("Lézard qui change de couleur et bouge ses yeux indépendamment", "Caméléon"),
             ("Le plus grand lézard du monde, en Indonésie", "Dragon de Komodo"),
             ("Le plus long serpent du monde", "Python réticulé"),
             ("Le serpent le plus lourd, dans les fleuves d'Amérique du Sud", "Anaconda vert"),
             ("Serpent venimeux qui se dresse en déployant une collerette", "Cobra"),
             ("La plus grande tortue marine, grande mangeuse de méduses", "Tortue luth"),
             ("Cousin du crocodile en Amérique, au museau large et arrondi", "Alligator"),
             ("Lézard qui grimpe aux murs et aux plafonds grâce à ses doigts", "Gecko"),
             ("Tortue géante des îles Galápagos", "Tortue des Galápagos"),
             ("Serpent venimeux de France, à la pupille verticale", "Vipère")],
            inverse="Quelle description correspond à ce reptile : {y} ?"),
    ], "questions": [
        q("Les reptiles produisent-ils leur propre chaleur corporelle ?", "Non, ils dépendent de l'extérieur",
          ["Oui, comme les mammifères", "Oui, seulement la nuit", "Seulement les tortues"],
          "Les reptiles sont ectothermes : ils se chauffent au soleil."),
        q("Que peut perdre un lézard pour échapper à un prédateur ?", "Sa queue", ["Ses pattes", "Sa peau", "Ses yeux"],
          "Le lézard peut abandonner sa queue, qui repousse ensuite."),
        q("Avec quoi un serpent capte-t-il les odeurs ?", "Sa langue fourchue", ["Ses narines seulement", "Ses écailles", "Ses yeux"],
          "Le serpent sort sa langue pour capter les odeurs et les porter à un organe dans son palais."),
        q("Comment s'appelle l'opération où un serpent change de peau ?", "La mue", ["La ponte", "L'hibernation", "La métamorphose"],
          "Le serpent mue plusieurs fois par an et laisse sa vieille peau derrière lui."),
    ]},
    {"id": "dinosaures", "relations": [
        rel("Quel animal préhistorique correspond à cette description : « {x} » ?",
            "{y} : {x}.",
            [("Grand carnivore du Crétacé aux bras minuscules", "Tyrannosaure"),
             ("Herbivore à trois cornes et à collerette", "Tricératops"),
             ("Herbivore à plaques sur le dos et à queue pointue", "Stégosaure"),
             ("Herbivore géant au très long cou, du Jurassique", "Diplodocus"),
             ("Petit carnivore rapide à griffe en forme de faucille", "Vélociraptor"),
             ("Herbivore à bec de canard et à longue crête tubulaire", "Parasaurolophus"),
             ("Herbivore cuirassé à queue en massue", "Ankylosaure"),
             ("Grand carnivore à voile sur le dos, mangeur de poissons", "Spinosaure"),
             ("Grand carnivore du Jurassique, bien avant le tyrannosaure", "Allosaure"),
             ("Dinosaure à plumes de Bavière, proche des premiers oiseaux", "Archéoptéryx"),
             ("Herbivore au crâne en dôme très épais", "Pachycéphalosaure"),
             ("Reptile volant à crête, qui n'est pas un dinosaure", "Ptéranodon")],
            inverse="Quelle description correspond à cet animal : {y} ?"),
    ], "questions": [
        q("Il y a combien de temps les dinosaures (sauf les oiseaux) ont-ils disparu ?", "Environ 66 millions d'années",
          ["Environ 6 millions d'années", "Environ 660 000 ans", "Environ 1 milliard d'années"],
          "Les dinosaures non aviens ont disparu il y a environ 66 millions d'années."),
        q("Quelle est la cause principale retenue pour leur extinction ?", "La chute d'un astéroïde géant",
          ["Une épidémie", "Une glaciation brutale", "La chasse par les humains"],
          "La chute d'un astéroïde au Mexique (cratère de Chicxulub) est la cause principale retenue."),
        q("Quels animaux actuels descendent des dinosaures ?", "Les oiseaux", ["Les lézards", "Les crocodiles", "Les tortues"],
          "Les oiseaux sont des dinosaures à plumes qui ont survécu."),
        q("Comment s'appelle le scientifique qui étudie les fossiles ?", "Le paléontologue",
          ["L'archéologue", "Le géologue", "L'anthropologue"],
          "Le paléontologue étudie les êtres vivants disparus à partir des fossiles."),
    ]},
    {"id": "eres-geologiques", "relations": [], "questions": [
        q("Dans quelle ère ont vécu les dinosaures ?", "Le Mésozoïque", ["Le Paléozoïque", "Le Cénozoïque", "Le Précambrien"],
          "Les dinosaures ont vécu au Mésozoïque, aussi appelé ère secondaire."),
        q("Quelles sont les trois périodes du Mésozoïque, dans l'ordre ?", "Trias, Jurassique, Crétacé",
          ["Jurassique, Trias, Crétacé", "Crétacé, Jurassique, Trias", "Trias, Crétacé, Jurassique"],
          "Le Mésozoïque se divise en Trias, Jurassique puis Crétacé."),
        q("Quelle période vient après le Jurassique ?", "Le Crétacé", ["Le Trias", "Le Permien", "Le Carbonifère"],
          "Le Crétacé suit le Jurassique et se termine avec l'extinction des dinosaures."),
        q("Dans quelle ère vivons-nous ?", "Le Cénozoïque", ["Le Mésozoïque", "Le Paléozoïque", "Le Jurassique"],
          "Nous vivons dans le Cénozoïque, l'ère des mammifères, commencée il y a 66 millions d'années."),
        q("Quel est l'âge de la Terre ?", "Environ 4,5 milliards d'années",
          ["Environ 6 000 ans", "Environ 450 millions d'années", "Environ 45 milliards d'années"],
          "La Terre s'est formée il y a environ 4,5 milliards d'années."),
        q("Quelle ère a vu foisonner les trilobites dans les mers ?", "Le Paléozoïque", ["Le Mésozoïque", "Le Cénozoïque", "Le Quaternaire"],
          "Les trilobites ont peuplé les mers pendant tout le Paléozoïque, ou ère primaire."),
        q("Pendant quelle période les forêts géantes ont-elles formé le charbon ?", "Le Carbonifère",
          ["Le Crétacé", "Le Trias", "Le Pléistocène"],
          "Le Carbonifère doit son nom au charbon issu de ses immenses forêts."),
        q("Comment s'appelle le supercontinent qui regroupait toutes les terres ?", "La Pangée",
          ["La Gondwanie", "L'Atlantide", "La Laurasie"],
          "La Pangée regroupait presque toutes les terres avant de se fragmenter au Mésozoïque."),
        q("À la fin de quelle période a eu lieu la plus grande extinction de l'histoire ?", "Le Permien",
          ["Le Crétacé", "Le Jurassique", "Le Dévonien"],
          "L'extinction de la fin du Permien a fait disparaître la grande majorité des espèces marines."),
        q("Quel massif a donné son nom au Jurassique ?", "Le Jura", ["Les Alpes", "Les Pyrénées", "Le Massif central"],
          "Le Jurassique doit son nom aux roches du massif du Jura."),
        q("Quel fossile en spirale est typique de l'ère secondaire ?", "L'ammonite", ["Le trilobite", "Le mammouth", "Le corail"],
          "Les ammonites, mollusques à coquille en spirale, ont disparu avec les dinosaures."),
        q("À quelle époque vivaient les mammouths laineux ?", "Le Pléistocène", ["Le Jurassique", "Le Crétacé", "Le Trias"],
          "Les mammouths laineux vivaient au Pléistocène, l'époque des grandes glaciations."),
    ]},
    # ------------------------------------------------------------ Corps humain
    {"id": "os", "relations": [
        rel("Où se trouve cet os : {x} ?",
            "Cet os, {x}, se trouve à cet endroit : {y}.",
            [("le fémur", "la cuisse"), ("le tibia", "la jambe"), ("le radius", "l'avant-bras"),
             ("l'humérus", "le bras"), ("la rotule", "le genou"), ("l'omoplate", "l'épaule"),
             ("le sternum", "le thorax"), ("la mandibule", "la mâchoire"), ("l'étrier", "l'oreille"),
             ("les phalanges", "les doigts"), ("le calcanéum", "le talon"), ("les vertèbres", "le dos"),
             ("le pariétal", "le crâne")],
            inverse="Quel os se trouve à cet endroit : {y} ?"),
    ], "questions": [
        q("Combien d'os compte le squelette d'un adulte ?", "206", ["186", "226", "306"],
          "Un adulte a 206 os ; un nouveau-né en a davantage, qui se soudent en grandissant."),
        q("Quel est l'os le plus long du corps humain ?", "Le fémur", ["Le tibia", "L'humérus", "La colonne vertébrale"],
          "Le fémur, l'os de la cuisse, est le plus long et le plus solide."),
        q("Quel est le plus petit os du corps humain ?", "L'étrier", ["La phalange du petit orteil", "Le coccyx", "La rotule"],
          "L'étrier, dans l'oreille moyenne, mesure environ 3 millimètres."),
        q("Combien de paires de côtes a l'être humain ?", "12", ["10", "14", "24"],
          "L'être humain a 12 paires de côtes, soit 24 côtes."),
        q("Quel minéral rend les os solides ?", "Le calcium", ["Le fer", "Le sodium", "Le zinc"],
          "Les os sont riches en calcium, sous forme de phosphate de calcium."),
    ]},
    {"id": "organes", "relations": [
        rel("Quel organe a ce rôle : {x} ?",
            "{y} : {x}.",
            [("pomper le sang dans tout le corps", "Le cœur"), ("filtrer le sang et produire l'urine", "Les reins"),
             ("faire passer l'oxygène de l'air dans le sang", "Les poumons"),
             ("produire la bile et stocker des réserves", "Le foie"), ("produire l'insuline", "Le pancréas"),
             ("absorber les nutriments des aliments digérés", "L'intestin grêle"), ("stocker l'urine", "La vessie"),
             ("broyer et digérer les aliments avec des sucs acides", "L'estomac"),
             ("protéger le corps du milieu extérieur", "La peau"), ("commander le corps et penser", "Le cerveau"),
             ("stocker la bile entre les repas", "La vésicule biliaire"),
             ("filtrer le sang et aider les défenses immunitaires", "La rate")],
            inverse="Quel est le rôle de cet organe : {y} ?"),
    ], "questions": [
        q("Combien de cavités compte le cœur humain ?", "4", ["2", "3", "6"],
          "Le cœur a deux oreillettes et deux ventricules."),
        q("Quel est le plus gros organe à l'intérieur du corps ?", "Le foie", ["Le cerveau", "Les poumons", "L'estomac"],
          "Le foie pèse environ 1,5 kg chez l'adulte."),
        q("Quel organe peut repousser après qu'on en a retiré une partie ?", "Le foie", ["Le cœur", "Le cerveau", "Le rein"],
          "Le foie peut se régénérer et retrouver sa taille après une ablation partielle."),
        q("Comment s'appellent les petits sacs des poumons où l'oxygène passe dans le sang ?", "Les alvéoles",
          ["Les bronches", "Les villosités", "Les capillaires"],
          "Les alvéoles pulmonaires, très nombreuses, font passer l'oxygène dans le sang."),
        q("Quel est l'organe le plus étendu du corps ?", "La peau", ["L'intestin grêle", "Le foie", "Les poumons"],
          "La peau couvre près de 2 m² chez l'adulte."),
    ]},
    {"id": "muscles", "relations": [
        rel("Où se trouve ce muscle : {x} ?",
            "{x} se trouve à cet endroit : {y}.",
            [("le biceps", "l'avant du bras"), ("le triceps", "l'arrière du bras"),
             ("le quadriceps", "l'avant de la cuisse"), ("les ischio-jambiers", "l'arrière de la cuisse"),
             ("le deltoïde", "l'épaule"), ("le grand pectoral", "la poitrine"), ("le grand droit", "le ventre"),
             ("le grand fessier", "les fesses"), ("le diaphragme", "sous les poumons"),
             ("le masséter", "la mâchoire"), ("le trapèze", "le haut du dos et la nuque"),
             ("le myocarde", "le cœur"), ("le gastrocnémien", "le mollet")],
            inverse="Quel muscle se trouve à cet endroit : {y} ?"),
    ], "questions": [
        q("Quel est le plus gros muscle du corps ?", "Le grand fessier", ["Le biceps", "Le quadriceps", "Le grand pectoral"],
          "Le grand fessier est le muscle le plus volumineux du corps."),
        q("Quel muscle fait respirer ?", "Le diaphragme", ["Le grand pectoral", "Le trapèze", "Le grand droit"],
          "En se contractant, le diaphragme fait entrer l'air dans les poumons."),
        q("Quel tendon relie le mollet au talon ?", "Le tendon d'Achille", ["Le tendon rotulien", "Le ligament croisé", "Le ménisque"],
          "Le tendon d'Achille est le plus gros tendon du corps."),
        q("Combien de muscles compte environ le corps humain ?", "Plus de 600",
          ["Une centaine", "Environ 250", "Plus de 5 000"],
          "Le corps humain compte plus de 600 muscles."),
        q("Quel muscle travaille sans jamais s'arrêter ?", "Le myocarde", ["Le diaphragme", "Le biceps", "Le masséter"],
          "Le myocarde, le muscle du cœur, se contracte sans arrêt toute la vie."),
    ]},
    # ----------------------------------------------------------------- Terre
    {"id": "volcans", "relations": [
        rel("Dans quel pays se trouve le volcan {x} ?",
            "Le volcan {x} se trouve dans ce pays : {y}.",
            [("Etna", "Italie"), ("Vésuve", "Italie"), ("Stromboli", "Italie"),
             ("Piton de la Fournaise", "France (La Réunion)"), ("Montagne Pelée", "France (Martinique)"),
             ("Kīlauea", "États-Unis (Hawaï)"), ("Mont Saint Helens", "États-Unis"), ("Mont Fuji", "Japon"),
             ("Eyjafjallajökull", "Islande"), ("Hekla", "Islande"), ("Krakatoa", "Indonésie"),
             ("Merapi", "Indonésie"), ("Popocatépetl", "Mexique"), ("Erebus", "Antarctique"),
             ("Nyiragongo", "République démocratique du Congo"), ("Pinatubo", "Philippines"),
             ("Cotopaxi", "Équateur")]),
    ], "questions": [
        q("Quelle ville romaine a été ensevelie par le Vésuve en 79 ?", "Pompéi", ["Rome", "Naples", "Ostie"],
          "L'éruption du Vésuve en 79 a enseveli Pompéi et Herculanum."),
        q("Comment appelle-t-on la roche en fusion sous la surface ?", "Le magma", ["La lave", "Le basalte", "La cendre"],
          "Sous la surface, c'est du magma ; une fois sorti du volcan, on parle de lave."),
        q("Comment s'appelle l'alignement de volcans autour du Pacifique ?", "La ceinture de feu",
          ["La dorsale atlantique", "La couronne volcanique", "L'arc de cendres"],
          "La ceinture de feu du Pacifique regroupe la majorité des volcans actifs du monde."),
        q("Quelle ville la montagne Pelée a-t-elle détruite en 1902 ?", "Saint-Pierre", ["Fort-de-France", "Pointe-à-Pitre", "Cayenne"],
          "L'éruption de la montagne Pelée a détruit Saint-Pierre, en Martinique, en 1902."),
        q("Quel volcan islandais a bloqué le trafic aérien européen en 2010 ?", "Eyjafjallajökull", ["Hekla", "Etna", "Stromboli"],
          "Le nuage de cendres de l'Eyjafjallajökull a cloué au sol des milliers d'avions en avril 2010."),
    ]},
    {"id": "seismes", "relations": [
        rel("En quelle année a eu lieu le grand séisme de {x} ?",
            "Le séisme de {x} a eu lieu en {y}.",
            [("Lisbonne", "1755"), ("San Francisco", "1906"), ("Messine", "1908"), ("Valdivia (Chili)", "1960"),
             ("l'Alaska", "1964"), ("Kobe", "1995"), ("Sumatra, suivi d'un tsunami", "2004"),
             ("Haïti", "2010"), ("Tōhoku (Japon)", "2011"), ("Turquie et Syrie", "2023")],
            inverse="Quel grand séisme a eu lieu en {y} ?"),
    ], "questions": [
        q("Quel appareil enregistre les séismes ?", "Le sismographe", ["Le baromètre", "L'anémomètre", "Le pluviomètre"],
          "Le sismographe enregistre les mouvements du sol."),
        q("Comment s'appelle le point de la surface situé au-dessus du foyer d'un séisme ?", "L'épicentre",
          ["L'hypocentre", "La faille", "Le cratère"],
          "Le foyer est en profondeur ; l'épicentre est le point de la surface juste au-dessus."),
        q("Quel est le séisme le plus puissant jamais enregistré ?", "Valdivia (Chili), 1960",
          ["Tōhoku (Japon), 2011", "San Francisco, 1906", "Lisbonne, 1755"],
          "Le séisme de Valdivia, en 1960, a atteint une magnitude de 9,5."),
        q("Comment s'appelle la vague géante provoquée par un séisme sous-marin ?", "Un tsunami",
          ["Un mascaret", "Une lame de fond", "Un raz de marée solaire"],
          "Un séisme sous la mer peut déplacer d'énormes masses d'eau et provoquer un tsunami."),
        q("Quelle centrale nucléaire a été frappée par le tsunami de 2011 ?", "Fukushima", ["Tchernobyl", "Three Mile Island", "Flamanville"],
          "Le tsunami du 11 mars 2011 a provoqué l'accident nucléaire de Fukushima."),
        q("Comment s'appellent les grandes pièces qui forment la croûte terrestre ?", "Les plaques tectoniques",
          ["Les strates", "Les dorsales", "Les continents flottants"],
          "La plupart des séismes se produisent à la frontière des plaques tectoniques."),
    ]},
    {"id": "fleuves-europe", "relations": [
        rel("Quelle ville le fleuve {x} traverse-t-il ?",
            "{x} traverse {y}.",
            [("la Seine", "Paris"), ("la Tamise", "Londres"), ("le Tibre", "Rome"), ("le Danube", "Budapest"),
             ("le Tage", "Lisbonne"), ("le Rhin", "Cologne"), ("l'Elbe", "Dresde"), ("la Vistule", "Varsovie"),
             ("le Guadalquivir", "Séville"), ("l'Arno", "Florence"), ("la Garonne", "Bordeaux"),
             ("la Loire", "Nantes")],
            inverse="Quel fleuve traverse {y} ?"),
        rel("Dans quelle mer se jette le fleuve {x} ?",
            "{x} se jette dans {y}.",
            [("la Seine", "la Manche"), ("la Loire", "l'océan Atlantique"), ("le Rhône", "la mer Méditerranée"),
             ("le Rhin", "la mer du Nord"), ("le Danube", "la mer Noire"), ("la Volga", "la mer Caspienne"),
             ("le Pô", "la mer Adriatique"), ("la Vistule", "la mer Baltique")]),
    ], "questions": [
        q("Quel est le plus long fleuve d'Europe ?", "La Volga", ["Le Danube", "Le Rhin", "La Loire"],
          "La Volga, en Russie, mesure environ 3 500 km."),
        q("Quel est le plus long fleuve de France ?", "La Loire", ["La Seine", "Le Rhône", "La Garonne"],
          "La Loire mesure environ 1 000 km."),
        q("Combien de capitales le Danube traverse-t-il ?", "4", ["2", "3", "6"],
          "Le Danube traverse Vienne, Bratislava, Budapest et Belgrade."),
        q("Quel fleuve forme une partie de la frontière entre la France et l'Allemagne ?", "Le Rhin",
          ["La Moselle", "Le Danube", "La Meuse"],
          "Le Rhin sépare l'Alsace de l'Allemagne."),
    ]},
    {"id": "fleuves-monde", "relations": [
        rel("Sur quel continent coule le fleuve {x} ?",
            "{x} coule en {y}.",
            [("Amazone", "Amérique du Sud"), ("Nil", "Afrique"), ("Mississippi", "Amérique du Nord"),
             ("Yangzi Jiang", "Asie"), ("Gange", "Asie"), ("Mékong", "Asie"), ("Congo", "Afrique"),
             ("Niger", "Afrique"), ("Zambèze", "Afrique"), ("Murray", "Océanie"), ("Volga", "Europe"),
             ("Paraná", "Amérique du Sud"), ("Orénoque", "Amérique du Sud"), ("Saint-Laurent", "Amérique du Nord"),
             ("Yukon", "Amérique du Nord"), ("Indus", "Asie")]),
        rel("Quelle ville le fleuve {x} traverse-t-il ?",
            "{x} traverse {y}.",
            [("le Nil", "Le Caire"), ("l'Amazone", "Iquitos"), ("le Mississippi", "La Nouvelle-Orléans"),
             ("le Gange", "Varanasi"), ("le Yangzi Jiang", "Wuhan"), ("l'Hudson", "New York"),
             ("le Saint-Laurent", "Québec"), ("le Mékong", "Phnom Penh"), ("le Congo", "Kinshasa"),
             ("le Niger", "Bamako"), ("le Tigre", "Bagdad"), ("la Chao Phraya", "Bangkok"),
             ("le Potomac", "Washington")],
            inverse="Quel fleuve traverse {y} ?"),
    ], "questions": [
        q("Quel fleuve a le plus grand débit du monde ?", "L'Amazone", ["Le Nil", "Le Congo", "Le Mississippi"],
          "L'Amazone déverse à lui seul environ un cinquième de l'eau douce qui arrive dans les océans."),
        q("Quel est le plus long fleuve d'Asie ?", "Le Yangzi Jiang", ["Le Gange", "Le Mékong", "L'Indus"],
          "Le Yangzi Jiang, en Chine, mesure environ 6 300 km."),
        q("Quel est le plus long fleuve d'Afrique ?", "Le Nil", ["Le Congo", "Le Niger", "Le Zambèze"],
          "Le Nil mesure environ 6 700 km."),
        q("Quel fleuve est sacré pour les hindous ?", "Le Gange", ["L'Indus", "Le Mékong", "Le Brahmapoutre"],
          "Les hindous viennent se purifier dans le Gange, notamment à Varanasi."),
        q("Quel fleuve a creusé le Grand Canyon ?", "Le Colorado", ["Le Mississippi", "Le Missouri", "Le Rio Grande"],
          "Le Colorado a creusé le Grand Canyon pendant des millions d'années."),
        q("Sur quel fleuve se trouvent les chutes Victoria ?", "Le Zambèze", ["Le Nil", "Le Congo", "Le Niger"],
          "Les chutes Victoria, entre la Zambie et le Zimbabwe, sont sur le Zambèze."),
        q("Quel fleuve traverse le plus de pays au monde ?", "Le Danube", ["Le Nil", "L'Amazone", "Le Rhin"],
          "Le Danube traverse 10 pays, de l'Allemagne à l'Ukraine."),
    ]},
    {"id": "lacs", "relations": [
        rel("Dans quel(s) pays se trouve le lac {x} ?",
            "Le lac {x} se trouve dans ce(s) pays : {y}.",
            [("Titicaca", "Pérou et Bolivie"), ("Baïkal", "Russie"), ("Léman", "Suisse et France"),
             ("Loch Ness", "Écosse"), ("Victoria", "Ouganda, Kenya et Tanzanie"),
             ("Supérieur", "États-Unis et Canada"), ("Michigan", "États-Unis"), ("Balaton", "Hongrie"),
             ("de Garde", "Italie"), ("de Côme", "Italie"), ("de Constance", "Allemagne, Suisse et Autriche"),
             ("d'Annecy", "France"), ("Tchad", "Tchad, Cameroun, Niger et Nigeria")]),
    ], "questions": [
        q("Quel est le lac le plus profond du monde ?", "Le Baïkal", ["Le Tanganyika", "Le lac Supérieur", "Le Titicaca"],
          "Le lac Baïkal, en Sibérie, dépasse 1 600 m de profondeur."),
        q("Quel est le plus grand lac d'eau douce du monde par sa superficie ?", "Le lac Supérieur",
          ["Le lac Victoria", "Le Baïkal", "Le lac Michigan"],
          "Le lac Supérieur, entre les États-Unis et le Canada, couvre environ 82 000 km²."),
        q("Quelle est la plus grande étendue d'eau fermée du monde ?", "La mer Caspienne",
          ["Le lac Supérieur", "La mer Morte", "La mer d'Aral"],
          "Malgré son nom, la mer Caspienne est un immense lac salé."),
        q("Quel est le plus grand lac d'Afrique ?", "Le lac Victoria", ["Le lac Tanganyika", "Le lac Tchad", "Le lac Malawi"],
          "Le lac Victoria est partagé entre l'Ouganda, le Kenya et la Tanzanie."),
        q("Quel monstre légendaire vivrait dans un lac écossais ?", "Nessie", ["Le Yéti", "Le Kraken", "Le Bigfoot"],
          "Nessie serait le monstre du Loch Ness ; son existence n'a jamais été prouvée."),
        q("Combien de lacs forment les Grands Lacs d'Amérique du Nord ?", "5", ["3", "4", "7"],
          "Les cinq Grands Lacs sont le Supérieur, le Michigan, le Huron, l'Érié et l'Ontario."),
        q("Quel lac est souvent présenté comme le plus haut lac navigable du monde ?", "Le Titicaca",
          ["Le Baïkal", "Le Léman", "Le lac Victoria"],
          "Le lac Titicaca est à environ 3 800 m d'altitude, entre le Pérou et la Bolivie."),
        q("Quelle part de l'eau douce liquide de surface de la planète contient le Baïkal ?", "Environ 20 %",
          ["Environ 2 %", "Environ 50 %", "Environ 80 %"],
          "Le Baïkal contient à lui seul environ 20 % de l'eau douce liquide de surface du monde."),
    ]},
    {"id": "oceans-mers", "relations": [
        rel("Quelle mer ou quel océan borde la ville de {x} ?",
            "{x} est au bord de {y}.",
            [("Marseille", "la mer Méditerranée"), ("Le Havre", "la Manche"), ("Saint-Pétersbourg", "la mer Baltique"),
             ("Odessa", "la mer Noire"), ("Venise", "la mer Adriatique"), ("Rotterdam", "la mer du Nord"),
             ("Bakou", "la mer Caspienne"), ("Djeddah", "la mer Rouge"), ("Sydney", "l'océan Pacifique"),
             ("Bombay", "l'océan Indien"), ("Rio de Janeiro", "l'océan Atlantique"), ("Vladivostok", "la mer du Japon"),
             ("Le Pirée, près d'Athènes", "la mer Égée")]),
    ], "questions": [
        q("Quel est le plus grand océan du monde ?", "Le Pacifique", ["L'Atlantique", "L'océan Indien", "L'Arctique"],
          "Le Pacifique couvre à lui seul près d'un tiers de la surface de la Terre."),
        q("Combien y a-t-il d'océans sur Terre ?", "5", ["3", "4", "7"],
          "Pacifique, Atlantique, Indien, Arctique et Austral."),
        q("Où se trouve le point le plus profond des océans ?", "La fosse des Mariannes",
          ["La fosse de Porto Rico", "Le triangle des Bermudes", "La dorsale atlantique"],
          "La fosse des Mariannes, dans le Pacifique, dépasse 10 900 m de profondeur."),
        q("Quel océan entoure l'Antarctique ?", "L'océan Austral", ["L'océan Arctique", "L'océan Indien", "L'Atlantique"],
          "L'océan Austral entoure le continent antarctique."),
        q("Quel détroit sépare l'Europe de l'Afrique ?", "Le détroit de Gibraltar",
          ["Le Bosphore", "Le détroit de Messine", "Le pas de Calais"],
          "Le détroit de Gibraltar relie l'Atlantique à la Méditerranée."),
        q("Quel canal relie la Méditerranée à la mer Rouge ?", "Le canal de Suez", ["Le canal de Panama", "Le canal de Corinthe", "Le canal du Midi"],
          "Le canal de Suez, en Égypte, a été inauguré en 1869."),
        q("Quel canal relie l'Atlantique au Pacifique ?", "Le canal de Panama", ["Le canal de Suez", "Le canal de Kiel", "Le détroit de Magellan"],
          "Le canal de Panama a été ouvert en 1914."),
        q("Quel courant marin chaud adoucit le climat de l'Europe de l'Ouest ?", "Le Gulf Stream",
          ["El Niño", "Le courant de Humboldt", "Le courant des Canaries"],
          "Le Gulf Stream transporte des eaux chaudes du golfe du Mexique vers l'Atlantique Nord."),
        q("Quelle part de la surface de la Terre les océans couvrent-ils ?", "Environ 70 %",
          ["Environ 50 %", "Environ 30 %", "Environ 90 %"],
          "Les océans couvrent environ 71 % de la surface de la planète."),
    ]},
    # ------------------------------------------------------------------ Arts
    {"id": "peintres-renaissance", "relations": [
        rel("Qui a peint « {x} » ?",
            "« {x} » est une œuvre de {y}.",
            [("La Joconde", "Léonard de Vinci"), ("La Cène", "Léonard de Vinci"),
             ("La Naissance de Vénus", "Sandro Botticelli"), ("Le Printemps", "Sandro Botticelli"),
             ("La Création d'Adam", "Michel-Ange"), ("L'École d'Athènes", "Raphaël"),
             ("La Vénus d'Urbino", "Titien"), ("Le Jardin des délices", "Jérôme Bosch"),
             ("Les Époux Arnolfini", "Jan van Eyck"), ("Les Ambassadeurs", "Hans Holbein le Jeune"),
             ("Les Chasseurs dans la neige", "Pieter Bruegel l'Ancien"),
             ("Autoportrait à la fourrure", "Albrecht Dürer")]),
    ], "questions": [
        q("Dans quelle ville est née la Renaissance italienne ?", "Florence", ["Rome", "Venise", "Milan"],
          "La Renaissance est née à Florence au XVe siècle."),
        q("Dans quel musée est exposée La Joconde ?", "Le Louvre", ["Les Offices", "Le Prado", "Le Vatican"],
          "La Joconde est exposée au musée du Louvre, à Paris."),
        q("Quelle famille de banquiers florentins a protégé les artistes de la Renaissance ?", "Les Médicis",
          ["Les Borgia", "Les Sforza", "Les Habsbourg"],
          "Les Médicis ont financé de nombreux artistes, dont Botticelli et Michel-Ange."),
        q("Quelle chapelle Michel-Ange a-t-il décorée de fresques sur son plafond ?", "La chapelle Sixtine",
          ["La chapelle royale", "La Sainte-Chapelle", "La chapelle des Médicis"],
          "Michel-Ange a peint le plafond de la chapelle Sixtine, au Vatican, de 1508 à 1512."),
        q("Dans quel pays Léonard de Vinci est-il mort ?", "La France", ["L'Italie", "L'Espagne", "La Suisse"],
          "Léonard de Vinci est mort en 1519 au Clos Lucé, près d'Amboise, invité par François Ier."),
    ]},
]


def ajouter_contextes(fiche):
    """Ajoute à chaque paire sa ligne de contexte (3e élément), tirée de contextes.py."""
    erreurs = []
    for n, r in enumerate(fiche["relations"]):
        contextes = CONTEXTES.get((fiche["id"], n), {})
        for p in r["paires"]:
            texte = (p[2] if len(p) > 2 else contextes.get(p[0], "")).strip()
            if not texte:
                erreurs.append(f"relation {n} : pas de contexte pour « {p[0]} »")
            source = p[3] if len(p) > 3 else ""
            del p[2:]
            p.append(texte)
            if source:
                p.append(source)
        inconnus = set(contextes) - {p[0] for p in r["paires"]}
        for x in sorted(inconnus):
            erreurs.append(f"relation {n} : contexte sans paire pour « {x} »")
    return erreurs


def verifier(fiche):
    erreurs = ajouter_contextes(fiche)
    total = len(fiche["questions"])
    for r in fiche["relations"]:
        ys = [p[1] for p in r["paires"]]
        xs = [p[0] for p in r["paires"]]
        if len(set(ys)) < 4:
            erreurs.append(f"relation « {r['modele']} » : moins de 4 réponses différentes")
        if len(set(xs)) != len(xs):
            erreurs.append(f"relation « {r['modele']} » : x en double")
        if r["inverse"]:
            for y in set(ys):
                if len([x for x, yy in zip(xs, ys) if yy != y]) < 3:
                    erreurs.append(f"inverse « {r['inverse']} » : trop peu de mauvaises réponses pour {y}")
            if len(set(ys)) != len(ys):
                erreurs.append(f"inverse « {r['inverse']} » : y en double (question ambiguë)")
        for p in r["paires"]:
            if len({y for y in ys if not recouvrent(r, p[1], y)}) < 3:
                erreurs.append(f"« {p[0]} » : moins de 3 mauvaises réponses possibles")
        total += len(r["paires"]) * (2 if r["inverse"] else 1)
    for qq in fiche["questions"]:
        if len(set(qq["faux"])) < 3 or qq["bonne"] in qq["faux"]:
            erreurs.append(f"question « {qq['enonce']} » : mauvaises réponses incorrectes")
        if not qq["explication"].strip():
            erreurs.append(f"question « {qq['enonce']} » : pas d'explication")
    return total, erreurs


# Réponses qui se recouvrent (une mer et l'océan dont elle fait partie…) : le jeu ne les propose
# jamais comme mauvaise réponse l'une de l'autre. Clé : (fiche, numéro de la relation).
RECOUVREMENTS = {
    ("oceans-mers", 0): [["l'océan Atlantique", "la Manche", "la mer du Nord", "la mer Baltique"],
                         ["la mer Méditerranée", "la mer Adriatique", "la mer Égée", "la mer Noire"],
                         ["l'océan Indien", "la mer Rouge"],
                         ["l'océan Pacifique", "la mer du Japon"]],
    ("oceans-mers", 2): [["l'océan Atlantique", "la mer Baltique"]],
    ("fleuves-europe", 1): [["la mer Méditerranée", "la mer Adriatique", "la mer Noire"],
                            ["l'océan Atlantique", "la Manche", "la mer du Nord", "la mer Baltique"]],
    ("fleuves-monde", 2): [["l'océan Atlantique", "le golfe du Mexique", "le golfe de Guinée"],
                           ["l'océan Indien", "le golfe du Bengale", "la mer d'Arabie"]],
    ("volcans", 0): [["États-Unis", "États-Unis (Hawaï)"], ["France (La Réunion)", "France (Martinique)"]],
    ("lacs", 0): [["États-Unis", "États-Unis et Canada"], ["France", "Suisse et France"]],
    ("os", 0): [["la mâchoire", "le crâne", "l'oreille"]],
    ("seismes", 1): [["La magnitude", "L'échelle de Richter"]],
}


def ajouter_recouvrements():
    par_id = {f["id"]: f for f in FICHES}
    for (fid, n), groupes in RECOUVREMENTS.items():
        relation = par_id[fid]["relations"][n]
        ys = {p[1] for p in relation["paires"]}
        for g in groupes:
            assert set(g) <= ys, (fid, n, set(g) - ys)
        relation["recouvrements"] = groupes


def recouvrent(relation, a, b):
    return a == b or any(a in g and b in g for g in relation.get("recouvrements", []))


def sources_verifiees():
    """Sources des faits vérifiés dans verification/faits.csv : {(fiche, fait): url}."""
    import csv
    import re
    chemin = os.path.join(os.path.dirname(__file__), "..", "verification", "faits.csv")
    if not os.path.exists(chemin):
        return {}
    trouvees = {}
    for ligne in csv.DictReader(open(chemin, encoding="utf-8")):
        url = re.search(r"https://\S+", ligne["source"])
        if ligne["statut"] in ("vérifié", "corrigé") and url:
            trouvees[(ligne["theme"], ligne["fait"])] = url.group(0).rstrip("),;")
    return trouvees


def ajouter_sources_verifiees():
    """Reporte dans les fiches les sources trouvées lors de la vérification."""
    trouvees = sources_verifiees()
    for f in FICHES:
        for r in f["relations"]:
            for p in r["paires"]:
                cle = trouvees.get((f["id"], r["modele"].replace("{x}", p[0]))) or trouvees.get((f["id"], p[0]))
                if cle and len(p) == 3:
                    p.append(cle)
        for qq in f["questions"]:
            cle = trouvees.get((f["id"], qq["enonce"]))
            if cle and "source" not in qq:
                qq["source"] = cle


def sans_source(fiche):
    """Nombre de paires et de questions sans source."""
    n = sum(1 for r in fiche["relations"] for p in r["paires"] if len(p) < 4 or not p[3].startswith("https://"))
    return n + sum(1 for qq in fiche["questions"] if not qq.get("source", "").startswith("https://"))


def fusionner_ajouts():
    """Ajoute aux fiches les relations et questions des fichiers ajouts_*.py."""
    par_id = {f["id"]: f for f in FICHES}
    import vague2
    import vague3
    import vague4
    import vague5
    import vague6
    import vague7
    for vague in (vague2, vague3, vague4, vague5, vague6, vague7):
        for module in vague.modules():
            FICHES.append(module.FICHE)
    for ajouts in (AJOUTS_VIVANT, AJOUTS_CORPS_TERRE_ARTS):
        for id_fiche, contenu in ajouts.items():
            if id_fiche not in par_id:
                par_id[id_fiche] = {"id": id_fiche, "relations": [], "questions": []}
                FICHES.append(par_id[id_fiche])
            par_id[id_fiche]["relations"].extend(contenu["relations"])
            par_id[id_fiche]["questions"].extend(contenu["questions"])


if __name__ == "__main__":
    fusionner_ajouts()
    ajouter_recouvrements()
    for f in FICHES:
        ajouter_contextes(f)
    ajouter_sources_verifiees()
    ok = True
    a_sourcer = 0
    for f in FICHES:
        total, erreurs = verifier(f)
        minimum = MINIMUM - COMPLEMENTS.get(f["id"], 0)
        if total < minimum:
            erreurs.append(f"{total} questions, il en faut au moins {minimum}")
        enonces = [qq["enonce"] for qq in f["questions"]]
        for e in sorted({e for e in enonces if enonces.count(e) > 1}):
            erreurs.append(f"question en double : « {e} »")
        manque = sans_source(f)
        if f["id"] in FICHES_ANTERIEURES:
            a_sourcer += manque
        elif manque:
            erreurs.append(f"{manque} paires ou questions sans source : chaque fait d'une nouvelle fiche "
                           "doit avoir l'URL https de la source consultée pour le vérifier")
        print(f"{f['id']:22} {total:3} questions, {manque:3} sans source")
        for e in erreurs:
            ok = False
            print("   ERREUR :", e)
    ids = [f["id"] for f in FICHES]
    assert len(ids) == len(set(ids)), "identifiants en double"
    sortie = os.path.join(os.path.dirname(__file__), "..", "CultureFight.swiftpm", "Resources", "fiches.json")
    with open(sortie, "w", encoding="utf-8") as fh:
        json.dump(FICHES, fh, ensure_ascii=False, indent=1)
    print(f"{len(FICHES)} fiches écrites dans Resources/fiches.json")
    print(f"Fiches antérieures à la règle des sources : {a_sourcer} faits encore sans source "
          "(voir verification/faits.csv)")
    sys.exit(0 if ok else 1)
