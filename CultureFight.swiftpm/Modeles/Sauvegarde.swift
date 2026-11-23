import Foundation
import SwiftData

// MARK: - Modèles sauvegardés

/// Le joueur : ses Pièces, sa réserve de combattants et son bilan. Un seul par appareil.
///
/// Chaque propriété a une valeur par défaut : SwiftData peut ainsi ajouter un champ dans une
/// version suivante sans perdre la sauvegarde (migration automatique).
@Model
final class Joueur {
    var pieces: Int = 0
    var niveauCompte: Int = 1
    /// XP de compte réunie depuis le dernier passage de niveau.
    var xpCompte: Int = 0
    var combatsJoues: Int = 0
    var victoires: Int = 0
    var defaites: Int = 0
    var nuls: Int = 0
    var dateCreation: Date = Date()
    /// Consommables possédés (identifiant de l'objet → quantité).
    var inventaire: [String: Int] = [:]
    /// Dernière ouverture du coffre gratuit (toutes les 4 heures).
    var dernierCoffre: Date?
    /// Articles de l'offre du jour déjà achetés (identifiants d'article), pour le jour `jourAchats`.
    var achatsDuJour: [String] = []
    var jourAchats: String = ""

    @Relationship(deleteRule: .cascade, inverse: \CombattantPossede.joueur)
    var reserve: [CombattantPossede] = []

    /// Toutes les parties jouées par ce joueur.
    @Relationship(deleteRule: .cascade, inverse: \PartieJouee.joueur)
    var parties: [PartieJouee] = []

    /// Les parties, de la plus récente à la plus ancienne.
    var historique: [PartieJouee] { parties.sorted { $0.date > $1.date } }

    init() {}

    /// Les combattants de la réserve, dans l'ordre du catalogue.
    var modelesReserve: [ModeleCombattant] {
        let ids = Set(reserve.map(\.modeleID))
        return Catalogue.tous.filter { ids.contains($0.id) }
    }

    func possede(_ modeleID: String) -> Bool {
        reserve.contains { $0.modeleID == modeleID }
    }

    /// Ajoute un combattant à la réserve, sauf s'il y est déjà. Renvoie vrai s'il a été ajouté.
    @discardableResult
    func ajouter(_ modeleID: String) -> Bool {
        guard !possede(modeleID) else { return false }
        reserve.append(CombattantPossede(modeleID: modeleID))
        return true
    }

    var idsPossedes: Set<String> { Set(reserve.map(\.modeleID)) }

    /// Bonus de PV des familles complètes, par combattant.
    var bonusPV: [String: Int] { Recompenses.bonusPV(idsPossedes) }

    /// Ajoute à la réserve les Légendaires des domaines complets ; renvoie ceux qui viennent d'arriver.
    @discardableResult
    func attribuerLegendaires() -> [ModeleCombattant] {
        let dus = Recompenses.legendairesDus(idsPossedes)
        for m in dus { _ = ajouter(m.id) }
        return dus
    }
}

/// Un combattant de la réserve du joueur. Nom, spécialité et statistiques de base restent dans
/// le catalogue ; seule la progression propre au joueur est sauvegardée.
@Model
final class CombattantPossede {
    /// Identifiant du combattant dans le catalogue (`ModeleCombattant.id`).
    var modeleID: String = ""
    var niveau: Int = 1
    var xp: Int = 0
    var equipementID: String?
    /// Tactique : profil de difficulté des questions (`ProfilDifficulte.rawValue`).
    var tactique: String = "aleatoire"
    var dateObtention: Date = Date()
    var joueur: Joueur?
    /// Entraînement en solo (`EtatEntrainement` encodé) : questions sues, questions à revoir, séances.
    var entrainementData: Data?

    init(modeleID: String) {
        self.modeleID = modeleID
    }

    var modele: ModeleCombattant? {
        Catalogue.modele(modeleID)
    }
}

// MARK: - Chargement et enregistrement

@MainActor
enum Sauvegarde {
    /// Pendant le prototype, avant la boutique, tous les combattants du catalogue étaient offerts.
    /// Depuis la boutique (tâche 24), un nouveau joueur reçoit seulement les 3 Communs de
    /// `reserveDeDepart` et achète les autres. Les joueurs existants gardent ce qu'ils ont.
    static let toutOffertPendantLePrototype = false

