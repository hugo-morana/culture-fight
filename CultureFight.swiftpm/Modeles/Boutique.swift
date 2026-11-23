import SwiftUI
import SwiftData

// MARK: - Objets

/// Un équipement permanent ou un consommable, d'après le tableau « Équipements » du game design.
struct Objet: Identifiable, Hashable, Sendable {
    enum Genre: String, Sendable {
        case permanent = "Équipement"
        case consommable = "Consommable"
    }

    let id: String
    let nom: String
    let genre: Genre
    let effet: String
    let prix: Int
    let symbole: String

    /// Les consommables se vendent par 3.
    var quantite: Int { genre == .consommable ? 3 : 1 }
}

extension Rarete {
    var couleur: Color {
        switch self {
        case .commun: return Color(red: 0.62, green: 0.66, blue: 0.72)
        case .rare: return Color(red: 0.36, green: 0.62, blue: 1.0)
        case .epique: return Color(red: 0.72, green: 0.42, blue: 1.0)
        case .legendaire: return Color(red: 1.0, green: 0.72, blue: 0.2)
        }
    }
}

// MARK: - Règles de la boutique

/// La boutique : un catalogue fixe des Communs, plus 4 articles tirés au sort chaque jour
/// (combattants de toutes raretés et objets), ouverts à partir du niveau de compte 3.
enum Boutique {
    static let niveauOffreDuJour = 3
    static let tailleOffre = 4

    /// Prix de référence d'une rareté (milieu de sa fourchette).
    static func prix(_ rarete: Rarete) -> Int {
        let f = fourchette(rarete)
        return (f.lowerBound + f.upperBound) / 2
    }

    /// Fourchette de prix d'une rareté (game design, « Prix de la boutique »).
    static func fourchette(_ rarete: Rarete) -> ClosedRange<Int> {
        switch rarete {
        case .commun: return 100...200
        case .rare: return 300...500
        case .epique: return 800...1200
        case .legendaire: return 2000...3000
        }
    }

    /// Puissance d'un combattant : PV + 2 × Attaque + 5 × Défense + 15 × difficulté de ses questions.
    static func puissance(_ m: ModeleCombattant) -> Int {
        m.pvMax + 2 * m.attaque + 5 * m.defense + 15 * m.difficulte
    }

    private static let bornesPuissance: [Rarete: ClosedRange<Int>] = {
        var bornes: [Rarete: ClosedRange<Int>] = [:]
        for m in Catalogue.prototype {
            let p = puissance(m)
            if let b = bornes[m.rarete] {
                bornes[m.rarete] = min(b.lowerBound, p)...max(b.upperBound, p)
            } else {
                bornes[m.rarete] = p...p
            }
        }
        return bornes
    }()

    /// Prix d'un combattant : sa rareté fixe la fourchette, sa puissance la place dedans (arrondi à 10).
    /// Un Équilibré de difficulté 2 est au milieu ; le plus faible au bas, le plus fort en haut.
    static func prix(_ m: ModeleCombattant) -> Int {
        let f = fourchette(m.rarete)
        let milieu = Double(f.lowerBound + f.upperBound) / 2
        guard let b = bornesPuissance[m.rarete], let ref = ProfilStats.reference(m.rarete) else {
            return prix(m.rarete)
        }
        let p = Double(puissance(m))
        let r = Double(ref.pv + 2 * ref.attaque + 5 * ref.defense + 15 * 2)
        var brut = milieu
        if p > r, Double(b.upperBound) > r {
            brut = milieu + (p - r) / (Double(b.upperBound) - r) * (Double(f.upperBound) - milieu)
        } else if p < r, Double(b.lowerBound) < r {
            brut = milieu - (r - p) / (r - Double(b.lowerBound)) * (milieu - Double(f.lowerBound))
        }
        return min(f.upperBound, max(f.lowerBound, Int((brut / 10).rounded()) * 10))
    }

    /// Réduction de l'offre du jour, de 20 à 40 % par pas de 5, tirée avec la date et l'article.
    static func remise(_ article: Article, jour: String) -> Int {
        var g = GenerateurDuJour(graine: jour + article.id)
        return 20 + Int(g.next() % 5) * 5
    }

    /// Prix réduit d'un article de l'offre du jour (arrondi à 5).
    static func prixOffre(_ article: Article, jour: String) -> Int {
        prixReduit(article.prix, remise: remise(article, jour: jour))
    }

    static func prixReduit(_ prix: Int, remise: Int) -> Int {
        max(5, Int((Double(prix) * Double(100 - remise) / 500).rounded()) * 5)
    }

