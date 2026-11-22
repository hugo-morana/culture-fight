import Foundation
import Observation

/// Fait vivre un `Combat` : chronomètre, réponse de l'IA, enchaînement des tours.
@MainActor
@Observable
final class CombatController {
    enum Phase {
        case attente
        case question
        case resultat(ResultatTour)
        case fin
    }

    private(set) var combat: Combat
    private(set) var phase: Phase = .attente
    private(set) var question: Question?
    private(set) var affinite: Affinite = .aucune
    private(set) var retires: Set<Int> = []
    private(set) var tempsTotal: Double = Regles.tempsReponse
    private(set) var tempsRestant: Double = Regles.tempsReponse
    /// Compteur par camp, augmenté à chaque fois que ses PV changent (déclenche les animations).
    private(set) var impacts: [Int] = [0, 0]
    /// Dernière variation de PV de chaque camp : négative pour des dégâts, positive pour un soin.
    private(set) var variations: [Int] = [0, 0]

    /// Secondes retirées par l'effet « Pression » pour la question en cours.
    private(set) var malusTemps: Double = 0

    /// Le questionneur répond aussi à sa question (désactivé en duel local à deux sur un téléphone).
    let questionneurRepond: Bool
    /// Réponse du joueur à sa propre question quand il attaque (nil tant qu'il n'a pas répondu, ou s'il a passé).
    private(set) var reponseAttaque: Int?
    /// Le joueur a répondu à sa question ou a passé.
    private(set) var attaqueFinie = false
    /// Bonnes réponses du joueur à ses propres questions, par combattant (+5 XP chacune).
    private(set) var bonnesReponsesAttaqueParCombattant: [String: Int] = [:]
    @ObservationIgnored private var reponseQuestionneurIA: Int?

    let ia: IAAdverse
    /// Réponses du joueur, sauvegardées pour les statistiques du profil.
    private(set) var reponsesJoueur: [ReponseJouee] = []
    /// Tous les tours joués, pour la revue de partie en fin de combat.
    private(set) var historique: [ResultatTour] = []
    /// Bonnes réponses données par le joueur, au total et par combattant (identifiant du modèle).
    private(set) var bonnesReponsesJoueur = 0
    private(set) var bonnesReponsesParCombattant: [String: Int] = [:]
    /// Niveaux gagnés à la fin du combat, remplis par la sauvegarde (identifiant → niveaux).
    var niveauxGagnes: [String: Int] = [:]
    var niveauxCompteGagnes = 0

    /// Vrai une fois le résultat du combat enregistré dans la sauvegarde.
    @ObservationIgnored private var gainsVerses = false
    @ObservationIgnored private var tache: Task<Void, Never>?
    @ObservationIgnored private var debutQuestion = Date()

    /// Combattants du joueur qui ont changé de stade, remplis par la sauvegarde en fin de combat.
    var evolutions: [EvolutionCombattant] = []

    /// Consommables du joueur disponibles pour ce combat (identifiant → quantité).
    private(set) var consommables: [String: Int] = [:]
    /// Consommables utilisés pendant ce combat, à retirer de l'inventaire en fin de combat.
    private(set) var objetsUtilises: [String] = []
    /// Dernier effet d'objet, affiché brièvement.
    private(set) var messageObjet: String?
    private(set) var compteurObjets = 0
    /// Nombre maximum de consommables utilisables par combat (game design : 2).
    static let consommablesParCombat = 2

    init(equipeJoueur: [ModeleCombattant], equipeIA: [ModeleCombattant], ia: IAAdverse,
         profils: [String: ProfilDifficulte] = [:], niveaux: [String: Int] = [:],
         equipements: [String: String] = [:], consommables: [String: Int] = [:], bonusPV: [String: Int] = [:],
         questionneurRepond: Bool = true) {
        self.ia = ia
        self.questionneurRepond = questionneurRepond
        self.consommables = consommables.filter { id, n in
            n > 0 && Boutique.objet(id)?.genre == .consommable
        }
        self.combat = Combat(camps: [
            Camp(nom: "Toi", estIA: false, equipe: equipeJoueur, profils: profils, niveaux: niveaux,
                 equipements: equipements, bonusPV: bonusPV),
            Camp(nom: "IA \(ia.niveau.rawValue.lowercased())", estIA: true, equipe: equipeIA, niveauParDefaut: Stade.pourIA(ia.niveau).niveauMin),
        ])
        combat.premier = Int.random(in: 0...1)
    }