    /// Réserve de départ (retour bêta n° 10) : 6 Communs tirés au sort à la création du joueur,
    /// de 6 domaines différents, dont au moins 2 de la même famille de styles (une synergie à viser),
    /// aux questions faciles (spécialité Facile ou Moyenne, difficulté 2 au plus).
    static let tailleReserveDeDepart = 6

    /// Vrai si le joueur vient d'être créé pendant ce lancement : le paquet de départ s'ouvre alors.
    private(set) static var nouveauJoueur = false

    static func tirerReserveDeDepart() -> [String] {
        let eligibles = Catalogue.prototype.filter {
            $0.rarete == .commun && $0.note != .pointue && $0.difficulte <= 2
        }
        for _ in 0..<200 {
            // Une famille de styles qui a au moins 2 combattants dans des domaines différents.
            guard let paire = eligibles.shuffled().first(where: { m in
                eligibles.contains { $0.familleStyle == m.familleStyle && $0.specialite.domaine != m.specialite.domaine }
            }), let second = eligibles.shuffled().first(where: {
                $0.familleStyle == paire.familleStyle && $0.specialite.domaine != paire.specialite.domaine
            }) else { break }
            var choisis = [paire, second]
            for m in eligibles.shuffled() where choisis.count < tailleReserveDeDepart {
                if !choisis.contains(where: { $0.specialite.domaine == m.specialite.domaine }) { choisis.append(m) }
            }
            if choisis.count == tailleReserveDeDepart { return choisis.map(\.id) }
        }
        return Array(eligibles.shuffled().prefix(tailleReserveDeDepart)).map(\.id)
    }

