import Foundation

/// Ce que rapporte une bonne réponse rapide, selon la famille de styles du combattant qui répond.
enum EffetVitesse: Sendable {
    /// La contre-attaque fait plus de dégâts.
    case contreAttaque
    /// Le combattant regagne des PV.
    case soin
    /// La prochaine erreur du combattant coûte moins de PV.
    case bouclier
    /// La jauge de Savoir se remplit plus vite.
    case savoir
    /// L'adversaire aura moins de temps à sa prochaine réponse.
    case pression

    var nom: String {
        switch self {
        case .contreAttaque: return "Contre-attaque"
        case .soin: return "Soin"
        case .bouclier: return "Bouclier"
        case .savoir: return "Inspiration"
        case .pression: return "Pression"
        }
    }

    /// Effet en clair, pour l'écran de choix de l'équipe.
    var description: String {
        switch self {
        case .contreAttaque: return "contre-attaque +50 % (Éclair) ou +25 % (Rapide)"
        case .soin: return "regagne 15 PV (Éclair) ou 8 PV (Rapide)"
        case .bouclier: return "sa prochaine erreur coûte 30 % (Éclair) ou 15 % (Rapide) de PV en moins"
        case .savoir: return "jauge d'Inspiration +2 cases (Éclair) ou +1 case (Rapide) en plus"
        case .pression: return "l'adversaire aura 4 s (Éclair) ou 2 s (Rapide) de moins à sa prochaine réponse"
        }
    }
}

/// Les familles de styles du game design. Chacune a son effet de vitesse.
enum FamilleStyle: String, Sendable {
    case guerriersLourds = "Guerriers lourds"
    case artsMartiaux = "Arts martiaux"
    case tireurs = "Tireurs"
    case creatures = "Créatures"
    case mortsVivants = "Morts-vivants"
    case chevaliers = "Chevaliers"
    case soldats = "Soldats"
    case mages = "Mages"
    case ombres = "Ombres"
    case bretteurs = "Bretteurs"

    var effetVitesse: EffetVitesse {
        switch self {
        case .guerriersLourds, .artsMartiaux, .tireurs: return .contreAttaque
        case .creatures, .mortsVivants: return .soin
        case .chevaliers, .soldats: return .bouclier
        case .mages: return .savoir
        case .ombres, .bretteurs: return .pression
        }
    }
}

/// Rapidité d'une bonne réponse.
enum Vitesse: Sendable {
    case eclair, rapide, normale

    init(secondes: Double) {
        if secondes < Regles.seuilEclair { self = .eclair }
        else if secondes < Regles.seuilRapide { self = .rapide }
        else { self = .normale }
    }

    var nom: String {
        switch self {
        case .eclair: return "Éclair !"
        case .rapide: return "Rapide !"
        case .normale: return ""
        }
    }
}
