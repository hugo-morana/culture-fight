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

    init(modele: ModeleCombattant) {
        self.modele = modele
        self.pv = modele.pvMax
    }

    var estKO: Bool { pv <= 0 }
}

/// Une équipe de 3 combattants et celui qui est en jeu.
struct Camp: Sendable {
    let nom: String
    let estIA: Bool
    var combattants: [CombattantEnJeu]
    var indexActif: Int = 0

    init(nom: String, estIA: Bool, equipe: [ModeleCombattant]) {
        self.nom = nom
        self.estIA = estIA
        self.combattants = equipe.map { CombattantEnJeu(modele: $0) }
    }

    var actif: CombattantEnJeu { combattants[indexActif] }
    var estElimine: Bool { combattants.allSatisfy(\.estKO) }
    var pvTotal: Int { combattants.reduce(0) { $0 + max(0, $1.pv) } }
    var nombreKO: Int { combattants.filter(\.estKO).count }

    /// Si le combattant actif est K.O., fait entrer le suivant encore debout.
    mutating func remplacerSiKO() {
        guard actif.estKO, let suivant = combattants.firstIndex(where: { !$0.estKO }) else { return }
        indexActif = suivant
    }
}