    var estFini: Bool {
        if case .fin = phase { return true }
        return false
    }

    /// Le joueur répond-il à la question en cours ?
    var joueurRepond: Bool { !combat.camps[combat.defenseur].estIA }

    /// Le joueur attaque et peut répondre à sa propre question (ou passer).
    var joueurAttaque: Bool { questionneurRepond && !combat.camps[combat.attaquant].estIA }

    /// Réponse du joueur à sa propre question : une fois choisie, elle ne change plus.
    func repondreAttaque(_ index: Int) {
        guard joueurAttaque, case .question = phase, !attaqueFinie else { return }
        reponseAttaque = index
        attaqueFinie = true
        ServiceSons.partage.jouer(.selection)
    }

    /// Le joueur ne répond pas à sa propre question : dégâts et contre-attaque normaux.
    func passerAttaque() {
        guard joueurAttaque, case .question = phase, !attaqueFinie else { return }
        reponseAttaque = nil
        attaqueFinie = true
    }

    /// Le joueur ouvre-t-il le combat (pile ou face) ?
    var joueurCommence: Bool { combat.premier == 0 }

    func demarrer() {
        guard case .attente = phase else { return }
        nouveauTour()
    }

    func repondre(_ index: Int) {
        guard joueurRepond, case .question = phase, !retires.contains(index) else { return }
        tache?.cancel()
        valider(index)
    }

    func continuer() {
        guard case .resultat = phase else { return }
        nouveauTour()
    }

    func abandonner() {
        tache?.cancel()
    }

    /// Note que le résultat a été enregistré. Renvoie faux s'il l'était déjà, pour ne jamais compter
    /// deux fois le même combat.
    func marquerGainsVerses() -> Bool {
        guard !gainsVerses else { return false }
        gainsVerses = true
        return true
    }

    // MARK: - Objets

    /// Un objet utilisable maintenant par le joueur.
    struct ObjetDisponible: Identifiable {
        let id: String
        let nom: String
        let symbole: String
        let quantite: Int?
    }

    var consommablesRestants: Int { Self.consommablesParCombat - objetsUtilises.count }

    /// Les objets que le joueur peut utiliser à ce moment du combat.
    var objetsDisponibles: [ObjetDisponible] {
        guard !estFini else { return [] }
        var liste: [ObjetDisponible] = []
        let enQuestion: Bool = { if case .question = phase { return true } else { return false } }()
        let enResultat: Bool = { if case .resultat = phase { return true } else { return false } }()
        if combat.camps[0].actif.capacitePrete && (enQuestion || enResultat) {
            liste.append(ObjetDisponible(id: "coup-de-maitre", nom: "Coup de maître", symbole: "sparkles", quantite: nil))
        }
        guard consommablesRestants > 0, enQuestion || enResultat else { return liste }
        for objet in Boutique.objets where objet.genre == .consommable {
            guard let n = consommables[objet.id], n > 0 else { continue }
            let surQuestion = objet.id == "joker" || objet.id == "changement-question"
            if surQuestion && !(enQuestion && joueurRepond) { continue }
            liste.append(ObjetDisponible(id: objet.id, nom: objet.nom, symbole: objet.symbole, quantite: n))
        }
        return liste
    }

    func utiliser(_ id: String) {
        let message: String?
        switch id {
        case "joker":
            guard case .question = phase, joueurRepond, let question else { return }
            let fausses = question.choix.indices.filter { $0 != question.bonneReponse && !retires.contains($0) }.shuffled()
            retires.formUnion(fausses.prefix(2))
            message = "Joker : deux mauvaises réponses retirées"
        case "changement-question":
            guard case .question = phase, joueurRepond else { return }
            lancer(combat.changerQuestion())
            message = "Nouvelle question !"
        default:
            message = combat.utiliser(id, camp: 0)
        }
        guard let message else { return }
        if id != "coup-de-maitre" {
            consommables[id, default: 0] -= 1
            objetsUtilises.append(id)
        }
        messageObjet = message
        compteurObjets += 1
        ServiceSons.partage.jouer(.objet)
    }

    // MARK: - Déroulé

    private func nouveauTour() {
        tache?.cancel()
        guard !combat.estTermine else {
            phase = .fin
            return
        }
        malusTemps = combat.consommerMalusTemps()
        lancer(combat.preparerQuestion())
    }

