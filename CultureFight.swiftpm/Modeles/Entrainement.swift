import Foundation
import SwiftData

/// Entraînement en solo d'un combattant (idée n° 14) : séances de 10 questions de sa spécialité,
/// répétition espacée des questions ratées, Savoir limité à 3 séances par jour, jauge de Maîtrise.
/// Les réponses restent ici, à part des statistiques de combat du profil.
struct EtatEntrainement: Codable, Sendable {
    /// Une question ratée, gardée telle quelle pour revenir aux séances suivantes.
    struct ARevoir: Codable, Sendable {
        let id: String
        let enonce: String
        let choix: [String]
        let bonneReponse: Int
        let explication: String
        let difficulte: Int
        var source: String? = nil
        /// Boîte de Leitner : 1 (revient à la séance suivante), 2 (dans 2 séances), 3 (dans 4 séances).
        var boite: Int
        /// Numéro de la séance où elle revient.
        var prochaineSeance: Int
    }

    var sues: [String] = []
    var aRevoir: [ARevoir] = []
    var seances = 0
    var jour = ""
    var seancesDuJour = 0

    static let questionsParSeance = 10
    static let seancesRecompenseesParJour = 3
    /// Séances d'attente selon la boîte : une question bien revue revient de plus en plus tard.
    static let espacement = [1: 1, 2: 2, 3: 4]
}

enum Entrainement {
    /// Savoir gagné par le combattant pour chaque bonne réponse, dans les 3 premières séances du jour.
    static let savoirParBonneReponse = 3

    static func etat(_ possede: CombattantPossede) -> EtatEntrainement {
        guard let data = possede.entrainementData,
              let etat = try? JSONDecoder().decode(EtatEntrainement.self, from: data) else { return EtatEntrainement() }
        return etat
    }

    static func ecrire(_ etat: EtatEntrainement, dans possede: CombattantPossede) {
        possede.entrainementData = try? JSONEncoder().encode(etat)
    }

    /// Nombre de questions à savoir pour 100 % de Maîtrise (au plus 100 pour les générateurs infinis).
    static func objectif(_ modele: ModeleCombattant) -> Int {
        var total = 0
        for tableau in modele.generateur.apercu {
            guard let n = tableau.nombreDeQuestions else { return 100 }
            total += n
        }
        return total > 0 ? min(total, 300) : 100
    }

    static func maitrise(_ possede: CombattantPossede, _ modele: ModeleCombattant) -> Double {
        min(1, Double(etat(possede).sues.count) / Double(objectif(modele)))
    }

    static func seancesRecompenseesRestantes(_ possede: CombattantPossede, maintenant: Date = Date()) -> Int {
        let e = etat(possede)
        let deja = e.jour == Boutique.cleJour(maintenant) ? e.seancesDuJour : 0
        return max(0, EtatEntrainement.seancesRecompenseesParJour - deja)
    }

    /// Les 10 questions d'une séance : d'abord les ratées qui reviennent, puis des nouvelles.
    static func seance(_ possede: CombattantPossede, _ modele: ModeleCombattant) -> [Question] {
        let e = etat(possede)
        let difficulte = Stade(niveau: possede.niveau).difficulte
        var file: [Question] = e.aRevoir
            .filter { $0.prochaineSeance <= e.seances }
            .sorted { $0.boite < $1.boite }
            .prefix(EtatEntrainement.questionsParSeance)
            .map { r in
                Question(id: r.id, specialite: modele.specialite, enonce: r.enonce, choix: r.choix.shuffled(),
                         bonneReponse: 0, difficulte: r.difficulte, explication: r.explication, source: r.source)
                    .avecBonneReponse(r.choix[r.bonneReponse])
            }
        var exclues = Set(e.sues).union(e.aRevoir.map(\.id))
        var essais = 0
        while file.count < EtatEntrainement.questionsParSeance, essais < 60 {
            essais += 1
            let q = modele.generateur.generer(difficulte: difficulte, exclues: exclues)
            guard !exclues.contains(q.id) || essais > 40 else { continue }
            guard !file.contains(where: { $0.id == q.id }) else { continue }
            exclues.insert(q.id)
            file.append(q)
        }
        return file
    }

    /// Enregistre une réponse : une question sue passe dans « sues » ; une ratée revient plus tard.
    static func repondre(_ question: Question, juste: Bool, possede: CombattantPossede) {
        var e = etat(possede)
        if let i = e.aRevoir.firstIndex(where: { $0.id == question.id }) {
            if juste {
                e.aRevoir[i].boite += 1
                if e.aRevoir[i].boite > 3 {
                    e.aRevoir.remove(at: i)
                    if !e.sues.contains(question.id) { e.sues.append(question.id) }
                } else {
                    e.aRevoir[i].prochaineSeance = e.seances + 1 + (EtatEntrainement.espacement[e.aRevoir[i].boite] ?? 1)
                }
            } else {
                e.aRevoir[i].boite = 1
                e.aRevoir[i].prochaineSeance = e.seances + 1
            }
        } else if juste {
            if !e.sues.contains(question.id) { e.sues.append(question.id) }
        } else {
            e.sues.removeAll { $0 == question.id }
            e.aRevoir.append(.init(id: question.id, enonce: question.enonce, choix: question.choix,
                                   bonneReponse: question.bonneReponse, explication: question.explication,
                                   difficulte: question.difficulte, source: question.source,
                                   boite: 1, prochaineSeance: e.seances + 1))
        }
        ecrire(e, dans: possede)
    }

    /// Fin de la séance : compte la séance et verse le Savoir si c'est l'une des 3 premières du jour.
    /// Renvoie le message de récompense.
    @MainActor
    static func terminer(reussies: Int, possede: CombattantPossede, dans contexte: ModelContext,
                         maintenant: Date = Date()) -> String {
        var e = etat(possede)
        let jour = Boutique.cleJour(maintenant)
        if e.jour != jour { e.jour = jour; e.seancesDuJour = 0 }
        let recompensee = e.seancesDuJour < EtatEntrainement.seancesRecompenseesParJour
        e.seances += 1
        e.seancesDuJour += 1
        ecrire(e, dans: possede)
        var message = "Séance terminée."
        if recompensee, reussies > 0 {
            let gain = savoirParBonneReponse * reussies
            let niveaux = possede.gagnerXP(gain)
            message = "+\(gain) Savoir pour \(possede.modele?.nom ?? "ton combattant")"
                + (niveaux > 0 ? ", niveau +\(niveaux) !" : ".")
        } else if !recompensee {
            message = "Séance sans Savoir : les 3 séances récompensées du jour sont faites."
        }
        Sauvegarde.enregistrer(contexte)
        return message
    }
}

extension Question {
    /// La même question, avec l'index de la bonne réponse retrouvé après mélange des choix.
    func avecBonneReponse(_ texte: String) -> Question {
        Question(id: id, specialite: specialite, enonce: enonce, choix: choix,
                 bonneReponse: choix.firstIndex(of: texte) ?? 0, difficulte: difficulte, explication: explication,
                 source: source)
    }
}
