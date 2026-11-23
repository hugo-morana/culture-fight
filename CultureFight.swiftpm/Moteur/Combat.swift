import Foundation

/// Les chiffres du game design, à un seul endroit pour l'équilibrage.
enum Regles {
    static let tailleEquipe = 3
    static let tempsReponse: Double = 15
    static let tempsMin: Double = 5
    static let toursMax = 30
    static let degatsMin = 5
    static let jaugeMax = 3
    /// Le questionneur répond aussi : ±20 % sur ses dégâts
    /// (game design, idées n° 10 et 16, valeur fixée par outils/simulation_questionneur.py).
    static let bonusQuestionneur = 0.2

    /// « 1,5 » : multiplicateur de synergie écrit à la française.
    static var texteSynergie: String {
        let k = ProfilStats.synergie
        return k == k.rounded() ? "\(Int(k))" : String(format: "%.1f", k).replacingOccurrences(of: ".", with: ",")
    }

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
    /// PV perdus par le questionneur sur un Contre des Arts martiaux (bonne réponse rapide), 0 sinon.
    /// Seule exception à la règle « seul l'attaquant fait mal ».
    let degatsContre: Int
    let capaciteUtilisee: Bool
    let jaugeRemplie: Bool
    let koDefenseur: Bool
    let koAttaquant: Bool
    /// Dégâts avant le bonus ou le malus du questionneur, pour l'afficher (« 18 PV au lieu de 15 »).
    var degatsSansQuestionneur = 0
    /// La Riposte de l'attaquant a renforcé ce coup.
    var riposteUtilisee = false
    /// Riposte préparée par le défenseur après sa bonne réponse (multiplicateur), nil s'il n'y en a pas.
    var riposteGagnee: Double? = nil
    /// Réponse du questionneur à sa propre question (nil s'il a passé ou n'a pas répondu).
    var reponseQuestionneur: Int? = nil
    /// Le questionneur a-t-il répondu (faux s'il a passé, ou si la règle est désactivée) ?
    var questionneurARepondu = false

    /// Juste, faux, ou nil si le questionneur n'a pas répondu.
    var questionneurCorrect: Bool? {
        questionneurARepondu ? reponseQuestionneur == question.bonneReponse : nil
    }
}

/// L'état d'un combat et ses règles, sans interface ni chronomètre.
struct Combat: Sendable {
    /// 0 = joueur, 1 = adversaire.
    var camps: [Camp]
    var tour = 0
    var questionsVues: Set<String> = []
    /// Secondes en moins pour la prochaine réponse de chaque camp (effet « Pression »).
    var malusTemps: [Double] = [0, 0]
    /// Questions encore relevées de +1 pour chaque camp (Élixir de surcharge).
    var surcharge: [Int] = [0, 0]
    /// Questions de l'adversaire encore abaissées de −1, pour chaque camp qui a lu le Parchemin.
    var simplification: [Int] = [0, 0]
    /// Coup de maître préparé : la prochaine question du camp monte de +2.
    var coupDeMaitre: [Bool] = [false, false]
    /// Écart de difficulté appliqué à la dernière question (−2 à +2), pour l'afficher.
    var dernierEcart = 0
    /// Difficulté de la dernière question tirée, réutilisée par le Changement de question.
    var derniereDifficulte = 1

    /// Camp qui ouvre le combat (tiré au sort à pile ou face) : il pose la première question.
    var premier = 0

    var attaquant: Int { (tour + premier) % 2 }
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

    /// Fait entrer un remplaçant à la place de chaque combattant actif K.O. (début du tour suivant).
    /// Renvoie vrai si un combattant a été remplacé.
    @discardableResult
    mutating func remplacerLesKO() -> Bool {
        let avant = camps.map(\.indexActif)
        for camp in camps.indices { camps[camp].remplacerSiKO() }
        return camps.map(\.indexActif) != avant
    }