    /// Prix payé pour un article, selon qu'il est acheté dans l'offre du jour ou au catalogue.
    static func prixPaye(_ article: Article, offreDuJour: Bool, date: Date = Date()) -> Int {
        offreDuJour ? prixOffre(article, jour: cleJour(date)) : article.prix
    }

    /// Un doublon (combattant déjà possédé) est converti en XP pour ce combattant : la moitié de son prix.
    static func xpDoublon(_ rarete: Rarete) -> Int { prix(rarete) / 2 }

    static let objets: [Objet] = [
        Objet(id: "blouse-renforcee", nom: "Blouse renforcée", genre: .permanent, effet: "+4 Défense",
              prix: 120, symbole: "tshirt.fill"),
        Objet(id: "encyclopedie", nom: "Encyclopédie", genre: .permanent, effet: "+5 Attaque",
              prix: 150, symbole: "books.vertical.fill"),
        Objet(id: "sablier", nom: "Sablier", genre: .permanent, effet: "+5 s pour répondre",
              prix: 100, symbole: "hourglass"),
        Objet(id: "amulette-de-vie", nom: "Amulette de vie", genre: .permanent, effet: "+20 PV max",
              prix: 200, symbole: "heart.circle.fill"),
        Objet(id: "lunettes-de-savant", nom: "Lunettes de savant", genre: .permanent,
              effet: "Jauge d'Inspiration remplie en 2 bonnes réponses", prix: 180, symbole: "eyeglasses"),
        Objet(id: "joker", nom: "Joker 50/50", genre: .consommable, effet: "Retire 2 mauvaises réponses",
              prix: 60, symbole: "circle.lefthalf.filled"),
        Objet(id: "potion", nom: "Potion", genre: .consommable, effet: "Rend 30 PV au combattant actif",
              prix: 60, symbole: "flask.fill"),
        Objet(id: "bouclier", nom: "Bouclier", genre: .consommable, effet: "Annule les dégâts de la prochaine erreur",
              prix: 60, symbole: "shield.lefthalf.filled"),
        Objet(id: "changement-question", nom: "Changement de question", genre: .consommable,
              effet: "Tire une autre question", prix: 60, symbole: "arrow.triangle.2.circlepath"),
        Objet(id: "loupe-du-sage", nom: "Loupe du sage", genre: .permanent,
              effet: "Questions reçues par ce combattant : difficulté −1", prix: 220, symbole: "magnifyingglass"),
        Objet(id: "couronne-du-savant", nom: "Couronne du savant", genre: .permanent,
              effet: "Questions posées par ce combattant : difficulté +1, mais −10 PV max", prix: 220,
              symbole: "crown.fill"),
        Objet(id: "parchemin-simplification", nom: "Parchemin de simplification", genre: .consommable,
              effet: "Les 3 prochaines questions de l'adversaire : difficulté −1", prix: 80, symbole: "scroll.fill"),
        Objet(id: "elixir-surcharge", nom: "Élixir de surcharge", genre: .consommable,
              effet: "Tes 3 prochaines questions : difficulté +1", prix: 80, symbole: "drop.triangle.fill"),
    ]

    static func objet(_ id: String) -> Objet? { objets.first { $0.id == id } }

    /// Le catalogue fixe : tous les combattants Communs.
    static var communs: [ModeleCombattant] { Catalogue.prototype.filter { $0.rarete == .commun } }

    // MARK: Offre du jour

    /// Un article de la boutique.
    enum Article: Identifiable, Hashable {
        case combattant(String)
        case objet(Objet)

        var id: String {
            switch self {
            case .combattant(let id): return "combattant:\(id)"
            case .objet(let objet): return "objet:\(objet.id)"
            }
        }

        var modele: ModeleCombattant? {
            guard case .combattant(let id) = self else { return nil }
            return Catalogue.prototype.first { $0.id == id }
        }

        var prix: Int {
            switch self {
            case .combattant: return modele.map { Boutique.prix($0) } ?? 0
            case .objet(let objet): return objet.prix
            }
        }

        var nom: String {
            switch self {
            case .combattant: return modele?.nom ?? "?"
            case .objet(let objet): return objet.genre == .consommable ? "\(objet.nom) × 3" : objet.nom
            }
        }
    }

