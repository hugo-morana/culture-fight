import Foundation

/// Les données embarquées et les combattants du prototype.
enum Catalogue {
    static let elements: [ElementChimique] = charger("elements")
    static let paysAfrique: [Pays] = charger("pays_afrique")
    /// Questions des combattants « à fiche », générées par `outils/fiches.py`.
    static let fiches: [String: FicheSpecialite] = {
        let liste: [FicheSpecialite] = charger("fiches")
        return Dictionary(uniqueKeysWithValues: liste.map { ($0.id, $0) })
    }()

    /// Un combattant commun dont les questions viennent d'une fiche.
    private static func aFiche(id: String, nom: String, style: String, familleStyle: FamilleStyle,
                               specialite: String, famille: String, domaine: String, fiche: String,
                               apparence: String, questions: String) -> ModeleCombattant {
        guard let donnees = fiches[fiche] else { fatalError("Fiche « \(fiche) » introuvable dans fiches.json") }
        let spec = Specialite(id: fiche, nom: specialite, famille: famille, domaine: domaine)
        return ModeleCombattant(id: id, nom: nom, style: style, familleStyle: familleStyle,
                                specialite: spec, rarete: .commun,
                                pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
                                apparence: apparence, questions: questions,
                                generateur: GenerateurFiche(specialite: spec, fiche: donnees))
    }

