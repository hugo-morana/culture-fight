import Foundation

/// Une spécialité de la grille 10 domaines × 10 familles × 10 spécialités.
struct Specialite: Hashable, Sendable {
    let id: String
    let nom: String
    let famille: String
    let domaine: String
}

/// Une question à choix multiples posée par un combattant.
struct Question: Identifiable, Sendable {
    /// Clé stable : sert à ne pas reposer une question déjà vue.
    let id: String
    let specialite: Specialite
    let enonce: String
    let choix: [String]
    let bonneReponse: Int
    let difficulte: Int
    /// Une ligne de contexte affichée après la réponse.
    let explication: String
    /// Page source du fait (« En savoir plus »), nil pour les questions générées sans source.
    var source: String? = nil

    var texteBonneReponse: String { choix[bonneReponse] }
}

extension Question {
    /// Construit un QCM à 4 choix : la bonne réponse et les 3 premiers distracteurs distincts, mélangés.
    static func qcm(id: String,
                    specialite: Specialite,
                    enonce: String,
                    bonne: String,
                    distracteurs: [String],
                    difficulte: Int,
                    explication: String,
                    source: String? = nil) -> Question {
        var autres: [String] = []
        for d in distracteurs where d != bonne && !autres.contains(d) {
            autres.append(d)
            if autres.count == 3 { break }
        }
        var choix = autres + [bonne]
        choix.shuffle()
        let index = choix.firstIndex(of: bonne) ?? 0
        return Question(id: id,
                        specialite: specialite,
                        enonce: enonce,
                        choix: choix,
                        bonneReponse: index,
                        difficulte: difficulte,
                        explication: explication,
                        source: source)
    }
}

/// Proximité entre la question posée et la spécialité du combattant qui répond.
enum Affinite: Sendable {
    case specialite, famille, domaine, aucune

    static func entre(_ question: Specialite, _ defenseur: Specialite) -> Affinite {
        if question.id == defenseur.id { return .specialite }
        if question.famille == defenseur.famille { return .famille }
        if question.domaine == defenseur.domaine { return .domaine }
        return .aucune
    }

    /// Secondes en plus pour répondre.
    var bonusTemps: Double {
        switch self {
        case .specialite: return 0
        case .famille: return 5
        case .domaine: return 3
        case .aucune: return 0
        }
    }

    /// Mauvaises réponses retirées avant de répondre.
    var choixRetires: Int { self == .specialite ? 2 : 0 }

    /// Multiplicateur des dégâts reçus en cas d'erreur.
    var multiplicateurDegatsRecus: Double {
        switch self {
        case .specialite: return 0.5
        case .famille: return 0.75
        case .domaine, .aucune: return 1
        }
    }

    /// Riposte d'affinité : multiplicateur de la prochaine attaque du défenseur après une bonne réponse.
    var multiplicateurRiposte: Double {
        switch self {
        case .specialite: return 2
        case .famille: return 1.25
        case .domaine, .aucune: return 1
        }
    }

    var libelle: String? {
        switch self {
        case .specialite: return "Sa spécialité : 2 réponses retirées, dégâts ÷ 2, prochaine attaque × 2 s'il trouve"
        case .famille: return "Même famille : +5 s, dégâts −25 %, prochaine attaque +25 % s'il trouve"
        case .domaine: return "Même domaine : +3 s"
        case .aucune: return nil
        }
    }
}
