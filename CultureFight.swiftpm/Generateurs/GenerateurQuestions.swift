import Foundation

/// Ce que sait faire chaque combattant : tirer une question de sa spécialité.
protocol GenerateurQuestions: Sendable {
    /// - Parameters:
    ///   - difficulte: 1 (facile) à 5 (expert).
    ///   - exclues: identifiants de questions déjà posées, à éviter si possible.
    func generer(difficulte: Int, exclues: Set<String>) -> Question
    /// Les données d'où viennent les questions, pour la fiche du combattant.
    var apercu: [TableauDonnees] { get }
}

extension GenerateurQuestions {
    var apercu: [TableauDonnees] { [] }

    /// Tire jusqu'à 40 questions pour en trouver une pas encore vue.
    func tirerNouvelle(exclues: Set<String>, _ tirage: () -> Question) -> Question {
        var derniere = tirage()
        if !exclues.contains(derniere.id) { return derniere }
        for _ in 0..<40 {
            derniere = tirage()
            if !exclues.contains(derniere.id) { return derniere }
        }
        return derniere
    }
}