    private static func charger<T: Decodable>(_ nom: String) -> [T] {
        guard let url = Bundle.module.url(forResource: nom, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let liste = try? JSONDecoder().decode([T].self, from: data) else {
            fatalError("\(nom).json introuvable ou illisible")
        }
        return liste
    }

    // MARK: - Spécialités

    static let gazNobles = Specialite(id: "gaz-nobles", nom: "Gaz nobles",
                                      famille: "Éléments chimiques", domaine: "Matière")
    static let symboles = Specialite(id: "symboles", nom: "Symboles des éléments",
                                     famille: "Éléments chimiques", domaine: "Matière")
    static let halogenes = Specialite(id: "halogenes", nom: "Halogènes",
                                      famille: "Éléments chimiques", domaine: "Matière")
    static let multiplications = Specialite(id: "multiplications", nom: "Multiplications",
                                            famille: "Calcul mental", domaine: "Savoirs")
    static let divisions = Specialite(id: "divisions", nom: "Divisions",
                                      famille: "Calcul mental", domaine: "Savoirs")
    static let metauxTransition = Specialite(id: "metaux-transition", nom: "Métaux de transition",
                                             famille: "Éléments chimiques", domaine: "Matière")
    static let radioactivite = Specialite(id: "radioactivite", nom: "Radioactivité",
                                          famille: "Atome et particules", domaine: "Matière")
    static let conversions = Specialite(id: "conversions", nom: "Conversions d'unités",
                                        famille: "Unités et mesures", domaine: "Matière")
    static let capitalesAfrique = Specialite(id: "capitales-afrique", nom: "Capitales d'Afrique",
                                             famille: "Capitales", domaine: "Monde")

    /// Numéros atomiques des métaux de transition (blocs d, hors lanthanides et actinides).
    static let numerosTransition = Set(Array(21...30) + Array(39...48) + Array(72...80) + Array(104...112))
    /// Éléments sans isotope stable : technétium, prométhium, et tous ceux à partir du polonium.
    static let numerosRadioactifs = Set([43, 61] + Array(84...118))

    // MARK: - Combattants du prototype

    static let prototype: [ModeleCombattant] = [
        ModeleCombattant(
            id: "multiplicator", nom: "Multiplicator", style: "Gladiateur", familleStyle: .guerriersLourds,
            specialite: multiplications, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 1,
            apparence: "Gladiateur imposant au casque en forme de ×, armure couverte des tables de multiplication.",
            questions: "Multiplications : tables de 2 à 10, jusqu'à 19 × 9 en difficulté élevée.",
            generateur: GenerateurCalcul(specialite: multiplications, operation: .multiplication)),
        ModeleCombattant(
            id: "divisator", nom: "Divisator", style: "Gladiateur", familleStyle: .guerriersLourds,
            specialite: divisions, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 2,
            apparence: "Gladiateur filiforme au casque en forme de ÷, bouclier découpé en fractions.",
            questions: "Divisions exactes, l'inverse des tables de multiplication.",
            generateur: GenerateurCalcul(specialite: divisions, operation: .division)),
        ModeleCombattant(
            id: "neonja", nom: "Néonja", style: "Ninja", familleStyle: .ombres,
            specialite: gazNobles, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 1,
            apparence: "Ninja en combinaison noire parcourue de tubes de néon, shurikens en verre lumineux.",
            questions: "Les 7 gaz nobles (hélium, néon, argon…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: gazNobles,
                                           selection: elements.filter { $0.famille == "gaz noble" },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "mendeleviking", nom: "Mendéléviking", style: "Viking", familleStyle: .guerriersLourds,
            specialite: symboles, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Viking à barbe rousse, casque à cornes en éprouvettes, bouclier peint du tableau périodique.",
            questions: "Les symboles des 118 éléments : retrouver le nom ou le symbole.",
            generateur: GenerateurElements(specialite: symboles,
                                           selection: elements,
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom])),
        ModeleCombattant(
            id: "iodiateur", nom: "Iodiateur", style: "Gladiateur", familleStyle: .guerriersLourds,
            specialite: halogenes, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Gladiateur trapu en armure brun-violet, trident à trois pointes F, Cl et I.",
            questions: "Les 6 halogènes (fluor, chlore, brome, iode…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: halogenes,
                                           selection: elements.filter { $0.famille == "halogène" },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "afrodecapitator", nom: "Afrodecapitator", style: "Bourreau", familleStyle: .guerriersLourds,
            specialite: capitalesAfrique, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 2,
            apparence: "Bourreau colossal à cagoule noire, hache en forme d'Afrique, afro qui dépasse.",
            questions: "Les 54 pays d'Afrique : retrouver la capitale ou le pays.",
            generateur: GenerateurCapitales(specialite: capitalesAfrique, pays: paysAfrique)),
        ModeleCombattant(
            id: "cuivrassier", nom: "Cuivrassier", style: "Cuirassier", familleStyle: .chevaliers,
            specialite: metauxTransition, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Cavalier à cuirasse de cuivre patinée de vert-de-gris, casque à crinière de fils électriques, sabre en titane.",
            questions: "Les métaux de transition (fer, cuivre, or, titane…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: metauxTransition,
                                           selection: elements.filter { numerosTransition.contains($0.numero) },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "radiomomie", nom: "Radiomomie", style: "Momie", familleStyle: .mortsVivants,
            specialite: radioactivite, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Momie aux bandelettes qui luisent d'un vert radioactif, trèfle de la radioactivité sur le torse, compteur Geiger qui crépite à la ceinture.",
            questions: "Les éléments radioactifs (uranium, plutonium, radium, polonium…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: radioactivite,
                                           selection: elements.filter { numerosRadioactifs.contains($0.numero) },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "conversorcier", nom: "Conversorcier", style: "Sorcier", familleStyle: .mages,
            specialite: conversions, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 1,
            apparence: "Vieux sorcier en robe bleu nuit couverte de pouces, de litres et de degrés, bâton terminé par un cadran de balance, chapeau en verre doseur.",
            questions: "Conversions d'unités : longueurs, masses, volumes et durées (km, kg, L, h…).",
            generateur: GenerateurConversions(specialite: conversions)),

        // Combattants à fiche (illustrations fournies)
        aFiche(id: "orquebusier", nom: "Orquebusier", style: "Arquebusier", familleStyle: .tireurs,
               specialite: "Cétacés", famille: "Mammifères", domaine: "Vivant", fiche: "cetaces",
               apparence: "Orque noir et blanc en armure de conquistador, arquebuse qui crache des jets d'eau, chapelet de coquillages.",
               questions: "Baleines, dauphins et autres cétacés : les reconnaître et leurs particularités."),
        aFiche(id: "druiderable", nom: "Druidérable", style: "Druide", familleStyle: .mages,
               specialite: "Arbres d'Europe", famille: "Arbres", domaine: "Vivant", fiche: "arbres",
               apparence: "Druide celte à la barbe de mousse et aux cheveux en feuilles d'érable, bâton couronné d'un gland lumineux, écureuil sur l'épaule.",
               questions: "Arbres d'Europe : leurs fruits, leur écorce et leurs particularités."),
        aFiche(id: "escrimarguerite", nom: "Escrimarguerite", style: "Escrimeur", familleStyle: .bretteurs,
               specialite: "Fleurs", famille: "Fleurs et plantes", domaine: "Vivant", fiche: "fleurs",
               apparence: "Escrimeuse en tenue blanche, masque orné de pétales de marguerite, épée en tige de fleur.",
               questions: "Fleurs et plantes : symboles, traditions et usages."),
        aFiche(id: "champignomancien", nom: "Champignomancien", style: "Nécromancien", familleStyle: .mages,
               specialite: "Champignons", famille: "Champignons et microbes", domaine: "Vivant", fiche: "champignons",
               apparence: "Nécromancien voûté sous un chapeau d'amanite, robe couverte de spores, petits champignons zombies à sa suite.",
               questions: "Champignons : les reconnaître, comestibles ou mortels, et leurs usages."),
        aFiche(id: "zombos", nom: "Zombos", style: "Zombie", familleStyle: .mortsVivants,
               specialite: "Os du squelette", famille: "Squelette", domaine: "Corps humain", fiche: "os",
               apparence: "Zombie squelettique à moitié couvert de bandages, os étiquetés au marqueur, joue du xylophone sur ses côtes.",
               questions: "Os du squelette : où ils se trouvent, et quelques records."),
        aFiche(id: "vampirein", nom: "Vampirein", style: "Vampire", familleStyle: .mortsVivants,
               specialite: "Organes", famille: "Organes", domaine: "Corps humain", fiche: "organes",
               apparence: "Vampire élégant à cape doublée de rouge, broche en forme de rein, sacoche de médecin pleine d'organes souriants.",
               questions: "Organes du corps humain : leur rôle et leurs records."),
        aFiche(id: "rapaladin", nom: "Rapaladin", style: "Paladin", familleStyle: .chevaliers,
               specialite: "Rapaces", famille: "Oiseaux", domaine: "Vivant", fiche: "rapaces",
               apparence: "Paladin à tête d'aigle royal, armure blanche et dorée aux plumes de métal, bouclier en forme de plume.",
               questions: "Rapaces de jour et de nuit : les reconnaître."),
        aFiche(id: "jaguerrier", nom: "Jaguerrier", style: "Guerrier", familleStyle: .guerriersLourds,
               specialite: "Félins", famille: "Mammifères", domaine: "Vivant", fiche: "felins",
               apparence: "Guerrier jaguar aztèque, coiffe en tête de jaguar, plastron de jade, épée d'obsidienne.",
               questions: "Félins sauvages : les reconnaître, et leurs records."),
        aFiche(id: "gorillero", nom: "Gorillero", style: "Guérillero", familleStyle: .soldats,
               specialite: "Primates", famille: "Mammifères", domaine: "Vivant", fiche: "primates",
               apparence: "Gorille en treillis et béret étoilé, lunettes d'intellectuel, livres en bandoulière et bananes en guise de grenades.",
               questions: "Singes et lémuriens : les reconnaître, et les grandes primatologues."),
        aFiche(id: "mante-shaolin", nom: "Mante Shaolin", style: "Moine shaolin", familleStyle: .artsMartiaux,
               specialite: "Insectes", famille: "Insectes et arachnides", domaine: "Vivant", fiche: "insectes",
               apparence: "Mante religieuse géante en robe orange de moine shaolin, chapelet de scarabées, posture de kung-fu.",
               questions: "Insectes : anatomie, métamorphoses et records."),
        aFiche(id: "crocodojo", nom: "Crocodojo", style: "Karatéka", familleStyle: .artsMartiaux,
               specialite: "Reptiles", famille: "Reptiles et amphibiens", domaine: "Vivant", fiche: "reptiles",
               apparence: "Crocodile en karatégi blanc et ceinture noire, bandeau rouge, l'œil mi-clos d'un vieux maître.",
               questions: "Reptiles : serpents, lézards, tortues et crocodiliens."),
        aFiche(id: "da-vincible", nom: "Da Vincible", style: "Champion", familleStyle: .guerriersLourds,
               specialite: "Peintres de la Renaissance", famille: "Peinture", domaine: "Arts", fiche: "peintres-renaissance",
               apparence: "Champion en armure à engrenages, ailes mécaniques de la Renaissance, bouclier au sourire énigmatique.",
               questions: "Peintres de la Renaissance : qui a peint quoi, et leur époque."),
        aFiche(id: "boxeps", nom: "Boxeps", style: "Boxeur", familleStyle: .artsMartiaux,
               specialite: "Muscles", famille: "Muscles", domaine: "Corps humain", fiche: "muscles",
               apparence: "Boxeur aux biceps démesurés, gants marqués BI et TRI, muscles annotés comme une planche d'anatomie.",
               questions: "Muscles : où ils se trouvent et à quoi ils servent."),
        aFiche(id: "judocus", nom: "Judocus", style: "Judoka", familleStyle: .artsMartiaux,
               specialite: "Dinosaures", famille: "Animaux préhistoriques", domaine: "Vivant", fiche: "dinosaures",
               apparence: "Diplodocus en kimono de judo trop court, ceinture noire, médailles en fossiles.",
               questions: "Dinosaures et reptiles préhistoriques : les reconnaître, et leur disparition."),
        aFiche(id: "mesozouave", nom: "Mésozouave", style: "Zouave", familleStyle: .soldats,
               specialite: "Ères géologiques", famille: "Animaux préhistoriques", domaine: "Vivant", fiche: "eres-geologiques",
               apparence: "Zouave en pantalon bouffant rouge, fusil en os de dinosaure, gourde d'ambre avec un moustique dedans.",
               questions: "Ères et périodes géologiques : leur ordre, et ce qui s'y est passé."),
        aFiche(id: "golemagma", nom: "Golemagma", style: "Golem", familleStyle: .creatures,
               specialite: "Volcans actifs", famille: "Volcans", domaine: "Terre", fiche: "volcans",
               apparence: "Golem de basalte noir dont les fissures laissent voir la lave, tête en petit volcan qui crache des étincelles.",
               questions: "Volcans actifs : où ils se trouvent, et les grandes éruptions."),
        aFiche(id: "sismogre", nom: "Sismogre", style: "Ogre", familleStyle: .creatures,
               specialite: "Grands séismes", famille: "Séismes et tectonique", domaine: "Terre", fiche: "seismes",
               apparence: "Ogre à la peau de roche, sismographe autour du ventre, massue taillée dans une plaque tectonique.",
               questions: "Grands séismes : quand et où, et comment on les mesure."),
        aFiche(id: "seinturion", nom: "Seinturion", style: "Centurion", familleStyle: .soldats,
               specialite: "Fleuves d'Europe", famille: "Fleuves", domaine: "Terre", fiche: "fleuves-europe",
               apparence: "Centurion à l'armure ruisselante, casque à cimier en forme de vague, bouclier gravé de la carte des fleuves d'Europe.",
               questions: "Fleuves d'Europe : les villes qu'ils traversent et les mers où ils se jettent."),
    ]
}