    /// Clé du jour (« 2026-11-20 »), dans le fuseau de l'appareil.
    static func cleJour(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Prochain renouvellement : minuit.
    static func prochainRenouvellement(apres date: Date = Date()) -> Date {
        Calendar.current.nextDate(after: date, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)
            ?? date.addingTimeInterval(24 * 3600)
    }

    /// Les 4 articles du jour : 2 combattants et 2 objets, tirés avec une graine qui ne dépend que du jour.
    /// L'offre reste donc la même toute la journée, même après un achat ou une relance de l'app.
    static func offreDuJour(_ date: Date = Date()) -> [Article] {
        var generateur = GenerateurDuJour(graine: cleJour(date))
        // Les combattants rares sortent deux fois plus souvent que les Communs (qui sont déjà au catalogue).
        var urne: [ModeleCombattant] = []
        for modele in Catalogue.prototype {
            urne.append(contentsOf: Array(repeating: modele, count: modele.rarete == .commun ? 1 : 2))
        }
        var combattants: [String] = []
        while combattants.count < 2, !urne.isEmpty {
            let tire = urne[Int(generateur.next() % UInt64(urne.count))]
            if !combattants.contains(tire.id) { combattants.append(tire.id) }
            urne.removeAll { $0.id == tire.id }
        }
        var restants = objets
        var tires: [Objet] = []
        while tires.count < tailleOffre - combattants.count, !restants.isEmpty {
            tires.append(restants.remove(at: Int(generateur.next() % UInt64(restants.count))))
        }
        return combattants.map { .combattant($0) } + tires.map { .objet($0) }
    }

    // MARK: Achat

    enum ResultatAchat: Equatable {
        case nouveauCombattant(String)
        /// Combattant déjà possédé : XP gagnée et niveaux gagnés.
        case doublon(String, xp: Int, niveaux: Int)
        case objet(String, quantite: Int)
        case refuse(String)
    }

    /// Ce que l'achat donnerait, pour le bouton et la confirmation.
    static func libelleAchat(_ article: Article, offreDuJour: Bool = false, pour joueur: Joueur) -> String {
        if let modele = article.modele, joueur.possede(modele.id) {
            return "Déjà possédé : +\(xpDoublon(modele.rarete)) Savoir pour \(modele.nom)"
        }
        if offreDuJour {
            return "\(prixPaye(article, offreDuJour: true)) Pièces au lieu de \(article.prix) (−\(remise(article, jour: cleJour())) %)"
        }
        return "\(article.prix) Pièces"
    }

    @MainActor
    static func acheter(_ article: Article, offreDuJour: Bool, joueur: Joueur, dans contexte: ModelContext,
                        maintenant: Date = Date()) -> ResultatAchat {
        let jour = cleJour(maintenant)
        if joueur.jourAchats != jour {
            joueur.jourAchats = jour
            joueur.achatsDuJour = []
        }
        if offreDuJour {
            guard joueur.niveauCompte >= niveauOffreDuJour else {
                return .refuse("L'offre du jour s'ouvre au niveau \(niveauOffreDuJour).")
            }
            guard !joueur.achatsDuJour.contains(article.id) else {
                return .refuse("Déjà acheté aujourd'hui.")
            }
        }
        let prix = prixPaye(article, offreDuJour: offreDuJour, date: maintenant)
        guard joueur.pieces >= prix else {
            return .refuse("Il te manque \(prix - joueur.pieces) Pièces.")
        }

        let resultat: ResultatAchat
        switch article {
        case .combattant(let id):
            guard let modele = article.modele else { return .refuse("Combattant introuvable.") }
            if let possede = joueur.reserve.first(where: { $0.modeleID == id }) {
                guard offreDuJour else { return .refuse("Tu as déjà \(modele.nom).") }
                let xp = xpDoublon(modele.rarete)
                resultat = .doublon(id, xp: xp, niveaux: possede.gagnerXP(xp))
            } else {
                joueur.ajouter(id)
                resultat = .nouveauCombattant(id)
            }
        case .objet(let objet):
            joueur.inventaire[objet.id, default: 0] += objet.quantite
            resultat = .objet(objet.id, quantite: objet.quantite)
        }
        joueur.pieces -= prix
        if offreDuJour { joueur.achatsDuJour.append(article.id) }
        Sauvegarde.enregistrer(contexte)
        return resultat
    }
}

/// Générateur pseudo-aléatoire SplitMix64 à graine fixe : même graine, même tirage sur tous les appareils.
struct GenerateurDuJour: RandomNumberGenerator {
    private var etat: UInt64

    init(graine: String) {
        // Hachage FNV-1a de la graine (stable, contrairement à `hashValue`).
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for octet in graine.utf8 {
            h ^= UInt64(octet)
            h = h &* 0x0000_0100_0000_01B3
        }
        etat = h
    }

    mutating func next() -> UInt64 {
        etat &+= 0x9E37_79B9_7F4A_7C15
        var z = etat
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
