import Foundation

/// Note de difficulté d'une spécialité, estimée sur toutes ses questions (game design, « Stats selon le style
/// et la spécialité ») : elle fixe la taille du budget de stats.
enum NoteSpecialite: String, Codable, Sendable, CaseIterable {
    case facile = "Facile"
    case moyenne = "Moyenne"
    case pointue = "Pointue"

    var picto: String {
        switch self {
        case .facile: return "🛡️"
        case .moyenne: return "⚖️"
        case .pointue: return "💥"
        }
    }

    var explication: String {
        switch self {
        case .facile:
            return "Spécialité facile : l'adversaire répond souvent juste et esquive, donc un budget de stats plus gros."
        case .moyenne:
            return "Spécialité de difficulté moyenne : budget de référence."
        case .pointue:
            return "Spécialité pointue : l'adversaire rate souvent, donc un budget de stats plus petit."
        }
    }
}

/// Niveau d'une stat dans la répartition d'une famille de styles.
enum NiveauStat: String, Codable, Sendable {
    case haute = "Haute", moyenne = "Moyenne", basse = "Basse"

    var valeur: Double {
        switch self {
        case .haute: return 1
        case .moyenne: return 0
        case .basse: return -1
        }
    }
}

/// Stats de base selon la rareté, la note de la spécialité (budget) et la famille de styles (répartition),
/// d'après `Resources/profils.json`, dont les valeurs viennent de `outils/simulation.py`.
/// Même calcul que la fonction `stats` du script.
enum ProfilStats {
    struct Prix: Decodable, Sendable { let pv: Double; let attaque: Double; let defense: Double }
    struct Parts: Decodable, Sendable { let pv: Double; let attaque: Double; let defense: Double }

    struct Fichier: Decodable, Sendable {
        let budgets: [String: [String: Double]]
        let prix: Prix
        let parts: Parts
        let ecart: Double
        let plafondDefense: Double
        let synergie: Double
        let bouclierChevaliers: Int
        let secondesCreatures: Double
        /// Riposte : bonus de la prochaine attaque après une bonne réponse Éclair, puis Rapide.
        let riposte: [Double]?
        /// Bouclier de vitesse : part des dégâts de la prochaine erreur retirée, Éclair puis Rapide.
        let bouclierVitesse: [Double]?
        /// Attaque, Défense, PV.
        let repartition: [String: [NiveauStat]]
        let notes: [String: NoteSpecialite]
    }

    struct Stats: Sendable, Equatable { let pv: Int; let attaque: Int; let defense: Int }

    static let fichier: Fichier? = {
        guard let url = Bundle.module.url(forResource: "profils", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Fichier.self, from: data)
    }()

    /// Multiplicateur de la synergie (3 combattants de la même famille) sur le bonus de famille.
    static var synergie: Double { fichier?.synergie ?? 1.5 }
    static var bouclierChevaliers: Int { fichier?.bouclierChevaliers ?? 10 }
    static var secondesCreatures: Double { fichier?.secondesCreatures ?? 2 }

    static var riposte: (eclair: Double, rapide: Double) {
        let r = fichier?.riposte ?? [0.5, 0.25]
        return (r.first ?? 0.5, r.count > 1 ? r[1] : 0.25)
    }

    static var bouclierVitesse: (eclair: Double, rapide: Double) {
        let b = fichier?.bouclierVitesse ?? [0.2, 0.1]
        return (b.first ?? 0.2, b.count > 1 ? b[1] : 0.1)
    }

    static func note(_ id: String) -> NoteSpecialite { fichier?.notes[id] ?? .moyenne }

    static func budget(_ rarete: Rarete, _ note: NoteSpecialite) -> Double? {
        fichier?.budgets[rarete.rawValue]?[note.rawValue]
    }

    static func repartition(_ famille: FamilleStyle) -> [NiveauStat] {
        fichier?.repartition[famille.rawValue] ?? [.moyenne, .moyenne, .moyenne]
    }

    private static func arrondi(_ x: Double) -> Int { Int((x + 0.5).rounded(.down)) }

    static func stats(_ rarete: Rarete, _ note: NoteSpecialite, _ famille: FamilleStyle) -> Stats? {
        guard let f = fichier, let budget = budget(rarete, note) else { return nil }
        let r = repartition(famille)
        let niveaux = (attaque: r[0].valeur, defense: r[1].valeur, pv: r[2].valeur)
        let ref = (pv: budget * f.parts.pv / f.prix.pv,
                   attaque: budget * f.parts.attaque / f.prix.attaque,
                   defense: budget * f.parts.defense / f.prix.defense)
        let poids = (pv: f.parts.pv * (1 + f.ecart * niveaux.pv),
                     attaque: f.parts.attaque * (1 + f.ecart * niveaux.attaque),
                     defense: f.parts.defense * (1 + f.ecart * niveaux.defense))
        let total = poids.pv + poids.attaque + poids.defense
        func borne(_ v: Double, _ reference: Double) -> Double {
            min(reference * (1 + f.ecart), max(reference * (1 - f.ecart), v))
        }
        let attaque = borne(budget * poids.attaque / total / f.prix.attaque, ref.attaque)
        let defense = min(f.plafondDefense, borne(budget * poids.defense / total / f.prix.defense, ref.defense))
        let pv = borne(budget - f.prix.attaque * attaque - f.prix.defense * defense, ref.pv)
        return Stats(pv: arrondi(pv), attaque: arrondi(attaque), defense: arrondi(defense))
    }

    /// Stats d'un combattant équilibré (toutes les stats « Moyenne »), pour situer les prix.
    static func reference(_ rarete: Rarete) -> Stats? { stats(rarete, .moyenne, .artsMartiaux) }

    /// Le combattant avec les stats de base de sa famille et de sa note (inchangé si la rareté n'a pas de budget).
    static func appliquer(_ m: ModeleCombattant) -> ModeleCombattant {
        guard let s = stats(m.rarete, note(m.id), m.familleStyle) else { return m }
        return ModeleCombattant(id: m.id, nom: m.nom, style: m.style, familleStyle: m.familleStyle,
                                specialite: m.specialite, rarete: m.rarete,
                                pvMax: s.pv, attaque: s.attaque, defense: s.defense, difficulte: m.difficulte,
                                apparence: m.apparence, questions: m.questions, generateur: m.generateur)
    }
}

extension ModeleCombattant {
    var note: NoteSpecialite { ProfilStats.note(id) }
}
