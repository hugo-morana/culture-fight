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

    @Relationship(deleteRule: .cascade, inverse: \CombattantPossede.joueur)
    var reserve: [CombattantPossede] = []

    init() {}

    /// Les combattants de la réserve, dans l'ordre du catalogue.
    var modelesReserve: [ModeleCombattant] {
        let ids = Set(reserve.map(\.modeleID))
        return Catalogue.prototype.filter { ids.contains($0.id) }
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
    var dateObtention: Date = Date()
    var joueur: Joueur?

    init(modeleID: String) {
        self.modeleID = modeleID
    }

    var modele: ModeleCombattant? {
        Catalogue.prototype.first { $0.id == modeleID }
    }
}

// MARK: - Chargement et enregistrement

@MainActor
enum Sauvegarde {
    /// Pendant le prototype, tous les combattants du catalogue sont offerts (la boutique n'existe pas
    /// encore). Passer à `false` quand la boutique arrive : un nouveau joueur reçoit alors seulement
    /// les combattants de `reserveDeDepart`, comme prévu dans le game design.
    static let toutOffertPendantLePrototype = true

    /// Les 3 combattants Communs offerts au niveau de compte 1.
    static let reserveDeDepart = ["neonja", "mendeleviking", "iodiateur"]

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
            reserveDeDepart.forEach { joueur.ajouter($0) }
        }
        if toutOffertPendantLePrototype {
            Catalogue.prototype.forEach { joueur.ajouter($0.id) }
        }
        enregistrer(contexte)
        return joueur
    }

    /// Verse les gains d'un combat terminé, une seule fois par combat.
    static func crediter(_ controleur: CombatController, a joueur: Joueur, dans contexte: ModelContext) {
        guard controleur.estFini, controleur.marquerGainsVerses() else { return }
        contexte.insert(controleur.partieJouee())
        joueur.combatsJoues += 1
        switch controleur.combat.vainqueur {
        case 0?: joueur.victoires += 1
        case 1?: joueur.defaites += 1
        default: joueur.nuls += 1
        }
        let bilan = controleur.bilan
        joueur.pieces += bilan.pieces
        controleur.niveauxCompteGagnes = joueur.gagnerXPCompte(bilan.xpCompte)
        var niveaux: [String: Int] = [:]
        for gain in bilan.combattants {
            guard let possede = joueur.reserve.first(where: { $0.modeleID == gain.modele.id }) else { continue }
            let n = possede.gagnerXP(gain.xp)
            if n > 0 { niveaux[gain.modele.id] = n }
        }
        controleur.niveauxGagnes = niveaux
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
        contexte.insert(controleur.partieJouee(abandon: true))
        joueur.combatsJoues += 1
        joueur.defaites += 1
        controleur.niveauxCompteGagnes = joueur.gagnerXPCompte(NiveauCompte.xpDefaite(contre: controleur.ia.niveau))
        enregistrer(contexte)
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
