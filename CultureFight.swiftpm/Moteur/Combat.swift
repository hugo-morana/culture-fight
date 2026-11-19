import Foundation

/// Les chiffres du game design, à un seul endroit pour l'équilibrage.
enum Regles {
    static let tailleEquipe = 3
    static let tempsReponse: Double = 15
    static let toursMax = 30
    static let degatsMin = 5
    static let jaugeMax = 3

    /// Bonus de vitesse sur la contre-attaque : moins de 3 s « Éclair », moins de 7 s « Rapide ».
    static let seuilEclair: Double = 3
    static let seuilRapide: Double = 7

    /// D = max(5, Attaque × (1 + 0,1 × (Difficulté − 1)) − Défense)
    static func degats(attaque: Int, difficulte: Int, defense: Int) -> Int {
        let brut = Double(attaque) * (1 + 0.1 * Double(difficulte - 1))
        return max(degatsMin, Int(brut.rounded()) - defense)
    }
}

/// Rapidité d'une bonne réponse.
enum Vitesse: Sendable {
    case eclair, rapide, normale

    init(secondes: Double) {
        if secondes < Regles.seuilEclair { self = .eclair }
        else if secondes < Regles.seuilRapide { self = .rapide }
        else { self = .normale }
    }

    var multiplicateurContre: Double {
        switch self {
        case .eclair: return 1.5
        case .rapide: return 1.25
        case .normale: return 1
        }
    }

    var libelle: String? {
        switch self {
        case .eclair: return "Éclair ! Contre-attaque +50 %"
        case .rapide: return "Rapide ! Contre-attaque +25 %"
        case .normale: return nil
        }
    }
}

/// Ce qui s'est passé pendant un tour, pour l'affichage.
struct ResultatTour: Sendable {
    let question: Question
    let reponse: Int?
    let correct: Bool
    let affinite: Affinite
    /// Rapidité de la réponse (comptée seulement si elle est bonne).
    let vitesse: Vitesse
    let attaquantNom: String
    let defenseurNom: String
    let defenseurEstJoueur: Bool
    /// PV perdus par le défenseur (mauvaise réponse).
    let degatsDefenseur: Int
    /// PV perdus par l'attaquant (contre-attaque après une bonne réponse).
    let degatsContre: Int
    let capaciteUtilisee: Bool
    let jaugeRemplie: Bool
    let koDefenseur: Bool
    let koAttaquant: Bool
}

/// L'état d'un combat et ses règles, sans interface ni chronomètre.
struct Combat: Sendable {
    /// 0 = joueur, 1 = adversaire.
    var camps: [Camp]
    var tour = 0
    var questionsVues: Set<String> = []

    var attaquant: Int { tour % 2 }
    var defenseur: Int { 1 - attaquant }

    var estTermine: Bool {
        camps[0].estElimine || camps[1].estElimine || tour >= Regles.toursMax
    }

    /// Camp gagnant (0 ou 1), ou nil en cas d'égalité ou de combat en cours.
    var vainqueur: Int? {
        if camps[1].estElimine && !camps[0].estElimine { return 0 }
        if camps[0].estElimine && !camps[1].estElimine { return 1 }
        guard tour >= Regles.toursMax else { return nil }
        if camps[0].pvTotal == camps[1].pvTotal { return nil }
        return camps[0].pvTotal > camps[1].pvTotal ? 0 : 1
    }

    /// Le combattant actif de l'attaquant tire une question de sa spécialité.
    mutating func preparerQuestion() -> (question: Question, affinite: Affinite, retires: Set<Int>) {
        let att = camps[attaquant].actif
        let def = camps[defenseur].actif
        let question = att.modele.generateur.generer(difficulte: att.modele.difficulte,
                                                     exclues: questionsVues)
        questionsVues.insert(question.id)
        let affinite = Affinite.entre(question.specialite, def.modele.specialite)
        let mauvaises = question.choix.indices.filter { $0 != question.bonneReponse }.shuffled()
        let retires = Set(mauvaises.prefix(affinite.choixRetires))
        return (question, affinite, retires)
    }

    /// Applique la réponse du défenseur (nil = temps écoulé) et passe au tour suivant.
    /// - Parameter secondes: temps mis pour répondre.
    mutating func resoudre(question: Question, affinite: Affinite, reponse: Int?, secondes: Double) -> ResultatTour {
        let a = attaquant, d = defenseur
        let ia = camps[a].indexActif, id = camps[d].indexActif
        let att = camps[a].actif, def = camps[d].actif
        let correct = reponse == question.bonneReponse
        let vitesse = correct ? Vitesse(secondes: secondes) : .normale

        var degatsDefenseur = 0
        var degatsContre = 0
        var capaciteUtilisee = false
        var jaugeRemplie = false

        if correct {
            // Contre-attaque : moitié des dégâts, avec l'Attaque du défenseur.
            let base = Regles.degats(attaque: def.modele.attaque,
                                     difficulte: question.difficulte,
                                     defense: att.modele.defense)
            degatsContre = max(Regles.degatsMin,
                               Int((Double(base) * 0.5 * affinite.multiplicateurContre * vitesse.multiplicateurContre).rounded()))
            camps[a].combattants[ia].pv -= degatsContre

            camps[d].combattants[id].jauge += 1
            if camps[d].combattants[id].jauge >= Regles.jaugeMax {
                camps[d].combattants[id].jauge = 0
                camps[d].combattants[id].capacitePrete = true
                jaugeRemplie = true
            }
        } else {
            var degats = Regles.degats(attaque: att.modele.attaque,
                                       difficulte: question.difficulte,
                                       defense: def.modele.defense)
            if att.capacitePrete {
                degats *= 2
                camps[a].combattants[ia].capacitePrete = false
                capaciteUtilisee = true
            }
            degatsDefenseur = max(Regles.degatsMin,
                                  Int((Double(degats) * affinite.multiplicateurDegatsRecus).rounded()))
            camps[d].combattants[id].pv -= degatsDefenseur
        }

        let koDefenseur = camps[d].combattants[id].estKO
        let koAttaquant = camps[a].combattants[ia].estKO
        for camp in camps.indices {
            for i in camps[camp].combattants.indices where camps[camp].combattants[i].pv < 0 {
                camps[camp].combattants[i].pv = 0
            }
            camps[camp].remplacerSiKO()
        }
        tour += 1

        return ResultatTour(question: question,
                            reponse: reponse,
                            correct: correct,
                            affinite: affinite,
                            vitesse: vitesse,
                            attaquantNom: att.modele.nom,
                            defenseurNom: def.modele.nom,
                            defenseurEstJoueur: d == 0,
                            degatsDefenseur: degatsDefenseur,
                            degatsContre: degatsContre,
                            capaciteUtilisee: capaciteUtilisee,
                            jaugeRemplie: jaugeRemplie,
                            koDefenseur: koDefenseur,
                            koAttaquant: koAttaquant)
    }
}
