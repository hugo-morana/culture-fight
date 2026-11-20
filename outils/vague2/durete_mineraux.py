"""Fiche « Dureté des minéraux » (Mohsquetaire)."""
from ajouts_vivant import q, rel

MOHS = "https://en.wikipedia.org/wiki/Mohs_scale"
MOHS_FR = "https://www.techno-science.net/definition/4662.html"
MANITOBA = "https://www.edu.gov.mb.ca/m12/frpub/ped/sn/dmo_4e/annexe_pdf/reg_4_ann_03.pdf"
SCN = ("https://schools.sciencenorth.ca/sites/default/files/2018/Mine%20Evolution/"
       "MineEvo-1.E%CC%81chelle%20de%20durete%CC%81%20de%20Mohs.pdf")
FMOHS = "https://en.wikipedia.org/wiki/Friedrich_Mohs"
NHM = ("https://www.nhm-wien.ac.at/en/research/mineralogy__petrography/history/the_naturalien_cabinet/"
       "friederich_mohs")
ECLAT = "https://www.techno-science.net/fr/definitions/eclat"
LUSTRE = "https://bafybeiemxf5abjwjbikoz4mc3a3dla6ual3jsgpdr4cjr3oz3evfyavhwq.ipfs.4everland.io/wiki/Lustrous.html"
CLIVAGE = "https://www.techno-science.net/fr/definitions/clivage"
TRAIT = "https://galleries.com/minerals/property/streak.htm"
PROPRIETES = "https://pressbooks.ccconline.org/physicalgeology/chapter/2-6-mineral-properties-physical-geology-2nd-edition/"
USGS = "https://pubs.usgs.gov/gip/gemstones/mineral.html"

SOURCES_GENERALES = [
    ("Wikipédia – Mohs scale", MOHS),
    ("Techno-Science – Échelle de Mohs", MOHS_FR),
    ("Éducation Manitoba – Échelle de dureté de Mohs", MANITOBA),
    ("Wikipédia – Friedrich Mohs", FMOHS),
    ("Muséum d'histoire naturelle de Vienne – Friedrich Mohs", NHM),
    ("Techno-Science – Éclat", ECLAT),
    ("Lustre (mineralogy) (copie de Wikipédia)", LUSTRE),
    ("Techno-Science – Clivage", CLIVAGE),
    ("Amethyst Galleries – Streak", TRAIT),
    ("Physical Geology – 2.6 Mineral Properties", PROPRIETES),
]

RANGS = rel(
    "Quel est le rang de ce minéral sur l'échelle de Mohs : {x} ?", "{x} : rang {y} sur l'échelle de Mohs.",
    [("le talc", "1", "C'est le plus tendre : il s'effrite sous l'ongle.", MOHS_FR),
     ("le gypse", "2", "L'ongle suffit à le rayer.", MOHS_FR),
     ("la calcite", "3", "Une pièce de cuivre la raye.", MOHS_FR),
     ("la fluorite", "4", "Une lame de couteau la raye légèrement.", MOHS_FR),
     ("l'apatite", "5", "Une lame de couteau la raye.", MOHS_FR),
     ("l'orthose", "6", "Ce feldspath est rayé par une lime ou du sable.", MOHS_FR),
     ("le quartz", "7", "Le quartz raye le verre.", MOHS_FR),
     ("la topaze", "8", "Le carbure de tungstène la raye.", MOHS_FR),
     ("le corindon", "9", "Le carbure de silicium le raye.", MOHS_FR),
     ("le diamant", "10", "Seul un autre diamant peut le rayer.", MOHS_FR)],
    inverse="Quel minéral occupe le rang {y} sur l'échelle de Mohs ?")

