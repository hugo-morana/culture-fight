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

    init(modele: ModeleCombattant, profil: ProfilDifficulte = .aleatoire) {
        self.modele = modele
        self.pv = modele.pvMax
        self.profil = profil
    }

    var estKO: Bool { pv <= 0 }
}

/// Une équipe de 3 combattants et celui qui est en jeu.
struct Camp: Sendable {
    let nom: String
    let estIA: Bool
    var combattants: [CombattantEnJeu]
    var indexActif: Int = 0

    init(nom: String, estIA: Bool, equipe: [ModeleCombattant], profils: [String: ProfilDifficulte] = [:]) {
        self.nom = nom
        self.estIA = estIA
        self.combattants = equipe.map { CombattantEnJeu(modele: $0, profil: profils[$0.id] ?? .aleatoire) }
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
