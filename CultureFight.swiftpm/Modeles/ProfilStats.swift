import Foundation

/// Note de difficulté d'une spécialité, estimée sur toutes ses questions (game design, « Profil de stats »).
enum NoteSpecialite: String, Codable, Sendable, CaseIterable {
    case facile = "Facile"
    case moyenne = "Moyenne"
    case pointue = "Pointue"

    /// Profil de stats qui compense la note : une spécialité facile fait rarement rater l'adversaire.
    var profil: String {
        switch self {
        case .facile: return "Tank"
        case .moyenne: return "Équilibré"
        case .pointue: return "Canon de verre"
        }
    }

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
            return "Spécialité facile : l'adversaire répond souvent juste et contre-attaque. Plus de PV, d'Attaque et de Défense pour compenser."
        case .moyenne:
            return "Spécialité de difficulté moyenne : répartition de référence."
        case .pointue:
            return "Spécialité pointue : l'adversaire rate souvent. Moins de PV et d'Attaque, ses questions font le travail."
        }
    }
}

/// Stats de base par rareté et par note, et note de chaque combattant (`Resources/profils.json`).
/// Les valeurs viennent de `outils/simulation.py` : à rareté égale, chaque profil gagne autour de 50 %.
enum ProfilStats {
    struct Stats: Decodable, Sendable {
        let pv: Int
        let attaque: Int
        let defense: Int
        /// Taux de victoire simulé contre un Équilibré de même rareté, en %.
        let victoires: Int
    }

    private struct Fichier: Decodable {
        let stats: [String: [String: Stats]]
        let notes: [String: NoteSpecialite]
    }

    private static let fichier: Fichier? = {
        guard let url = Bundle.module.url(forResource: "profils", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Fichier.self, from: data)
    }()

    static func note(_ id: String) -> NoteSpecialite { fichier?.notes[id] ?? .moyenne }

    static func stats(_ rarete: Rarete, _ note: NoteSpecialite) -> Stats? {
        fichier?.stats[rarete.rawValue]?[note.rawValue]
    }

    /// Le combattant avec les stats de base de son profil (inchangé si la rareté n'a pas encore de table).
    static func appliquer(_ m: ModeleCombattant) -> ModeleCombattant {
        guard let s = stats(m.rarete, note(m.id)) else { return m }
        return ModeleCombattant(id: m.id, nom: m.nom, style: m.style, familleStyle: m.familleStyle,
                                specialite: m.specialite, rarete: m.rarete,
                                pvMax: s.pv, attaque: s.attaque, defense: s.defense, difficulte: m.difficulte,
                                apparence: m.apparence, questions: m.questions, generateur: m.generateur)
    }
}

extension ModeleCombattant {
    var note: NoteSpecialite { ProfilStats.note(id) }
}
