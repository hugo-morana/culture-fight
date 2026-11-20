import Foundation

/// Calcul mental (Multiplicator, Divisator) : questions générées à l'infini, sans données.
struct GenerateurCalcul: GenerateurQuestions {
    enum Operation: Sendable {
        case multiplication, division
    }

    let specialite: Specialite
    let operation: Operation

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        tirerNouvelle(exclues: exclues) { tirer(difficulte) }
    }

    private func operandes(_ difficulte: Int) -> (Int, Int) {
        switch difficulte {
        // Au moins 60 opérations différentes à chaque difficulté.
        case ...1: return (Int.random(in: 2...10), Int.random(in: 2...10))   // 81 : les tables
        case 2: return (Int.random(in: 6...12), Int.random(in: 3...12))      // 70
        default: return (Int.random(in: 11...19), Int.random(in: 3...9))     // 63
        }
    }

    private func tirer(_ difficulte: Int) -> Question {
        let (a, b) = operandes(difficulte)
        let produit = a * b
        switch operation {
        case .multiplication:
            let faux = [produit + a, produit - a, produit + b, produit - b,
                        (a + 1) * b, a * (b + 1), produit + 10, produit - 10]
                .filter { $0 > 0 }
                .shuffled()
            return .qcm(id: "mul-\(a)x\(b)",
                        specialite: specialite,
                        enonce: "\(a) × \(b) = ?",
                        bonne: String(produit),
                        distracteurs: faux.map { String($0) },
                        difficulte: difficulte,
                        explication: "\(a) × \(b) = \(produit).")
        case .division:
            let faux = [b + 1, b - 1, b + 2, b - 2, a, b + 10]
                .filter { $0 > 0 && $0 != b }
                .shuffled()
            return .qcm(id: "div-\(produit):\(a)",
                        specialite: specialite,
                        enonce: "\(produit) ÷ \(a) = ?",
                        bonne: String(b),
                        distracteurs: faux.map { String($0) },
                        difficulte: difficulte,
                        explication: "\(produit) ÷ \(a) = \(b), car \(a) × \(b) = \(produit).")
        }
    }
}