    /// Affiche une question et lance le chronomètre (et la réponse de l'IA si c'est elle qui répond).
    private func lancer(_ tirage: (question: Question, affinite: Affinite, retires: Set<Int>)) {
        tache?.cancel()
        question = tirage.question
        affinite = tirage.affinite
        retires = tirage.retires
        let bonusEquipement = combat.camps[combat.defenseur].actif.bonusTemps
        tempsTotal = max(Regles.tempsMin, Regles.tempsReponse + tirage.affinite.bonusTemps + bonusEquipement - malusTemps)
        tempsRestant = tempsTotal
        reponseAttaque = nil
        attaqueFinie = false
        // L'IA répond aussi à ses propres questions (affinité de spécialité), et ne passe jamais.
        reponseQuestionneurIA = questionneurRepond && combat.camps[combat.attaquant].estIA
            ? ia.repondre(question: tirage.question, affinite: .specialite, retires: [])
            : nil
        phase = .question
        ServiceSons.partage.jouer(.question)
        let joueurReponds = !combat.camps[combat.defenseur].estIA || joueurAttaque
        let secondesInitiales = Int(tempsTotal.rounded(.up))

        let reponseIA: Int? = combat.camps[combat.defenseur].estIA
            ? ia.repondre(question: tirage.question, affinite: tirage.affinite, retires: tirage.retires)
            : nil
        let delaiIA = min(ia.delaiReponse(), tempsTotal - 0.5)
        let debut = Date()
        debutQuestion = debut

        tache = Task { [weak self] in
            var dernierTic = secondesInitiales
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                let ecoule = Date().timeIntervalSince(debut)
                self.tempsRestant = max(0, self.tempsTotal - ecoule)
                // Tic du chrono sur les 5 dernières secondes, quand c'est le joueur qui répond.
                let seconde = Int(self.tempsRestant.rounded(.up))
                if joueurReponds, !(self.joueurAttaque && self.attaqueFinie),
                   seconde < dernierTic, seconde <= 5, seconde > 0 {
                    ServiceSons.partage.jouer(.tic)
                }
                dernierTic = seconde
                // Les deux réponses sont révélées ensemble : on attend aussi celle du joueur qui attaque.
                if let reponseIA, ecoule >= delaiIA, !self.joueurAttaque || self.attaqueFinie {
                    self.valider(reponseIA)
                    return
                }
                if self.tempsRestant <= 0 {
                    self.valider(nil)
                    return
                }
            }
        }
    }

    private func valider(_ reponse: Int?) {
        guard case .question = phase, let question else { return }
        let secondes = Date().timeIntervalSince(debutQuestion)
        let avant = combat.camps.map { pvActifs($0) }
        let actifsAvant = combat.camps.map(\.indexActif)
        let campDefenseur = combat.camps[combat.defenseur]
        let joueurDefend = !campDefenseur.estIA
        let defenseurID = campDefenseur.actif.modele.id
        let attaquantID = combat.camps[combat.attaquant].actif.modele.id
        let joueurAttaquait = joueurAttaque
        var reponseQ: Int? = nil
        if questionneurRepond {
            reponseQ = combat.camps[combat.attaquant].estIA ? reponseQuestionneurIA : reponseAttaque
        }
        let aRepondu = reponseQ != nil
        let resultat = combat.resoudre(question: question, affinite: affinite,
                                       reponse: reponse, secondes: secondes,
                                       reponseQuestionneur: reponseQ, questionneurARepondu: aRepondu)
        if joueurAttaquait, resultat.questionneurCorrect == true {
            bonnesReponsesAttaqueParCombattant[attaquantID, default: 0] += 1
        }
        historique.append(resultat)
        if joueurDefend {
            let s = question.specialite
            reponsesJoueur.append(ReponseJouee(domaine: s.domaine, famille: s.famille, specialite: s.nom,
                                               specialiteID: s.id, correct: resultat.correct,
                                               secondes: secondes, tempsEcoule: reponse == nil,
                                               difficulte: question.difficulte,
                                               rang: reponsesJoueur.count + 1))
        }
        if joueurDefend && resultat.correct {
            bonnesReponsesJoueur += 1
            bonnesReponsesParCombattant[defenseurID, default: 0] += 1
        }
        for camp in combat.camps.indices {
            let delta = pvActifs(combat.camps[camp], apres: avant[camp].index) - avant[camp].pv
            if delta != 0 {
                variations[camp] = delta
                impacts[camp] += 1
            }
        }
        phase = .resultat(resultat)
        jouerSons(resultat, joueurDefend: joueurDefend)
        if combat.camps.map(\.indexActif) != actifsAvant, !combat.estTermine {
            ServiceSons.partage.jouer(.changement, apres: 1.0)
        }
    }

    /// Bruitages d'un tour : la réponse du joueur tout de suite, puis l'impact au moment où
    /// l'animation d'attaque touche (`TempsAttaque.arrivee`).
    private func jouerSons(_ resultat: ResultatTour, joueurDefend: Bool) {
        let sons = ServiceSons.partage
        if joueurDefend {
            if resultat.reponse == nil { sons.jouer(.tempsEcoule) }
            else if resultat.correct { sons.jouer(.bonneReponse) }
            else { sons.jouer(.mauvaiseReponse) }
            if resultat.correct, resultat.vitesse == .eclair { sons.jouer(.eclair, apres: 0.25) }
            if resultat.jaugeRemplie { sons.jouer(.jauge, apres: 0.5) }
        }
        let arrivee = TempsAttaque.arrivee
        if resultat.degatsAbsorbes > 0 { sons.jouer(.bouclier, apres: arrivee) }
        // Le coup lui-même (son d'attaque de la famille, ou impact seul) est joué par CombatView,
        // qui sait si l'animation d'attaque est montrée.
        if variations.contains(where: { $0 > 0 }) { sons.jouer(.soin, apres: arrivee) }
        if resultat.koDefenseur || resultat.koAttaquant { sons.jouer(.ko, apres: arrivee + 0.15) }
    }

    /// PV du combattant actif d'un camp (ou de celui d'un index donné), pour mesurer ce qu'il a gagné ou perdu.
    private func pvActifs(_ camp: Camp) -> (index: Int, pv: Int) {
        (camp.indexActif, camp.actif.pv)
    }

    private func pvActifs(_ camp: Camp, apres index: Int) -> Int {
        camp.combattants[index].pv
    }

    var estVictoire: Bool { combat.vainqueur == 0 }

    // MARK: - Fin de combat

    var titreFin: String {
        switch combat.vainqueur {
        case 0?: return "Victoire !"
        case 1?: return "Défaite"
        default: return "Match nul"
        }
    }

    /// Ce que rapporte le combat, d'après le tableau des gains du game design.
    var bilan: BilanCombat {
        var lignes: [LigneGain] = []
        switch combat.vainqueur {
        case 0?:
            lignes.append(LigneGain(libelle: "Victoire", pieces: Gains.piecesVictoire))
            let ko = combat.camps[1].nombreKO
            if ko > 0 {
                lignes.append(LigneGain(libelle: "Adversaires K.O. × \(ko)", pieces: Gains.piecesParKO * ko))
            }
        case 1?:
            lignes.append(LigneGain(libelle: "Défaite (consolation)", pieces: Gains.piecesDefaite))
        default:
            lignes.append(LigneGain(libelle: "Match nul", pieces: Gains.piecesNul))
        }
        if bonnesReponsesJoueur > 0 {
            lignes.append(LigneGain(libelle: "Bonnes réponses × \(bonnesReponsesJoueur)",
                                    pieces: Gains.piecesBonneReponse * bonnesReponsesJoueur))
        }
        let victoire = combat.vainqueur == 0
        let combattants = combat.camps[0].combattants.map { c -> GainCombattant in
            let bonnes = bonnesReponsesParCombattant[c.modele.id, default: 0]
            let enAttaque = bonnesReponsesAttaqueParCombattant[c.modele.id, default: 0]
            let xp = Gains.xpCombattantCombat + (victoire ? Gains.xpCombattantVictoire : 0)
                + Gains.xpCombattantBonneReponse * bonnes
                + Gains.xpCombattantBonneReponseAttaque * enAttaque
            return GainCombattant(modele: c.modele, bonnesReponses: bonnes, xp: xp)
        }
        return BilanCombat(lignes: lignes, xpCompte: xpCompteGagnee, combattants: combattants)
    }

    var piecesGagnees: Int { bilan.pieces }

    /// XP de compte gagnée (ou perdue si négative), selon le résultat et le niveau de l'IA.
    var xpCompteGagnee: Int {
        NiveauCompte.xp(vainqueur: combat.vainqueur, contre: ia.niveau)
    }
}
