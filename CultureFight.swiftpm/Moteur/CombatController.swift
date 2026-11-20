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

    let ia: IAAdverse
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

    init(equipeJoueur: [ModeleCombattant], equipeIA: [ModeleCombattant], ia: IAAdverse) {
        self.ia = ia
        self.combat = Combat(camps: [
            Camp(nom: "Toi", estIA: false, equipe: equipeJoueur),
            Camp(nom: "IA \(ia.niveau.rawValue.lowercased())", estIA: true, equipe: equipeIA),
        ])
    }

    var estFini: Bool {
        if case .fin = phase { return true }
        return false
    }

    /// Le joueur répond-il à la question en cours ?
    var joueurRepond: Bool { !combat.camps[combat.defenseur].estIA }

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

    // MARK: - Déroulé

    private func nouveauTour() {
        tache?.cancel()
        guard !combat.estTermine else {
            phase = .fin
            return
        }
        let tirage = combat.preparerQuestion()
        question = tirage.question
        affinite = tirage.affinite
        retires = tirage.retires
        malusTemps = combat.consommerMalusTemps()
        tempsTotal = max(Regles.tempsMin, Regles.tempsReponse + tirage.affinite.bonusTemps - malusTemps)
        tempsRestant = tempsTotal
        phase = .question

        let reponseIA: Int? = combat.camps[combat.defenseur].estIA
            ? ia.repondre(question: tirage.question, affinite: tirage.affinite, retires: tirage.retires)
            : nil
        let delaiIA = min(ia.delaiReponse(), tempsTotal - 0.5)
        let debut = Date()
        debutQuestion = debut

        tache = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, !Task.isCancelled else { return }
                let ecoule = Date().timeIntervalSince(debut)
                self.tempsRestant = max(0, self.tempsTotal - ecoule)
                if let reponseIA, ecoule >= delaiIA {
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
        let campDefenseur = combat.camps[combat.defenseur]
        let joueurDefend = !campDefenseur.estIA
        let defenseurID = campDefenseur.actif.modele.id
        let resultat = combat.resoudre(question: question, affinite: affinite,
                                       reponse: reponse, secondes: secondes)
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
            let xp = Gains.xpCombattantCombat + (victoire ? Gains.xpCombattantVictoire : 0)
                + Gains.xpCombattantBonneReponse * bonnes
            return GainCombattant(modele: c.modele, bonnesReponses: bonnes, xp: xp)
        }
        return BilanCombat(lignes: lignes, xpCompte: xpCompteGagnee, combattants: combattants)
    }

    var piecesGagnees: Int { bilan.pieces }

    /// XP de compte gagnée : +10 par combat terminé, +20 de plus en cas de victoire.
    var xpCompteGagnee: Int {
        NiveauCompte.xpCombat + (combat.vainqueur == 0 ? NiveauCompte.xpVictoire : 0)
    }
}