FORMULES = rel(
    "Quelle est la formule chimique de ce minéral de l'échelle de Mohs : {x} ?", "{x} : {y}.",
    [("le talc", "Mg₃Si₄O₁₀(OH)₂", "Le talc est un silicate de magnésium hydraté, de système monoclinique.", MOHS_FR),
     ("le gypse", "CaSO₄·2H₂O", "Le gypse est un sulfate de calcium hydraté.", MOHS_FR),
     ("la calcite", "CaCO₃", "La calcite est un carbonate de calcium, de système rhomboédrique.", MOHS_FR),
     ("la fluorite", "CaF₂", "La fluorite est un fluorure de calcium, de système cubique.", MOHS_FR),
     ("l'apatite", "Ca₅(PO₄)₃(OH,Cl,F)", "L'apatite est un phosphate de calcium, de système hexagonal.", MOHS_FR),
     ("l'orthose", "KAlSi₃O₈", "L'orthose est un feldspath potassique, de système monoclinique.", MOHS_FR),
     ("le quartz", "SiO₂", "Le quartz est de la silice, de système hexagonal.", MOHS_FR),
     ("la topaze", "Al₂SiO₄(OH,F)₂", "La topaze contient du fluor ; elle cristallise dans le système orthorhombique.", MOHS_FR),
     ("le corindon", "Al₂O₃", "Le corindon est un oxyde d'aluminium, de système rhomboédrique.", MOHS_FR),
     ("le diamant", "C", "Le diamant est du carbone pur, de système cubique.", MOHS_FR)],
    inverse="Quel minéral de l'échelle de Mohs a pour formule {y} ?")

MATERIAUX = rel(
    "Quelle dureté approximative ce matériau a-t-il sur l'échelle de Mohs : {x} ?", "{x} : dureté d'environ {y}.",
    [("le potassium", "0,2 à 0,4", "Ce métal alcalin est plus tendre que le talc.", MOHS),
     ("le lithium", "0,5 à 0,6", "Le lithium, lui aussi métal alcalin, est à peine plus dur que le potassium.", MOHS),
     ("le plomb", "1,5", "Le plomb est à peine plus dur que le talc.", MOHS),
     ("le bois dur", "2", "Il a la dureté du gypse.", MOHS),
     ("le zinc", "2,5", "Le cuivre est un peu plus dur, de 2,5 à 3.", MOHS),
     ("le laiton", "3", "Cet alliage a la dureté de la calcite.", MOHS),
     ("le fer", "4", "L'acier ordinaire est à peine plus dur, de 4 à 4,5.", MOHS),
     ("le silicium", "6,5", "Le silicium est plus dur que l'orthose mais moins que le quartz.", MOHS),
     ("le tungstène", "7,5", "Le tungstène est plus dur que le quartz.", MOHS),
     ("le chrome", "8,5", "Le chrome est plus dur que la topaze.", MOHS)],
    inverse="Quel matériau a une dureté d'environ {y} sur l'échelle de Mohs ?")

ECLATS = rel(
    "Quel éclat présente ce minéral : {x} ?", "{x} : éclat {y}.",
    [("le zircon", "Adamantin", "L'éclat adamantin correspond à un indice de réfraction de 1,9 à 2,6.", ECLAT),
     ("la cérusite", "Adamantin", "L'éclat adamantin est le plus brillant, celui du diamant.", LUSTRE),
     ("la galène", "Métallique", "Un éclat métallique rappelle celui du métal poli.", LUSTRE),
     ("la pyrite", "Métallique", "La lumière ne traverse pas les minéraux à éclat métallique.", LUSTRE),
     ("la magnétite", "Métallique", "Les minéraux à éclat métallique sont opaques.", LUSTRE),
     ("le quartz", "Vitreux", "Environ 70 % des minéraux ont l'éclat vitreux, celui du verre.", ECLAT),
     ("la calcite", "Vitreux", "Presque tous les carbonates ont un éclat vitreux.", ECLAT),
     ("la muscovite", "Nacré", "L'éclat nacré vient de fines feuilles parallèles ; ces minéraux ont un clivage parfait.", LUSTRE),
     ("l'ambre", "Résineux", "L'ambre est lui-même une résine fossilisée.", LUSTRE),
     ("le gypse fibreux", "Soyeux", "Des fibres parallèles très fines donnent cet aspect de soie.", LUSTRE),
     ("la kaolinite", "Terreux", "Ses fines granulations diffusent la lumière dans toutes les directions.", LUSTRE),
     ("le cinabre", "Submétallique", "Son indice de réfraction est d'environ 2,9.", ECLAT)])