    /// Le combattant actif de l'attaquant tire une question de sa spécialité.
    mutating func preparerQuestion() -> (question: Question, affinite: Affinite, retires: Set<Int>) {
        let att = camps[attaquant].actif
        let def0 = camps[defenseur].actif
        var ecart = 0
        if surcharge[attaquant] > 0 { ecart += 1; surcharge[attaquant] -= 1 }
        if coupDeMaitre[attaquant] { ecart += 2; coupDeMaitre[attaquant] = false }
        if att.equipement == "couronne-du-savant" { ecart += 1 }
        if simplification[defenseur] > 0 { ecart -= 1; simplification[defenseur] -= 1 }
        if def0.equipement == "loupe-du-sage" { ecart -= 1 }
        ecart = min(2, max(-2, ecart))
        dernierEcart = ecart
        let difficulte = min(7, max(1, att.profil.difficulte(base: att.stade.difficulte, rang: att.questionsPosees) + ecart))
        derniereDifficulte = difficulte
        // Créatures : leur première question du combat retire des secondes au chrono adverse.
        if att.modele.familleStyle == .creatures && att.questionsPosees == 0 {
            let k = camps[attaquant].synergie == .creatures ? ProfilStats.synergie : 1
            malusTemps[defenseur] += ProfilStats.secondesCreatures * k
        }
        camps[attaquant].combattants[camps[attaquant].indexActif].questionsPosees += 1
        return tirer(difficulte: difficulte)
    }

    /// Changement de question : une autre question à la même difficulté, sans reconsommer
    /// les effets d'objets (Parchemin, Élixir, Coup de maître) ni compter une question posée de plus.
    mutating func changerQuestion() -> (question: Question, affinite: Affinite, retires: Set<Int>) {
        tirer(difficulte: derniereDifficulte)
    }

