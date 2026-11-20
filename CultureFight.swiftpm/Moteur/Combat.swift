import Foundation

/// Les chiffres du game design, à un seul endroit pour l'équilibrage.
enum Regles {
    static let tailleEquipe = 3
    static let tempsReponse: Double = 15
    static let tempsMin: Double = 5
    static let toursMax = 30
    static let degatsMin = 5
    static let jaugeMax = 3

    /// Bonne réponse en moins de 3 s : « Éclair ». En moins de 7 s : « Rapide ».
    static let seuilEclair: Double = 3
    static let seuilRapide: Double = 7

    /// D = max(5, Attaque × (1 + 0,1 × (Difficulté − 1)) − Défense)
    static func degats(attaque: Int, difficulte: Int, defense: Int) -> Int {
        let brut = Double(attaque) * (1 + 0.1 * Double(difficulte - 1))
        return max(degatsMin, Int(brut.rounded()) - defense)
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
    /// Effet du bonus de vitesse en clair, ou nil s'il n'y en a pas eu.
    let effetVitesse: String?
    let attaquantNom: String
    let defenseurNom: String
    let defenseurEstJoueur: Bool
    /// PV perdus par le défenseur (mauvaise réponse).
    let degatsDefenseur: Int
    /// Part des dégâts absorbée par un bouclier.
    let degatsAbsorbes: Int
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
    /// Secondes en moins pour la prochaine réponse de chaque camp (effet « Pression »).
    var malusTemps: [Double] = [0, 0]

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

    /// Le malus de temps du défenseur pour cette question, remis à zéro une fois utilisé.
    mutating func consommerMalusTemps() -> Double {
        let malus = malusTemps[defenseur]
        malusTemps[defenseur] = 0
        return malus
    }

    /// Applique la réponse du défenseur (nil = temps écoulé) et passe au tour suivant.
    /// - Parameter secondes: temps mis pour répondre.
    mutating func resoudre(question: Question, affinite: Affinite, reponse: Int?, secondes: Double) -> ResultatTour {
        let a = attaquant, d = defenseur
        let ia = camps[a].indexActif, id = camps[d].indexActif
        let att = camps[a].actif, def = camps[d].actif
        let correct = reponse == question.bonneReponse
        let vitesse = correct ? Vitesse(secondes: secondes) : .normale
        let eclair = vitesse == .eclair

        var degatsDefenseur = 0
        var degatsAbsorbes = 0
        var degatsContre = 0
        var capaciteUtilisee = false
        var jaugeRemplie = false
        var effetVitesse: String?

        if correct {
            // Bonus de vitesse : son effet dépend de la famille de styles de celui qui a répondu.
            var multiplicateurVitesse = 1.0
            var casesEnPlus = 0
            // Synergie d'équipe : 3 combattants de la même famille de styles doublent le bonus.
            let k = camps[d].synergie == def.modele.familleStyle ? 2 : 1
            let mention = k == 2 ? " (synergie ×2)" : ""
            if vitesse != .normale {
                switch def.modele.familleStyle.effetVitesse {
                case .contreAttaque:
                    let bonus = (eclair ? 50 : 25) * k
                    multiplicateurVitesse = 1 + Double(bonus) / 100
                    effetVitesse = "\(vitesse.nom) Contre-attaque +\(bonus) %\(mention)"
                case .soin:
                    let soin = (eclair ? 15 : 8) * k
                    let avant = camps[d].combattants[id].pv
                    camps[d].combattants[id].pv = min(def.modele.pvMax, avant + soin)
                    effetVitesse = "\(vitesse.nom) \(def.modele.nom) regagne \(camps[d].combattants[id].pv - avant) PV\(mention)"
                case .bouclier:
                    let bouclier = (eclair ? 0.3 : 0.15) * Double(k)
                    camps[d].combattants[id].bouclier = max(camps[d].combattants[id].bouclier, bouclier)
                    effetVitesse = "\(vitesse.nom) Bouclier : sa prochaine erreur coûtera \(Int(bouclier * 100)) % de PV en moins\(mention)"
                case .savoir:
                    casesEnPlus = (eclair ? 2 : 1) * k
                    effetVitesse = "\(vitesse.nom) Jauge de Savoir +\(casesEnPlus) case\(casesEnPlus > 1 ? "s" : "") en plus\(mention)"
                case .pression:
                    let malus = (eclair ? 4.0 : 2.0) * Double(k)
                    malusTemps[a] = malus
                    effetVitesse = "\(vitesse.nom) Pression : l'adversaire aura \(Int(malus)) s de moins à sa prochaine réponse\(mention)"
                }
            }

            // Contre-attaque : moitié des dégâts, avec l'Attaque du défenseur.
            let base = Regles.degats(attaque: def.modele.attaque,
                                     difficulte: question.difficulte,
                                     defense: att.modele.defense)
            degatsContre = max(Regles.degatsMin,
                               Int((Double(base) * 0.5 * affinite.multiplicateurContre * multiplicateurVitesse).rounded()))
            camps[a].combattants[ia].pv -= degatsContre

            camps[d].combattants[id].jauge += 1 + casesEnPlus
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
            degats = max(Regles.degatsMin, Int((Double(degats) * affinite.multiplicateurDegatsRecus).rounded()))
            let bouclier = camps[d].combattants[id].bouclier
            if bouclier > 0 {
                degatsAbsorbes = Int((Double(degats) * bouclier).rounded())
                degats -= degatsAbsorbes
                camps[d].combattants[id].bouclier = 0
            }
            degatsDefenseur = degats
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
                            effetVitesse: effetVitesse,
                            attaquantNom: att.modele.nom,
                            defenseurNom: def.modele.nom,
                            defenseurEstJoueur: d == 0,
                            degatsDefenseur: degatsDefenseur,
                            degatsAbsorbes: degatsAbsorbes,
                            degatsContre: degatsContre,
                            capaciteUtilisee: capaciteUtilisee,
                            jaugeRemplie: jaugeRemplie,
                            koDefenseur: koDefenseur,
                            koAttaquant: koAttaquant)
    }
}
