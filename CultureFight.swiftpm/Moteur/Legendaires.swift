import Foundation

/// Les 10 Légendaires exclusifs de domaine (game design, « Bonus de collection ») : un par domaine,
/// gagné en complétant le domaine, impossible à acheter. Ses questions viennent de tout le domaine.
/// Ils ne comptent pas dans la complétion de l'album et n'apparaissent ni en boutique ni chez l'IA.
enum Legendaires {
    private static func legendaire(id: String, nom: String, style: String, familleStyle: FamilleStyle,
                                   domaine: String, apparence: String) -> ModeleCombattant {
        let spec = Specialite(id: "legendaire-\(id)", nom: "Tout le domaine \(domaine)",
                              famille: "Légendaires", domaine: domaine)
        return ModeleCombattant(id: id, nom: nom, style: style, familleStyle: familleStyle,
                                specialite: spec, rarete: .legendaire,
                                pvMax: 130, attaque: 62, defense: 8, difficulte: 2,
                                apparence: apparence,
                                questions: "Toutes les spécialités du domaine \(domaine), tirées au hasard.",
                                generateur: GenerateurDomaine(domaine: domaine))
    }

    static let liste: [ModeleCombattant] = [
        legendaire(id: "elementor", nom: "Élémentor", style: "Archimage", familleStyle: .mages, domaine: "Matière",
                   apparence: "Archimage en robe tissée des cases du tableau périodique, couronne d'atomes en orbite, bâton-alambic où bouillonnent toutes les couleurs de la matière."),
        legendaire(id: "omniscientor", nom: "Omniscientor", style: "Sage", familleStyle: .mages, domaine: "Savoirs",
                   apparence: "Sage aux mille yeux, toge couverte d'équations et de plans d'inventions, une plume dans chaque main, la Bibliothèque infinie dans son dos."),
        legendaire(id: "galactarque", nom: "Galactarque", style: "Empereur", familleStyle: .chevaliers, domaine: "Univers",
                   apparence: "Empereur cosmique en armure d'étoiles, cape faite d'une galaxie spirale, sceptre surmonté d'un soleil miniature."),
        legendaire(id: "tellurion", nom: "Tellurion", style: "Titan", familleStyle: .guerriersLourds, domaine: "Terre",
                   apparence: "Titan de roche et de lave, montagnes sur les épaules, fleuves qui coulent de ses bras, couronne de nuages."),
        legendaire(id: "gaiasaure", nom: "Gaïasaure", style: "Dragon", familleStyle: .creatures, domaine: "Vivant",
                   apparence: "Dragon végétal couvert de mousse et de fleurs, ailes de feuilles géantes, animaux de toutes sortes nichés sur son dos."),
        legendaire(id: "vitruvion", nom: "Vitruvion", style: "Colosse", familleStyle: .artsMartiaux, domaine: "Corps humain",
                   apparence: "Colosse à quatre bras inscrit dans un cercle et un carré d'or, os et muscles visibles comme une planche d'anatomie."),
        legendaire(id: "mappemonarque", nom: "Mappemonarque", style: "Monarque", familleStyle: .soldats, domaine: "Monde",
                   apparence: "Monarque à la cape cousue de tous les drapeaux, globe terrestre en guise d'orbe, couronne en rose des vents."),
        legendaire(id: "chronarque", nom: "Chronarque", style: "Empereur", familleStyle: .guerriersLourds, domaine: "Histoire",
                   apparence: "Empereur du temps à l'armure faite de toutes les époques (hoplite, chevalier, grognard), sablier géant en guise de bouclier."),
        legendaire(id: "musagete", nom: "Musagète", style: "Muse", familleStyle: .bretteurs, domaine: "Arts",
                   apparence: "Muse resplendissante, lyre d'or à la ceinture, palette de peintre en bouclier et pinceau-épée qui laisse des traînées de couleurs."),
        legendaire(id: "homerion", nom: "Homérion", style: "Aède", familleStyle: .ombres, domaine: "Lettres et mythes",
                   apparence: "Aède aveugle à la barbe de parchemin, lyre et plume en main, entouré des ombres des héros et des monstres des grands récits."),
    ]

    static func duDomaine(_ domaine: String) -> ModeleCombattant? {
        liste.first { $0.specialite.domaine == domaine }
    }
}

/// Questions d'un Légendaire : un combattant jouable du domaine tiré au hasard pose la sienne.
struct GenerateurDomaine: GenerateurQuestions {
    let domaine: String

    private var generateurs: [any GenerateurQuestions] {
        Catalogue.prototype.filter { $0.specialite.domaine == domaine }.map(\.generateur)
    }

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        let liste = generateurs
        return tirerNouvelle(exclues: exclues) {
            liste.randomElement()!.generer(difficulte: difficulte, exclues: exclues)
        }
    }

    var apercu: [TableauDonnees] { [] }
}

extension Catalogue {
    /// Tous les combattants qu'un joueur peut posséder : les jouables et les Légendaires de domaine.
    static let tous: [ModeleCombattant] = prototype + Legendaires.liste

    static func modele(_ id: String) -> ModeleCombattant? { tous.first { $0.id == id } }
}

extension ModeleCombattant {
    var estLegendaireDeDomaine: Bool { specialite.famille == "Légendaires" }
}

// MARK: - Récompenses de complétion

/// Récompenses de l'album : titre et +5 PV pour une famille complète, Légendaire pour un domaine complet.
/// (La tenue alternative d'un style complet est gérée par `Tenues`.)
enum Recompenses {
    static let bonusPVFamille = 5

    private static func complet(_ modeles: [ModeleCombattant], _ possedes: Set<String>) -> Bool {
        !modeles.isEmpty && modeles.allSatisfy { possedes.contains($0.id) }
    }

    /// Familles (domaine, famille) complètes, dans l'ordre du catalogue.
    static func famillesCompletes(_ possedes: Set<String>) -> [(domaine: String, famille: String)] {
        var vues: [String] = []
        var resultat: [(domaine: String, famille: String)] = []
        for m in Catalogue.prototype where !vues.contains(m.specialite.famille) {
            vues.append(m.specialite.famille)
            let membres = Catalogue.prototype.filter { $0.specialite.famille == m.specialite.famille }
            if complet(membres, possedes) { resultat.append((m.specialite.domaine, m.specialite.famille)) }
        }
        return resultat
    }

    static func familleComplete(_ famille: String, _ possedes: Set<String>) -> Bool {
        complet(Catalogue.prototype.filter { $0.specialite.famille == famille }, possedes)
    }

    static func domaineComplet(_ domaine: String, _ possedes: Set<String>) -> Bool {
        complet(Catalogue.prototype.filter { $0.specialite.domaine == domaine }, possedes)
    }

    static func titre(famille: String) -> String { "Expert · \(famille)" }

    /// +5 PV en combat pour chaque combattant possédé dont la famille est complète.
    static func bonusPV(_ possedes: Set<String>) -> [String: Int] {
        let familles = Set(famillesCompletes(possedes).map(\.famille))
        var bonus: [String: Int] = [:]
        for m in Catalogue.prototype where possedes.contains(m.id) && familles.contains(m.specialite.famille) {
            bonus[m.id] = bonusPVFamille
        }
        return bonus
    }

    /// Légendaires dus (domaine complet) et pas encore dans la réserve.
    static func legendairesDus(_ possedes: Set<String>) -> [ModeleCombattant] {
        Legendaires.liste.filter { !possedes.contains($0.id) && domaineComplet($0.specialite.domaine, possedes) }
    }
}