ECLATS["recouvrements"] = [["Adamantin", "Submétallique"], ["Métallique", "Submétallique"]]

CLIVAGES = rel(
    "Quel type de clivage présente ce minéral : {x} ?", "{x} : {y}.",
    [("la halite", "Clivage cubique", "Clivée selon trois directions, elle donne des fragments compacts.", CLIVAGE),
     ("la fluorite", "Clivage octaédrique", "Son clivage octaédrique est particulièrement net.", CLIVAGE),
     ("la biotite", "Clivage basal", "Comme les autres micas, elle se délite en feuillets.", CLIVAGE),
     ("les amphiboles", "Clivage prismatique", "Leurs cristaux se fendent en longueur.", CLIVAGE),
     ("les pyroxènes", "Clivage prismatique", "Ils se clivent surtout selon deux directions.", CLIVAGE),
     ("le quartz", "Aucun clivage net", "Le quartz présente surtout une cassure conchoïdale, en arcs lisses.", CLIVAGE)])
CLIVAGES["explication"] = "{x} : {y}."

TRAITS = rel(
    "Quelle est la couleur du trait (la poudre) de ce minéral : {x} ?", "{x} : trait {y}.",
    [("l'hématite", "Rouge sang", "Son trait est rouge même quand le minéral paraît gris.", TRAIT),
     ("la pyrite", "Noir", "Jaune laiton en cristal, l'« or des fous » laisse pourtant un trait noir.", TRAIT),
     ("l'or", "Jaune", "Le trait révèle souvent la vraie couleur d'un minéral.", TRAIT),
     ("la galène", "Gris plomb", "Son trait permet de la distinguer de l'hématite.", TRAIT)])

