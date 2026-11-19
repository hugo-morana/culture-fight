import Foundation

/// Conversions d'unités (Conversorcier) : questions générées à l'infini, sans données.
struct GenerateurConversions: GenerateurQuestions {
    /// Une conversion : 1 `grande` = `facteur` `petite`.
    struct Conversion: Sendable {
        let grande: String
        let petite: String
        let facteur: Double
    }

    static let conversions: [Conversion] = [
        Conversion(grande: "km", petite: "m", facteur: 1000),
        Conversion(grande: "m", petite: "cm", facteur: 100),
        Conversion(grande: "cm", petite: "mm", facteur: 10),
        Conversion(grande: "kg", petite: "g", facteur: 1000),
        Conversion(grande: "t", petite: "kg", facteur: 1000),
        Conversion(grande: "g", petite: "mg", facteur: 1000),
        Conversion(grande: "L", petite: "mL", facteur: 1000),
        Conversion(grande: "L", petite: "cL", facteur: 100),
        Conversion(grande: "m³", petite: "L", facteur: 1000),
        Conversion(grande: "h", petite: "min", facteur: 60),
        Conversion(grande: "min", petite: "s", facteur: 60),
        Conversion(grande: "h", petite: "s", facteur: 3600),
        Conversion(grande: "jour", petite: "h", facteur: 24),
    ]

    let specialite: Specialite

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        tirerNouvelle(exclues: exclues) { tirer(difficulte) }
    }

    private static let format: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 3
        return f
    }()

    private func texte(_ x: Double) -> String {
        Self.format.string(from: NSNumber(value: x)) ?? String(x)
    }

    private func tirer(_ difficulte: Int) -> Question {
        let c = Self.conversions.randomElement() ?? Self.conversions[0]
        // Difficulté 1-2 : de la grande unité vers la petite. Difficulté 3+ : l'inverse, avec des décimales.
        let versPetite = difficulte <= 2
        let depart: Double
        let reponse: Double
        let enonce: String
        if versPetite {
            depart = Double(difficulte <= 1 ? Int.random(in: 1...9) : Int.random(in: 2...25))
            reponse = depart * c.facteur
            enonce = "\(texte(depart)) \(c.grande) = ? \(c.petite)"
        } else {
            reponse = Double(Int.random(in: 11...99)) / 10
            depart = reponse * c.facteur
            enonce = "\(texte(depart)) \(c.petite) = ? \(c.grande)"
        }
        let faux = [reponse * 10, reponse / 10, reponse * 100, reponse / 100, reponse * 2]
            .filter { $0 != reponse && $0 > 0 }
            .shuffled()
            .map { texte($0) }
        let unite = versPetite ? c.petite : c.grande
        return .qcm(id: "conv-\(texte(depart))\(versPetite ? c.grande : c.petite)",
                    specialite: specialite,
                    enonce: enonce,
                    bonne: texte(reponse),
                    distracteurs: faux,
                    difficulte: difficulte,
                    explication: "1 \(c.grande) = \(texte(c.facteur)) \(c.petite), donc la réponse est \(texte(reponse)) \(unite).")
    }
}
