import Foundation

/// L'adversaire contrôlé par l'app.
struct IAAdverse: Sendable {
    enum Niveau: String, CaseIterable, Identifiable, Sendable {
        case facile = "Facile"
        case moyen = "Moyen"
        case difficile = "Difficile"

        var id: String { rawValue }

        /// Chance de bonne réponse en difficulté 1, sans affinité.
        var tauxBase: Double {
            switch self {
            case .facile: return 0.65
            case .moyen: return 0.8
            case .difficile: return 0.92
            }
        }
    }

    let niveau: Niveau

    /// Index choisi par l'IA. Perd 10 points de réussite par niveau de difficulté.
    func repondre(question: Question, affinite: Affinite, retires: Set<Int>) -> Int {
        var chance = niveau.tauxBase - 0.1 * Double(question.difficulte - 1)
        switch affinite {
        case .specialite: chance += 0.15
        case .famille: chance += 0.08
        case .domaine: chance += 0.04
        case .aucune: break
        }
        chance = min(0.98, max(0.15, chance))
        if Double.random(in: 0..<1) < chance { return question.bonneReponse }
        let fausses = question.choix.indices.filter { $0 != question.bonneReponse && !retires.contains($0) }
        return fausses.randomElement() ?? question.bonneReponse
    }

    /// Temps de réflexion affiché, en secondes.
    func delaiReponse() -> Double {
        Double.random(in: 2.0...6.0)
    }

    func choisirEquipe(parmi catalogue: [ModeleCombattant]) -> [ModeleCombattant] {
        Array(catalogue.shuffled().prefix(Regles.tailleEquipe))
    }
}