FICHE = {"id": "durete-mineraux", "relations": [RANGS, FORMULES, MATERIAUX, ECLATS, CLIVAGES, TRAITS],
         "questions": [
    q("En quelle année Friedrich Mohs a-t-il proposé son échelle de dureté ?", "1812", ["1666", "1789", "1905"],
      "La même année, il devient professeur au Joanneum de Graz.", source=MOHS),
    q("Quelle était la nationalité de Friedrich Mohs ?", "Allemande", ["Française", "Suédoise", "Anglaise"],
      "Il est né en 1773 à Gernrode, dans le massif du Harz.", source=FMOHS),
    q("Dans quelle académie des mines Friedrich Mohs a-t-il étudié auprès d'Abraham Gottlob Werner ?",
      "Freiberg", ["Paris", "Uppsala", "Turin"], "Il succédera plus tard à Werner comme professeur à Freiberg.",
      source=NHM),
    q("Dans quelle ville Friedrich Mohs est-il devenu professeur de minéralogie à l'université en 1826 ?", "Vienne",
      ["Berlin", "Prague", "Munich"], "Il fut aussi conservateur de la collection minéralogique impériale.", source=FMOHS),
    q("Dans quel pays Friedrich Mohs est-il mort en 1839, au cours d'un voyage ?", "En Italie",
      ["En France", "En Grèce", "En Espagne"], "Il se rendait à Agordo, alors en Lombardie-Vénétie autrichienne.",
      source=FMOHS),
    q("Selon quel critère Friedrich Mohs classait-il les minéraux ?", "Leurs propriétés physiques",
      ["Leur composition chimique", "Leur âge", "Leur lieu de découverte"],
      "Forme, clivage, dureté et densité : ce choix l'opposa à beaucoup de ses contemporains.", source=NHM),
    q("Quel minéral nommé en l'honneur de Mohs a ensuite perdu son statut d'espèce ?", "La mohsite",
      ["La mohsonite", "La fridérite", "La harzite"],
      "On l'a reconnue comme une variété de crichtonite.", source=NHM),
    q("Quel savant grec décrivait déjà, vers 300 av. J.-C., la comparaison des pierres en les rayant ?", "Théophraste",
      ["Archimède", "Euclide", "Pythagore"], "Pline l'Ancien a ensuite consigné la méthode vers l'an 77.", source=MOHS),
    q("Sur l'échelle de Mohs, que mesure la dureté ?", "La résistance à la rayure",
      ["La résistance au choc", "La densité", "La résistance à la chaleur"],
      "Un matériau peut résister aux rayures et pourtant se briser facilement.", source=MOHS),
    q("Quel type d'échelle est l'échelle de Mohs ?", "Une échelle ordinale",
      ["Une échelle linéaire", "Une échelle logarithmique", "Une échelle de températures"],
      "Elle classe les minéraux par comparaison, sans écarts réguliers entre les rangs.", source=MOHS_FR),
    q("En dureté absolue, combien de fois environ le diamant est-il plus dur que le corindon ?", "4 fois",
      ["1 fois et demie", "10 fois", "100 fois"], "Le corindon, lui, est environ deux fois plus dur que la topaze.",
      source=MOHS),
    q("Un minéral rayé par l'apatite mais pas par la fluorite a une dureté comprise entre…", "4 et 5",
      ["3 et 4", "5 et 6", "6 et 7"], "La dureté se lit d'après ce qui raye le minéral et ce qu'il raye.", source=MOHS),
    q("Quel minéral de l'échelle de Mohs l'ongle raye-t-il ?", "Le gypse", ["La calcite", "La fluorite", "Le quartz"],
      "Avec sa dureté proche de 2,2, l'ongle entame le gypse, mais reste sans effet sur la calcite.", source=MOHS_FR),
    q("Quelle dureté approximative attribue-t-on à une lame de canif en acier ?", "5,5", ["2,5", "3,5", "8"],
      "L'ongle, lui, a une dureté d'environ 2,5.", source=MANITOBA),
    q("Quelle dureté approximative attribue-t-on à une lime en acier trempé ?", "6,5", ["2,5", "4", "9,5"],
      "Les géologues l'utilisent comme outil de test, avec l'ongle et la lame de couteau.", source=PROPRIETES),
    q("Quel minéral de l'échelle de Mohs une pièce de cuivre d'un cent raye-t-elle ?", "La calcite",
      ["Le quartz", "La topaze", "L'apatite"], "Un clou, lui, raye la fluorite et l'apatite mais pas l'orthose.",
      source=SCN),
    q("Lequel de ces minéraux raye une vitre ?", "Le quartz", ["Le talc", "La calcite", "Le gypse"],
      "Le verre se laisse aussi rayer par l'orthose.", source=SCN),
    q("Quel abrasif courant est associé au corindon sur l'échelle de Mohs ?", "Le papier émeri",
      ["Le papier de verre au silex", "La pierre ponce", "La craie"],
      "Le diamant, au rang 10, est associé au papier abrasif au carborundum.", source=MANITOBA),
    q("Quelle dureté approximative a la moissanite, entre corindon et diamant ?", "9,5", ["7", "8", "10,5"],
      "Des matériaux synthétiques plus durs que le diamant sont aussi étudiés.", source=MOHS_FR),
    q("Quel minéral a une dureté de 4 dans une direction et de 8 dans une autre ?", "Le disthène (cyanite)",
      ["Le talc", "Le quartz", "Le diamant"], "Sa dureté dépend de la direction de la rayure.", source=MOHS_FR),
    q("Pourquoi la dureté du granite est-elle difficile à fixer ?", "C'est un mélange de plusieurs minéraux",
      ["Il est trop dur pour être rayé", "Il est liquide en profondeur", "Il change de dureté avec la température"],
      "Il associe par exemple quartz (7), orthose (6) et mica (2 à 4).", source=MOHS),
    q("Quelle dureté a l'émeraude sur l'échelle de Mohs ?", "7,5 à 8", ["3 à 4", "5 à 5,5", "9 à 10"],
      "Elle est donc un peu plus dure que le quartz.", source=MOHS),
    q("Quelle dureté a le saphir sur l'échelle de Mohs ?", "9", ["6", "7", "10"],
      "Le saphir est un corindon, dont il partage le rang.", source=MOHS),
    q("Quelle dureté a l'ambre sur l'échelle de Mohs ?", "2 à 2,5", ["5 à 6", "7", "8,5"],
      "Cette résine fossile est à peine plus dure que le gypse.",
      source="https://pubs.usgs.gov/gip/gemstones/organic.html"),
    q("Quelle dureté a la turquoise sur l'échelle de Mohs ?", "5 à 6", ["1 à 2", "8", "9 à 10"],
      "La turquoise est un phosphate hydraté de cuivre et d'aluminium.", source=USGS),
    q("Sur quoi frotte-t-on un minéral pour observer son trait ?", "Une plaque de porcelaine non émaillée",
      ["Une vitre", "Une feuille de papier", "Une plaque de cuivre"],
      "Le trait est la couleur de la poudre du minéral.", source=TRAIT),
    q("Pourquoi les minéraux très durs ne laissent-ils pas de trait ?", "Ils rayent la plaque de porcelaine",
      ["Ils sont toujours incolores", "Ils fondent au contact", "Ils sont magnétiques"],
      "Au-delà d'une dureté de 6,5 environ, ils laissent une poudre de porcelaine blanche.", source=TRAIT),
    q("Quelle couleur de trait laissent en général les minéraux translucides ?", "Blanc", ["Noir", "Rouge", "Vert"],
      "Leur couleur vient de traces d'éléments, invisibles dans une fine poudre.", source=TRAIT),
    q("Comment appelle-t-on l'aptitude d'un minéral à se casser selon des plans réguliers ?", "Le clivage",
      ["La cassure", "Le trait", "L'éclat"], "Ces plans suivent les liaisons les plus faibles du cristal.",
      source=CLIVAGE),
    q("Comment appelle-t-on la cassure en arcs lisses typique du quartz ?", "Conchoïdale",
      ["Fibreuse", "Cubique", "Basale"], "Ces courbes forment des arcs autour du point d'impact.", source=CLIVAGE),
    q("Comment se clive le feldspath ?", "Selon deux plans à 90°",
      ["Selon un seul plan", "Selon trois plans cubiques", "Il ne se clive pas"],
      "Le quartz, au contraire, n'a pas de clivage.", source=PROPRIETES),
    q("Lequel de ces minéraux présente un clivage excellent en lamelles fines ?", "Le graphite",
      ["Le quartz", "Le soufre", "L'apatite"], "Le gypse et la muscovite aussi se clivent en fines lamelles.",
      source=CLIVAGE),
    q("Quel terme désigne l'aspect d'un minéral selon la manière dont il renvoie la lumière ?", "L'éclat",
      ["Le trait", "Le clivage", "La dureté"], "L'éclat est en général lié à l'indice de réfraction.", source=ECLAT),
    q("Quel éclat présente le jade ?", "Cireux", ["Métallique", "Adamantin", "Soyeux"],
      "La calcédoine présente le même aspect de cire.", source=LUSTRE),
    q("Quel minéral fait effervescence dans un acide dilué ?", "La calcite", ["Le quartz", "Le talc", "La fluorite"],
      "Les bulles sont du dioxyde de carbone libéré.", source=PROPRIETES),
    q("Quel minéral est attiré par un aimant ?", "La magnétite", ["La calcite", "Le quartz", "Le gypse"],
      "Quelques autres minéraux sont faiblement magnétiques.", source=PROPRIETES),
    q("Quelle densité dépassent les minéraux métalliques comme la pyrite ?", "5 g/cm³", ["1 g/cm³", "2 g/cm³", "20 g/cm³"],
      "Le quartz, le feldspath ou la calcite sont entre 2,6 et 3,0 g/cm³.", source=PROPRIETES),
    q("Quelle forme prennent souvent les cristaux de pyrite ?", "Des cubes",
      ["Des aiguilles", "Des feuillets", "Des sphères"], "Elle forme aussi des dodécaèdres à 12 faces.", source=PROPRIETES),
    q("Quelle forme ont les cristaux de quartz ?", "Des prismes à six faces",
      ["Des cubes", "Des octaèdres", "Des feuillets"], "Ils se forment en général dans des cavités.", source=PROPRIETES),
]}
