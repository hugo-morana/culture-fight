import Foundation

/// Mélange plusieurs générateurs d'une même spécialité, par exemple les questions sur les éléments
/// (nom, symbole, numéro) et une fiche de questions de culture sur ces éléments.
struct GenerateurMixte: GenerateurQuestions {
    struct Partie: Sendable {
        let generateur: any GenerateurQuestions
        /// Nombre de questions différentes de ce générateur : il est tiré en proportion.
        let poids: Int
    }

    let parties: [Partie]

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        tirerNouvelle(exclues: exclues) {
            choisirPartie().generateur.generer(difficulte: difficulte, exclues: exclues)
        }
    }

    private func choisirPartie() -> Partie {
        let total = parties.reduce(0) { $0 + max(1, $1.poids) }
        var reste = Int.random(in: 0..<max(1, total))
        for partie in parties {
            reste -= max(1, partie.poids)
            if reste < 0 { return partie }
        }
        return parties[0]
    }
}
