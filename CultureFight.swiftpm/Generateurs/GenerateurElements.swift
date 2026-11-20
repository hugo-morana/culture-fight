import Foundation

/// Un élément chimique de `Resources/elements.json`.
struct ElementChimique: Decodable, Sendable {
    let numero: Int
    let symbole: String
    let nom: String
    /// « gaz noble », « halogène »… ou vide.
    let famille: String
    /// 1 = très connu, 3 = rare.
    let notoriete: Int
    /// Une ligne de contexte (origine du nom, usage…) affichée après la réponse.
    let anecdote: String
}

/// Questions sur une sélection d'éléments (gaz nobles, halogènes, tous les éléments…).
struct GenerateurElements: GenerateurQuestions {
    enum Forme: Sendable {
        case nomDuSymbole, symboleDuNom, numeroAtomique, nomDuNumero
    }

    let specialite: Specialite
    /// Les éléments de la spécialité.
    let selection: [ElementChimique]
    /// Tous les éléments, pour compléter les mauvaises réponses.
    let tous: [ElementChimique]
    let formes: [Forme]

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        let connus = selection.filter { $0.notoriete <= difficulte + 1 }
        let candidats = connus.isEmpty ? selection : connus
        return tirerNouvelle(exclues: exclues) {
            let element = candidats.randomElement() ?? tous[0]
            let forme = formes.randomElement() ?? .nomDuSymbole
            return question(element, forme, difficulte)
        }
    }

    /// Mauvaises réponses plausibles : d'abord la même spécialité, puis les voisins du tableau.
    /// Plus la difficulté monte, plus on prend des voisins proches.
    private func voisins(de element: ElementChimique, difficulte: Int) -> [ElementChimique] {
        let memeSelection = selection.filter { $0.numero != element.numero }.shuffled()
        let proches = tous
            .filter { $0.numero != element.numero }
            .sorted { abs($0.numero - element.numero) < abs($1.numero - element.numero) }
            .prefix(6)
            .shuffled()
        if memeSelection.count >= 3 && memeSelection.count <= 20 {
            return memeSelection + proches
        }
        return difficulte >= 2 ? proches + memeSelection : memeSelection + proches
    }

    private func question(_ e: ElementChimique, _ forme: Forme, _ difficulte: Int) -> Question {
        let autres = voisins(de: e, difficulte: difficulte)
        let explication = "\(e.nom) : symbole \(e.symbole), numéro atomique \(e.numero). \(e.anecdote)"
        switch forme {
        case .nomDuSymbole:
            return .qcm(id: "el-nom-\(e.numero)",
                        specialite: specialite,
                        enonce: "Quel élément a pour symbole \(e.symbole) ?",
                        bonne: e.nom,
                        distracteurs: autres.map(\.nom),
                        difficulte: difficulte,
                        explication: explication)
        case .symboleDuNom:
            return .qcm(id: "el-sym-\(e.numero)",
                        specialite: specialite,
                        enonce: "Quel est le symbole de l'élément « \(e.nom) » ?",
                        bonne: e.symbole,
                        distracteurs: autres.map(\.symbole),
                        difficulte: difficulte,
                        explication: explication)
        case .nomDuNumero:
            return .qcm(id: "el-nomnum-\(e.numero)",
                        specialite: specialite,
                        enonce: "Quel élément a le numéro atomique \(e.numero) ?",
                        bonne: e.nom,
                        distracteurs: autres.map(\.nom),
                        difficulte: difficulte,
                        explication: explication)
        case .numeroAtomique:
            return .qcm(id: "el-num-\(e.numero)",
                        specialite: specialite,
                        enonce: "Quel est le numéro atomique de l'élément « \(e.nom) » ?",
                        bonne: String(e.numero),
                        distracteurs: autres.map { String($0.numero) },
                        difficulte: difficulte,
                        explication: explication)
        }
    }
}
