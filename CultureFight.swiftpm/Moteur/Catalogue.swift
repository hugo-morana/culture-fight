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
    static let capitalesAfrique = Specialite(id: "capitales-afrique", nom: "Capitales d'Afrique",
                                             famille: "Capitales", domaine: "Monde")

    // MARK: - Combattants du prototype

    static let prototype: [ModeleCombattant] = [
        ModeleCombattant(
            id: "multiplicator", nom: "Multiplicator", style: "Gladiateur",
            specialite: multiplications, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 1,
            apparence: "Gladiateur imposant au casque en forme de ×, armure couverte des tables de multiplication.",
            questions: "Multiplications : tables de 2 à 10, jusqu'à 19 × 9 en difficulté élevée.",
            generateur: GenerateurCalcul(specialite: multiplications, operation: .multiplication)),
        ModeleCombattant(
            id: "divisator", nom: "Divisator", style: "Gladiateur",
            specialite: divisions, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 2,
            apparence: "Gladiateur filiforme au casque en forme de ÷, bouclier découpé en fractions.",
            questions: "Divisions exactes, l'inverse des tables de multiplication.",
            generateur: GenerateurCalcul(specialite: divisions, operation: .division)),
        ModeleCombattant(
            id: "neonja", nom: "Néonja", style: "Ninja",
            specialite: gazNobles, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 1,
            apparence: "Ninja en combinaison noire parcourue de tubes de néon, shurikens en verre lumineux.",
            questions: "Les 7 gaz nobles (hélium, néon, argon…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: gazNobles,
                                           selection: elements.filter { $0.famille == "gaz noble" },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "mendeleviking", nom: "Mendéléviking", style: "Viking",
            specialite: symboles, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Viking à barbe rousse, casque à cornes en éprouvettes, bouclier peint du tableau périodique.",
            questions: "Les symboles des 118 éléments : retrouver le nom ou le symbole.",
            generateur: GenerateurElements(specialite: symboles,
                                           selection: elements,
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom])),
        ModeleCombattant(
            id: "iodiateur", nom: "Iodiateur", style: "Gladiateur",
            specialite: halogenes, rarete: .commun,
            pvMax: 100, attaque: 50, defense: 0, difficulte: 2,
            apparence: "Gladiateur trapu en armure brun-violet, trident à trois pointes F, Cl et I.",
            questions: "Les 6 halogènes (fluor, chlore, brome, iode…) : nom, symbole et numéro atomique.",
            generateur: GenerateurElements(specialite: halogenes,
                                           selection: elements.filter { $0.famille == "halogène" },
                                           tous: elements,
                                           formes: [.nomDuSymbole, .symboleDuNom, .numeroAtomique])),
        ModeleCombattant(
            id: "afrodecapitator", nom: "Afrodecapitator", style: "Bourreau",
            specialite: capitalesAfrique, rarete: .rare,
            pvMax: 110, attaque: 54, defense: 4, difficulte: 2,
            apparence: "Bourreau colossal à cagoule noire, hache en forme d'Afrique, afro qui dépasse.",
            questions: "Les 54 pays d'Afrique : retrouver la capitale ou le pays.",
            generateur: GenerateurCapitales(specialite: capitalesAfrique, pays: paysAfrique)),
    ]
}