    /// Le conteneur SwiftData de l'app. Si la sauvegarde ne peut pas être ouverte, l'app démarre
    /// quand même avec une sauvegarde en mémoire (perdue à la fermeture) plutôt que de planter.
    static let conteneur: ModelContainer = {
        let schema = Schema([Joueur.self, CombattantPossede.self, PartieJouee.self])
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            print("Sauvegarde illisible, démarrage sans sauvegarde : \(error)")
            return try! ModelContainer(for: schema,
                                       configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
    }()

    /// Le joueur enregistré, créé au premier lancement. Complète sa réserve si de nouveaux
    /// combattants offerts sont apparus dans le catalogue depuis la dernière version.
    static func joueur(dans contexte: ModelContext) -> Joueur {
        let existants = (try? contexte.fetch(FetchDescriptor<Joueur>(sortBy: [SortDescriptor(\.dateCreation)]))) ?? []
        let joueur: Joueur
        if let premier = existants.first {
            joueur = premier
        } else {
            joueur = Joueur()
            contexte.insert(joueur)
            tirerReserveDeDepart().forEach { joueur.ajouter($0) }
            nouveauJoueur = true
        }
        if toutOffertPendantLePrototype {
            Catalogue.prototype.forEach { joueur.ajouter($0.id) }
        }
        // Parties enregistrées avant l'historique par joueur : rattachées au joueur de l'appareil.
        let parties = (try? contexte.fetch(FetchDescriptor<PartieJouee>())) ?? []
        for partie in parties where partie.joueur == nil {
            partie.joueur = joueur
        }
        // Domaines renommés (« Savoirs » devient « Maths et techniques », « Monde » devient « Pays et cultures ») : l'historique suit le nouveau nom.
        for partie in parties where partie.reponses.contains(where: { Domaines.anciensNoms[$0.domaine] != nil }) {
            partie.reponses = partie.reponses.map { r in
                var r = r
                r.domaine = Domaines.nomActuel(r.domaine)
                return r
            }
        }
        enregistrer(contexte)
        return joueur
    }

    /// Verse les gains d'un combat terminé, une seule fois par combat.
    static func crediter(_ controleur: CombatController, a joueur: Joueur, dans contexte: ModelContext) {
        guard controleur.estFini, controleur.marquerGainsVerses() else { return }
        let partie = controleur.partieJouee()
        retirerObjets(controleur, de: joueur)
        joueur.combatsJoues += 1
        switch controleur.combat.vainqueur {
        case 0?: joueur.victoires += 1
        case 1?: joueur.defaites += 1
        default: joueur.nuls += 1
        }
        let bilan = controleur.bilan
        joueur.pieces += bilan.pieces
        controleur.savoirAvant = NiveauCompte.savoirTotal(niveau: joueur.niveauCompte, xp: joueur.xpCompte)
        controleur.niveauxCompteGagnes = joueur.gagnerXPCompte(bilan.xpCompte)
        controleur.savoirApres = NiveauCompte.savoirTotal(niveau: joueur.niveauCompte, xp: joueur.xpCompte)
        var niveaux: [String: Int] = [:]
        var evolutions: [EvolutionCombattant] = []
        for gain in bilan.combattants {
            guard let possede = joueur.reserve.first(where: { $0.modeleID == gain.modele.id }) else { continue }
            let avant = possede.stade
            let n = possede.gagnerXP(gain.xp)
            if n > 0 { niveaux[gain.modele.id] = n }
            if possede.stade > avant {
                evolutions.append(EvolutionCombattant(modele: gain.modele, avant: avant, apres: possede.stade))
            }
        }
        controleur.niveauxGagnes = niveaux
        controleur.evolutions = evolutions
        partie.pieces = bilan.pieces
        partie.xpCompte = bilan.xpCompte
        partie.niveauCompteApres = joueur.niveauCompte
        joueur.parties.append(partie)
        enregistrer(contexte)
    }

    /// Ouvre le coffre gratuit s'il est prêt : renvoie les Pièces gagnées, ou nil s'il faut attendre.
    static func ouvrirCoffre(_ joueur: Joueur, dans contexte: ModelContext, maintenant: Date = Date()) -> Int? {
        guard maintenant >= Gains.prochainCoffre(apres: joueur.dernierCoffre) else { return nil }
        let pieces = Int.random(in: Gains.coffre)
        joueur.pieces += pieces
        joueur.dernierCoffre = maintenant
        enregistrer(contexte)
        return pieces
    }

    /// Un abandon compte comme une défaite, sans Pièces : il coûte l'XP de compte d'une défaite.
    static func abandon(_ controleur: CombatController, de joueur: Joueur, dans contexte: ModelContext) {
        guard controleur.marquerGainsVerses() else { return }
        let partie = controleur.partieJouee(abandon: true)
        retirerObjets(controleur, de: joueur)
        joueur.combatsJoues += 1
        joueur.defaites += 1
        let xp = NiveauCompte.xpDefaite(contre: controleur.ia.niveau)
        controleur.savoirAvant = NiveauCompte.savoirTotal(niveau: joueur.niveauCompte, xp: joueur.xpCompte)
        controleur.niveauxCompteGagnes = joueur.gagnerXPCompte(xp)
        controleur.savoirApres = NiveauCompte.savoirTotal(niveau: joueur.niveauCompte, xp: joueur.xpCompte)
        partie.xpCompte = xp
        partie.niveauCompteApres = joueur.niveauCompte
        joueur.parties.append(partie)
        enregistrer(contexte)
    }

    /// Retire de l'inventaire les consommables utilisés pendant le combat.
    static func retirerObjets(_ controleur: CombatController, de joueur: Joueur) {
        for id in controleur.objetsUtilises {
            joueur.inventaire[id] = max(0, (joueur.inventaire[id] ?? 0) - 1)
        }
    }

    /// Bouton caché des testeurs : efface toute la sauvegarde et les réglages de jeu de l'appareil,
    /// puis recrée un joueur neuf (avec un nouveau paquet de départ).
    static func remettreAZero(dans contexte: ModelContext) -> Joueur {
        try? contexte.delete(model: PartieJouee.self)
        try? contexte.delete(model: CombattantPossede.self)
        try? contexte.delete(model: Joueur.self)
        try? contexte.save()
        for cle in ["tenuesPortees", "tenuesVersion", "titrePorte", "derniereEquipe", "paquetDepartOuvert"] {
            UserDefaults.standard.removeObject(forKey: cle)
        }
        return joueur(dans: contexte)
    }

    static func enregistrer(_ contexte: ModelContext) {
        guard contexte.hasChanges else { return }
        do {
            try contexte.save()
        } catch {
            print("Échec de l'enregistrement : \(error)")
        }
    }
}
