import Foundation
import SwiftData

/// Une réponse donnée par le joueur pendant un combat, gardée pour les statistiques du profil.
struct ReponseJouee: Codable, Hashable, Sendable {
    var domaine: String
    var famille: String
    var specialite: String
    var specialiteID: String
    var correct: Bool
    var secondes: Double
    var tempsEcoule: Bool
    var difficulte: Int
    /// Rang de la question parmi celles auxquelles le joueur a répondu dans ce combat (1, 2, 3…).
    var rang: Int
}

/// Une partie terminée (ou abandonnée), sauvegardée pour les statistiques façon Chess.com.
@Model
final class PartieJouee {
    var date: Date = Date()
    /// 0 victoire, 1 défaite, 2 nul, 3 abandon.
    var resultat: Int = 0
    var niveauIA: String = ""
    var equipe: [String] = []
    var reponses: [ReponseJouee] = []

    init(date: Date = Date(), resultat: Int, niveauIA: String, equipe: [String], reponses: [ReponseJouee]) {
        self.date = date
        self.resultat = resultat
        self.niveauIA = niveauIA
        self.equipe = equipe
        self.reponses = reponses
    }

    var estVictoire: Bool { resultat == 0 }
    var estDefaite: Bool { resultat == 1 || resultat == 3 }
    var estNul: Bool { resultat == 2 }

    /// Pourcentage de bonnes réponses du joueur dans cette partie, nil s'il n'a répondu à rien.
    var precision: Double? {
        guard !reponses.isEmpty else { return nil }
        return Double(reponses.filter(\.correct).count) / Double(reponses.count) * 100
    }
}

extension CombatController {
    /// La partie à sauvegarder. `abandon` force le résultat « abandon ».
    func partieJouee(abandon: Bool = false) -> PartieJouee {
        let resultat: Int
        if abandon { resultat = 3 } else {
            switch combat.vainqueur {
            case 0?: resultat = 0
            case 1?: resultat = 1
            default: resultat = 2
            }
        }
        return PartieJouee(resultat: resultat, niveauIA: ia.niveau.rawValue,
                           equipe: combat.camps[0].combattants.map(\.modele.id),
                           reponses: reponsesJoueur)
    }
}