    private mutating func tirer(difficulte: Int) -> (question: Question, affinite: Affinite, retires: Set<Int>) {
        let att = camps[attaquant].actif
        let def = camps[defenseur].actif
        let question = att.modele.generateur.generer(difficulte: difficulte, exclues: questionsVues)
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
    mutating func resoudre(question: Question, affinite: Affinite, reponse: Int?, secondes: Double,
                           reponseQuestionneur: Int? = nil, questionneurARepondu: Bool = false) -> ResultatTour {
        // Le questionneur a répondu juste : +20 % de dégâts ; faux : −20 %. Sans effet si le défenseur esquive.
        let facteurQuestionneur: Double = questionneurARepondu
            ? (reponseQuestionneur == question.bonneReponse ? 1 + Regles.bonusQuestionneur : 1 - Regles.bonusQuestionneur)
            : 1
        let a = attaquant, d = defenseur
        let ia = camps[a].indexActif, id = camps[d].indexActif
        let att = camps[a].actif, def = camps[d].actif
        let correct = reponse == question.bonneReponse
        let vitesse = correct ? Vitesse(secondes: secondes) : .normale
        let eclair = vitesse == .eclair

        var degatsDefenseur = 0
        var degatsAbsorbes = 0
        var degatsContre = 0
        var degatsSansQuestionneur = 0
        var riposteUtilisee = false
        var capaciteUtilisee = false
        var jaugeRemplie = false
        var effetVitesse: String?

        // La Riposte se dépense à la prochaine question posée par le combattant, qu'elle touche ou non.
        let riposte = camps[a].combattants[ia].riposte
        camps[a].combattants[ia].riposte = 1
        var riposteGagnee = 1.0

        if correct {
            // Seul l'attaquant fait mal : une bonne réponse est une esquive totale, personne ne perd de PV.
            var casesEnPlus = 0
            // Synergie : ×1,5 (outils/simulation.py ; ×2 donnait plus de 55 % aux équipes d'une seule famille).
            let k = camps[d].synergie == def.modele.familleStyle ? ProfilStats.synergie : 1
            let mention = k > 1 ? " (synergie ×\(Regles.texteSynergie))" : ""
            if vitesse != .normale {
                switch def.modele.familleStyle.effetVitesse {
                case .riposte:
                    let r = ProfilStats.riposte
                    riposteGagnee = 1 + (eclair ? r.eclair : r.rapide) * k
                    effetVitesse = "\(vitesse.nom) Riposte : la prochaine attaque de \(def.nom) fera +\(Int(((riposteGagnee - 1) * 100).rounded())) %\(mention)"
                case .contre:
                    // Contre (validé le 23/11) : 25 % (Éclair) ou 12 % (Rapide) des dégâts d'une attaque du défenseur,
                    // +20 % de bonus de famille. Ni synergie ni K.O. (le questionneur garde au moins 1 PV) :
                    // sinon une équipe de 3 Arts martiaux gagnait 57 à 63 % (outils/simulation.py).
                    let part = ProfilStats.contrePart(eclair: eclair)
                    let attaque = Regles.degats(attaque: def.attaque, difficulte: question.difficulte, defense: att.defense)
                    var coup = max(1, Int((Double(attaque) * part).rounded()))
                    coup = camps[a].combattants[ia].absorber(coup)
                    let pvAvant = camps[a].combattants[ia].pv
                    coup = min(coup, max(0, pvAvant - 1))
                    degatsContre = coup
                    camps[a].combattants[ia].pv -= coup
                    effetVitesse = coup > 0 ? "\(vitesse.nom) Contre : \(att.nom) perd \(coup) PV" : nil
                case .soin:
                    let soin = Int((Double(eclair ? 15 : 8) * k).rounded())
                    let avant = camps[d].combattants[id].pv
                    camps[d].combattants[id].pv = min(def.pvMax, avant + soin)
                    let gagne = camps[d].combattants[id].pv - avant
                    // Pas de « regagne 0 PV » quand le combattant a déjà tous ses PV.
                    effetVitesse = gagne > 0 ? "\(vitesse.nom) \(def.nom) regagne \(gagne) PV\(mention)" : nil
                case .bouclier:
                    let b = ProfilStats.bouclierVitesse
                    let bouclier = (eclair ? b.eclair : b.rapide) * k
                    camps[d].combattants[id].bouclier = max(camps[d].combattants[id].bouclier, bouclier)
                    effetVitesse = "\(vitesse.nom) Bouclier : sa prochaine erreur coûtera \(Int((bouclier * 100).rounded())) % de PV en moins\(mention)"
                case .savoir:
                    // Arrondi vers le bas : 3 cases en Éclair, 1 en Rapide avec la synergie.
                    casesEnPlus = Int((Double(eclair ? 2 : 1) * k).rounded(.down))
                    effetVitesse = "\(vitesse.nom) Inspiration +\(casesEnPlus) case\(casesEnPlus > 1 ? "s" : "") en plus\(mention)"
                case .pression:
                    let malus = (eclair ? 4.0 : 2.0) * k
                    malusTemps[a] = malus
                    effetVitesse = "\(vitesse.nom) Pression : l'adversaire aura \(Int(malus)) s de moins à sa prochaine réponse\(mention)"
                }
            }
            // Affinité : le spécialiste qui trouve prépare une attaque plus forte.
            riposteGagnee = max(riposteGagnee, affinite.multiplicateurRiposte)
            if riposteGagnee > 1 {
                camps[d].combattants[id].riposte = max(camps[d].combattants[id].riposte, riposteGagnee)
            }

            camps[d].combattants[id].jauge += 1 + casesEnPlus
            if camps[d].combattants[id].jauge >= camps[d].combattants[id].jaugeMax {
                camps[d].combattants[id].jauge = 0
                camps[d].combattants[id].capacitePrete = true
                jaugeRemplie = true
            }
        } else {
            var degats = Regles.degats(attaque: att.attaque,
                                       difficulte: question.difficulte,
                                       defense: def.defense)
            if att.capacitePrete {
                degats *= 2
                camps[a].combattants[ia].capacitePrete = false
                capaciteUtilisee = true
            }
            let avantQuestionneur = max(Regles.degatsMin,
                                        Int((Double(degats) * affinite.multiplicateurDegatsRecus * riposte).rounded()))
            degats = max(Regles.degatsMin,
                         Int((Double(degats) * affinite.multiplicateurDegatsRecus * riposte * facteurQuestionneur).rounded()))
            degatsSansQuestionneur = avantQuestionneur
            riposteUtilisee = riposte > 1
            let bouclier = camps[d].combattants[id].bouclier
            if bouclier > 0 {
                degatsAbsorbes = Int((Double(degats) * bouclier).rounded())
                degats -= degatsAbsorbes
                camps[d].combattants[id].bouclier = 0
            }
            let parBouclierChevalier = degats - camps[d].combattants[id].absorber(degats)
            degatsAbsorbes += parBouclierChevalier
            degats -= parBouclierChevalier
            degatsDefenseur = degats
            camps[d].combattants[id].pv -= degatsDefenseur
        }

        let koDefenseur = camps[d].combattants[id].estKO
        let koAttaquant = camps[a].combattants[ia].estKO
        for camp in camps.indices {
            for i in camps[camp].combattants.indices where camps[camp].combattants[i].pv < 0 {
                camps[camp].combattants[i].pv = 0
            }
        }
        // Le combattant K.O. reste à l'écran jusqu'au bouton Suivant : il n'est remplacé
        // qu'au début du tour suivant (`remplacerLesKO`, retour bêta n° 13).
        tour += 1

        var resultat = ResultatTour(question: question,
                            reponse: reponse,
                            correct: correct,
                            affinite: affinite,
                            vitesse: vitesse,
                            effetVitesse: effetVitesse,
                            attaquantNom: att.nom,
                            defenseurNom: def.nom,
                            defenseurEstJoueur: d == 0,
                            degatsDefenseur: degatsDefenseur,
                            degatsAbsorbes: degatsAbsorbes,
                            degatsContre: degatsContre,
                            capaciteUtilisee: capaciteUtilisee,
                            jaugeRemplie: jaugeRemplie,
                            koDefenseur: koDefenseur,
                            koAttaquant: koAttaquant)
        resultat.degatsSansQuestionneur = degatsSansQuestionneur
        resultat.riposteUtilisee = riposteUtilisee
        resultat.riposteGagnee = correct && riposteGagnee > 1 ? riposteGagnee : nil
        resultat.reponseQuestionneur = reponseQuestionneur
        resultat.questionneurARepondu = questionneurARepondu
        return resultat
    }

    // MARK: - Objets

    /// Applique un consommable (ou le Coup de maître) pour un camp. Renvoie le message à afficher, nil si impossible.
    /// Le Joker et le Changement de question agissent sur la question en cours : le contrôleur s'en charge.
    mutating func utiliser(_ objet: String, camp: Int) -> String? {
        let i = camps[camp].indexActif
        let nom = camps[camp].actif.nom
        switch objet {
        case "potion":
            guard !camps[camp].combattants[i].estKO else { return nil }
            let avant = camps[camp].combattants[i].pv
            camps[camp].combattants[i].pv = min(camps[camp].combattants[i].pvMax, avant + 30)
            return "Potion : \(nom) regagne \(camps[camp].combattants[i].pv - avant) PV"
        case "bouclier":
            camps[camp].combattants[i].bouclier = 1
            return "Bouclier : la prochaine erreur de \(nom) ne coûtera aucun PV"
        case "parchemin-simplification":
            simplification[camp] += 3
            return "Parchemin : les 3 prochaines questions adverses seront plus faciles"
        case "elixir-surcharge":
            surcharge[camp] += 3
            return "Élixir : tes 3 prochaines questions seront plus difficiles"
        case "coup-de-maitre":
            guard camps[camp].combattants[i].capacitePrete else { return nil }
            camps[camp].combattants[i].capacitePrete = false
            coupDeMaitre[camp] = true
            return "Coup de maître : ta prochaine question montera de 2 crans"
        default:
            return nil
        }
    }
}
