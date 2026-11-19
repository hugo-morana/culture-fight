import Foundation

/// Les données embarquées et les combattants du prototype.
enum Catalogue {
    static let elements: [ElementChimique] = charger("elements")
    static let paysAfrique: [Pays] = charger("pays_afrique")

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
    ]
}
