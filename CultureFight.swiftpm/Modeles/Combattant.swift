import Foundation

enum Rarete: String, Sendable {
    case commun = "Commun"
    case rare = "Rare"
    case epique = "Épique"
    case legendaire = "Légendaire"
}

/// Un combattant tel qu'il existe dans le catalogue.
struct ModeleCombattant: Identifiable, Sendable {
    let id: String
    let nom: String
    let style: String
    /// Famille de styles : décide de l'effet du bonus de vitesse.
    let familleStyle: FamilleStyle
    let specialite: Specialite
    let rarete: Rarete
    let pvMax: Int
    let attaque: Int
    let defense: Int
    /// Difficulté des questions qu'il pose (1 à 5).
    let difficulte: Int
    let apparence: String
    /// Sur quoi portent ses questions, affiché dans le choix de l'équipe.
    let questions: String
    let generateur: any GenerateurQuestions

    /// Une question tirée au hasard, pour montrer le genre de questions posées.
    func exempleDeQuestion() -> String {
        generateur.generer(difficulte: difficulte, exclues: []).enonce
    }

    var initiales: String {
        String(nom.prefix(2)).uppercased()
    }
}

/// Un combattant pendant un combat.
struct CombattantEnJeu: Identifiable, Sendable {
    let id = UUID()
    let modele: ModeleCombattant
    var pv: Int
    /// Jauge de Savoir : se remplit d'une case par bonne réponse.
    var jauge: Int = 0
    /// Jauge pleine : sa prochaine attaque réussie fera double dégâts.
    var capacitePrete: Bool = false
    /// Part des dégâts absorbée à la prochaine erreur (effet « Bouclier »), 0 si aucun.
    var bouclier: Double = 0
    /// Tactique : évolution de la difficulté des questions qu'il pose.
    var profil: ProfilDifficulte = .aleatoire
    /// Nombre de questions déjà posées par ce combattant dans le combat.
    var questionsPosees = 0

    /// Niveau du combattant (1 à 20) : fixe ses statistiques et son stade d'évolution.
    var niveau: Int = 1
    /// Équipement permanent porté (identifiant d'objet de la boutique), ou nil.
    var equipement: String?
    /// PV en plus de la famille complète (récompense d'album).
    var bonusPV = 0
    /// Bouclier des Chevaliers : PV de dégâts absorbés, donné au combattant qui entre après un K.O.
    var absorption = 0
    /// Riposte : multiplicateur de la prochaine attaque (1 = aucune), gagné par une bonne réponse rapide.
    var riposte: Double = 1

    /// Retire des dégâts ce que le bouclier des Chevaliers absorbe, et renvoie le reste.
    mutating func absorber(_ degats: Int) -> Int {
        let absorbe = min(absorption, degats)
        absorption -= absorbe
        return degats - absorbe
    }

    init(modele: ModeleCombattant, profil: ProfilDifficulte = .aleatoire, niveau: Int = 1, equipement: String? = nil,
         bonusPV: Int = 0) {
        self.modele = modele
        self.bonusPV = bonusPV
        self.niveau = max(1, niveau)
        self.profil = profil
        self.equipement = equipement
        self.pv = 0
        self.pv = pvMax
    }

    var stade: Stade { Stade(niveau: niveau) }
    var pvMax: Int {
        var pv = Progression.pv(modele, niveau: niveau) + bonusPV
        if equipement == "amulette-de-vie" { pv += 20 }
        if equipement == "couronne-du-savant" { pv -= 10 }
        return pv
    }
    var attaque: Int { Progression.attaque(modele, niveau: niveau) + (equipement == "encyclopedie" ? 5 : 0) }
    var defense: Int { Progression.defense(modele, niveau: niveau) + (equipement == "blouse-renforcee" ? 4 : 0) }
    /// Cases de jauge de Savoir à remplir (2 avec les Lunettes de savant).
    var jaugeMax: Int { equipement == "lunettes-de-savant" ? 2 : Regles.jaugeMax }
    /// Secondes en plus pour répondre (Sablier).
    var bonusTemps: Double { equipement == "sablier" ? 5 : 0 }
    /// Nom avec le stade : « Méso-Néonja ».
    var nom: String { stade.nom(de: modele.nom) }

    var estKO: Bool { pv <= 0 }
}

/// Une équipe de 3 combattants et celui qui est en jeu.
struct Camp: Sendable {
    let nom: String
    let estIA: Bool
    var combattants: [CombattantEnJeu]
    var indexActif: Int = 0

    init(nom: String, estIA: Bool, equipe: [ModeleCombattant], profils: [String: ProfilDifficulte] = [:],
         niveaux: [String: Int] = [:], niveauParDefaut: Int = 1, equipements: [String: String] = [:],
         bonusPV: [String: Int] = [:]) {
        self.nom = nom
        self.estIA = estIA
        self.combattants = equipe.map {
            CombattantEnJeu(modele: $0, profil: profils[$0.id] ?? .aleatoire,
                            niveau: niveaux[$0.id] ?? niveauParDefaut, equipement: equipements[$0.id],
                            bonusPV: bonusPV[$0.id] ?? 0)
        }
    }

    var actif: CombattantEnJeu { combattants[indexActif] }

    /// La famille de styles partagée par toute l'équipe (3 combattants), si c'est le cas.
    var synergie: FamilleStyle? { Equipe.synergie(combattants.map(\.modele)) }
    var estElimine: Bool { combattants.allSatisfy(\.estKO) }
    var pvTotal: Int { combattants.reduce(0) { $0 + max(0, $1.pv) } }
    var nombreKO: Int { combattants.filter(\.estKO).count }

    /// Si le combattant actif est K.O., fait entrer le suivant encore debout.
    mutating func remplacerSiKO() {
        guard actif.estKO, let suivant = combattants.firstIndex(where: { !$0.estKO }) else { return }
        indexActif = suivant
        // Chevaliers : le combattant qui entre après un K.O. de son équipe reçoit un bouclier.
        if combattants[suivant].modele.familleStyle == .chevaliers {
            let k = synergie == .chevaliers ? ProfilStats.synergie : 1
            combattants[suivant].absorption += Int((Double(ProfilStats.bouclierChevaliers) * k).rounded())
        }
    }
}

/// Règles de composition d'équipe partagées par l'écran de sélection et le combat.
enum Equipe {
    /// La famille de styles commune à une équipe complète de 3 combattants, sinon nil.
    static func synergie(_ modeles: [ModeleCombattant]) -> FamilleStyle? {
        guard modeles.count == Regles.tailleEquipe, let premiere = modeles.first?.familleStyle,
              modeles.allSatisfy({ $0.familleStyle == premiere }) else { return nil }
        return premiere
    }
}
