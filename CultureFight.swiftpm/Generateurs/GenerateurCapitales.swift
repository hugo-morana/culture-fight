import Foundation

/// Un pays et sa capitale, de `Resources/pays_afrique.json`.
struct Pays: Decodable, Sendable {
    let pays: String
    let capitale: String
    /// 1 = très connu, 3 = rare.
    let notoriete: Int
    /// Ligne de contexte affichée après la réponse (capitales multiples, histoire…).
    let note: String
}

/// Capitales d'un continent, dans les deux sens.
struct GenerateurCapitales: GenerateurQuestions {
    enum Forme: Sendable {
        case capitaleDuPays, paysDeLaCapitale
    }

    let specialite: Specialite
    let pays: [Pays]

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        let connus = pays.filter { $0.notoriete <= difficulte + 1 }
        let candidats = connus.isEmpty ? pays : connus
        return tirerNouvelle(exclues: exclues) {
            let p = candidats.randomElement() ?? pays[0]
            let forme: Forme = Bool.random() ? .capitaleDuPays : .paysDeLaCapitale
            return question(p, forme, difficulte)
        }
    }

    private func question(_ p: Pays, _ forme: Forme, _ difficulte: Int) -> Question {
        // À difficulté élevée, les mauvaises réponses viennent des pays peu connus.
        let melanges = pays.filter { $0.pays != p.pays }.shuffled()
        let autres = difficulte >= 3 ? melanges.sorted { $0.notoriete > $1.notoriete } : melanges
        let explication = p.note.isEmpty
            ? "\(p.pays) : la capitale est \(p.capitale)."
            : "\(p.pays) : la capitale est \(p.capitale). \(p.note)"
        switch forme {
        case .capitaleDuPays:
            return .qcm(id: "cap-\(p.pays)",
                        specialite: specialite,
                        enonce: "\(p.pays) : quelle est sa capitale ?",
                        bonne: p.capitale,
                        distracteurs: autres.map(\.capitale),
                        difficulte: difficulte,
                        explication: explication)
        case .paysDeLaCapitale:
            return .qcm(id: "pays-\(p.capitale)",
                        specialite: specialite,
                        enonce: "\(p.capitale) est la capitale de quel pays ?",
                        bonne: p.pays,
                        distracteurs: autres.map(\.pays),
                        difficulte: difficulte,
                        explication: explication)
        }
    }
}
