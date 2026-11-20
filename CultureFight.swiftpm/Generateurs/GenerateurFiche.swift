import Foundation

/// Les questions d'une spécialité, décrites dans `Resources/fiches.json`.
///
/// - Une **relation** associe des paires (x, y), par exemple (volcan, pays). Elle donne une question
///   « x → y » et, si `inverse` est rempli, une question « y → x ». Les mauvaises réponses sont les
///   autres valeurs de la même relation.
/// - Une **question fixe** a sa bonne réponse et ses mauvaises réponses écrites à la main.
struct FicheSpecialite: Decodable, Sendable {
    struct Relation: Decodable, Sendable {
        /// Énoncé, avec `{x}` à remplacer.
        let modele: String
        /// Énoncé de la question inverse, avec `{y}`, ou nil.
        let inverse: String?
        /// Explication affichée après la réponse, avec `{x}` et `{y}`.
        let explication: String
        /// [x, y, contexte] : le contexte est ajouté à l'explication.
        let paires: [[String]]
    }

    struct QuestionFixe: Decodable, Sendable {
        let enonce: String
        let bonne: String
        let faux: [String]
        let explication: String
    }

    let id: String
    let relations: [Relation]
    let questions: [QuestionFixe]

    /// Nombre de questions différentes que la fiche peut produire.
    var nombreDeQuestions: Int {
        questions.count + relations.reduce(0) { $0 + $1.paires.count * ($1.inverse == nil ? 1 : 2) }
    }
}

struct GenerateurFiche: GenerateurQuestions {
    let specialite: Specialite
    let fiche: FicheSpecialite

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        tirerNouvelle(exclues: exclues) { tirer(difficulte) }
    }

    /// Tire une question au hasard parmi toutes celles de la fiche, chacune avec la même chance.
    private func tirer(_ difficulte: Int) -> Question {
        var reste = Int.random(in: 0..<max(1, fiche.nombreDeQuestions))
        if reste < fiche.questions.count {
            let q = fiche.questions[reste]
            return .qcm(id: "\(fiche.id)-q\(reste)",
                        specialite: specialite,
                        enonce: q.enonce,
                        bonne: q.bonne,
                        distracteurs: q.faux.shuffled(),
                        difficulte: difficulte,
                        explication: q.explication)
        }
        reste -= fiche.questions.count
        for (r, relation) in fiche.relations.enumerated() {
            let n = relation.paires.count
            if reste < n {
                return question(relation, numero: r, paire: reste, inverse: false, difficulte: difficulte)
            }
            reste -= n
            if relation.inverse != nil {
                if reste < n {
                    return question(relation, numero: r, paire: reste, inverse: true, difficulte: difficulte)
                }
                reste -= n
            }
        }
        // Fiche vide : ne devrait pas arriver.
        return .qcm(id: "\(fiche.id)-vide", specialite: specialite, enonce: "?", bonne: "?",
                    distracteurs: [], difficulte: difficulte, explication: "")
    }

    private func question(_ relation: FicheSpecialite.Relation, numero: Int, paire i: Int,
                          inverse: Bool, difficulte: Int) -> Question {
        let x = relation.paires[i][0], y = relation.paires[i][1]
        var explication = relation.explication
            .replacingOccurrences(of: "{x}", with: x)
            .replacingOccurrences(of: "{y}", with: y)
        // 3e élément de la paire : une ligne de contexte propre à cette paire.
        if relation.paires[i].count > 2, !relation.paires[i][2].isEmpty {
            explication += " " + relation.paires[i][2]
        }
        if inverse, let modele = relation.inverse {
            // Les autres x, sauf ceux qui partagent le même y (ils seraient aussi de bonnes réponses).
            let faux = relation.paires.filter { $0[1] != y }.map { $0[0] }.shuffled()
            return .qcm(id: "\(fiche.id)-r\(numero)-\(i)-i",
                        specialite: specialite,
                        enonce: modele.replacingOccurrences(of: "{y}", with: y),
                        bonne: x,
                        distracteurs: faux,
                        difficulte: difficulte,
                        explication: explication)
        }
        let faux = relation.paires.map { $0[1] }.filter { $0 != y }.shuffled()
        return .qcm(id: "\(fiche.id)-r\(numero)-\(i)",
                    specialite: specialite,
                    enonce: relation.modele.replacingOccurrences(of: "{x}", with: x),
                    bonne: y,
                    distracteurs: faux,
                    difficulte: difficulte,
                    explication: explication)
    }
}
