import Foundation

/// Les données dont un générateur tire ses questions, pour les montrer dans la fiche du combattant.
struct TableauDonnees: Identifiable, Sendable {
    let titre: String
    let entetes: [String]
    let lignes: [[String]]
    /// Identifiant du jeu de données (clé de `Resources/sources.json`), s'il y en a un.
    var jeu: String? = nil
    var note: String? = nil
    /// Nombre de questions différentes par ligne (2 si la question est posée dans les deux sens), nil si infini.
    var questionsParLigne: Int? = 1
    var id: String { titre }

    /// Nombre de questions différentes, nil si le générateur en crée à l'infini.
    var nombreDeQuestions: Int? { questionsParLigne.map { $0 * lignes.count } }
}

extension GenerateurFiche {
    var apercu: [TableauDonnees] {
        var tableaux = fiche.relations.map { relation in
            TableauDonnees(titre: Self.titre(relation.modele),
                           entetes: ["Indice", "Réponse"],
                           lignes: relation.paires.map { Array($0.prefix(2)) },
                           jeu: fiche.id,
                           note: relation.inverse == nil ? nil : "Posée dans les deux sens.",
                           questionsParLigne: relation.inverse == nil ? 1 : 2)
        }
        if !fiche.questions.isEmpty {
            tableaux.append(TableauDonnees(titre: "Questions de culture",
                                           entetes: ["Question", "Réponse"],
                                           lignes: fiche.questions.map { [$0.enonce, $0.bonne] },
                                           jeu: fiche.id))
        }
        return tableaux
    }

    /// « Quel félin correspond à cette description : « {x} » ? » → « Quel félin correspond à cette description ? »
    static func titre(_ modele: String) -> String {
        var t = modele.replacingOccurrences(of: " : « {x} »", with: "")
            .replacingOccurrences(of: " : {x}", with: "")
            .replacingOccurrences(of: "« {x} »", with: "…")
            .replacingOccurrences(of: "{x}", with: "…")
        t = t.replacingOccurrences(of: "  ", with: " ")
        return t
    }
}

extension GenerateurElements {
    var apercu: [TableauDonnees] {
        [TableauDonnees(titre: "Éléments de la spécialité",
                        entetes: ["N°", "Symbole", "Nom"],
                        lignes: selection.map { ["\($0.numero)", $0.symbole, $0.nom] },
                        jeu: "elements",
                        note: "Questions sur le nom, le symbole et le numéro atomique.",
                        questionsParLigne: formes.count)]
    }
}

extension GenerateurCapitales {
    var apercu: [TableauDonnees] {
        [TableauDonnees(titre: "Pays et capitales",
                        entetes: ["Pays", "Capitale"],
                        lignes: pays.sorted { $0.pays < $1.pays }.map { [$0.pays, $0.capitale] },
                        jeu: "pays-afrique",
                        note: "Posée dans les deux sens.",
                        questionsParLigne: 2)]
    }
}

extension GenerateurConversions {
    var apercu: [TableauDonnees] {
        let format = NumberFormatter()
        format.locale = Locale(identifier: "fr_FR")
        format.numberStyle = .decimal
        return [TableauDonnees(titre: "Conversions",
                               entetes: ["Unité", "Équivalent"],
                               lignes: Self.conversions.map { c in
                                   let n = format.string(from: NSNumber(value: c.facteur)) ?? "\(c.facteur)"
                                   return ["1 \(c.grande)", "\(n) \(c.petite)"]
                               },
                               note: "Les questions mélangent ces conversions avec des nombres tirés au hasard, dans les deux sens.",
                               questionsParLigne: nil)]
    }
}

extension GenerateurCalcul {
    var apercu: [TableauDonnees] {
        let signe = operation == .multiplication ? "×" : "÷"
        let lignes = (2...12).map { n -> [String] in
            let produits = (1...10).map { "\(n * $0)" }.joined(separator: ", ")
            return ["Table de \(n)", produits]
        }
        let note = operation == .multiplication
            ? "Difficulté 1 : tables de 2 à 10 ; puis jusqu'à 12, puis des nombres à deux chiffres."
            : "Les divisions tombent juste : le dividende est un produit de ces tables."
        return [TableauDonnees(titre: "Tables (\(signe))", entetes: ["Table", "Résultats de 1 à 10"],
                               lignes: lignes, note: note, questionsParLigne: nil)]
    }
}

extension GenerateurMixte {
    var apercu: [TableauDonnees] { parties.flatMap { $0.generateur.apercu } }
}
