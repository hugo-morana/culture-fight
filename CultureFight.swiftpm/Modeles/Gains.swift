import SwiftUI

/// Tableau des gains du game design (section « Économie et boutique ») et XP des combattants
/// (section « Progression »).
enum Gains {
    static let piecesVictoire = 50
    static let piecesParKO = 5
    static let piecesDefaite = 10
    static let piecesNul = 25
    static let piecesBonneReponse = 2

    /// XP d'un combattant de l'équipe : +10 par combat terminé, +20 en cas de victoire,
    /// +5 par bonne réponse qu'il a donnée en défense.
    static let xpCombattantCombat = 10
    static let xpCombattantVictoire = 20
    static let xpCombattantBonneReponse = 5
    static let niveauMaxCombattant = 20

    /// Coffre gratuit : 20 à 60 Pièces, toutes les 4 heures.
    static let intervalleCoffre: TimeInterval = 4 * 3600
    static let coffre = 20...60

    /// XP pour passer du niveau `niveau` au suivant : 100 × niveau actuel (comme le niveau de compte).
    static func seuilCombattant(_ niveau: Int) -> Int { 100 * max(1, niveau) }

    static func prochainCoffre(apres dernier: Date?) -> Date {
        guard let dernier else { return .distantPast }
        return dernier.addingTimeInterval(intervalleCoffre)
    }
}

/// Une ligne du bilan de Pièces d'un combat.
struct LigneGain: Identifiable, Sendable {
    let libelle: String
    let pieces: Int
    var id: String { libelle }
}

/// L'XP gagnée par un combattant de l'équipe du joueur.
struct GainCombattant: Identifiable, Sendable {
    let modele: ModeleCombattant
    let bonnesReponses: Int
    let xp: Int
    var id: String { modele.id }
}

/// Ce que rapporte un combat terminé.
struct BilanCombat: Sendable {
    let lignes: [LigneGain]
    let xpCompte: Int
    let combattants: [GainCombattant]

    var pieces: Int { lignes.reduce(0) { $0 + $1.pieces } }
}

extension CombattantPossede {
    /// Ajoute de l'XP et fait monter de niveau, jusqu'au niveau 20. Renvoie le nombre de niveaux gagnés.
    @discardableResult
    func gagnerXP(_ gain: Int) -> Int {
        guard gain > 0, niveau < Gains.niveauMaxCombattant else { return 0 }
        xp += gain
        var gagnes = 0
        while niveau < Gains.niveauMaxCombattant, xp >= Gains.seuilCombattant(niveau) {
            xp -= Gains.seuilCombattant(niveau)
            niveau += 1
            gagnes += 1
        }
        if niveau >= Gains.niveauMaxCombattant { xp = 0 }
        return gagnes
    }
}
