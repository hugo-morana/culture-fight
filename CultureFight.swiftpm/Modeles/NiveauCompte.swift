import SwiftUI

/// Règles du niveau de compte : XP gagnée en combat, seuils et ligues.
enum NiveauCompte {
    /// XP de compte : +10 par combat terminé, +20 de plus en cas de victoire (comme l'XP des combattants).
    static let xpCombat = 10
    static let xpVictoire = 20

    /// XP à réunir pour passer du niveau `niveau` au suivant : 100 × niveau actuel.
    static func seuil(_ niveau: Int) -> Int { 100 * max(1, niveau) }
}

/// Ligue affichée sur le badge. En attendant le classement Glicko-2 (tâche 30), elle suit le niveau de compte.
enum Ligue: Int, CaseIterable, Sendable {
    case bronze, argent, or, platine, savant

    init(niveau: Int) {
        switch niveau {
        case ..<5: self = .bronze
        case 5..<10: self = .argent
        case 10..<15: self = .or
        case 15..<20: self = .platine
        default: self = .savant
        }
    }

    var nom: String {
        switch self {
        case .bronze: return "Bronze"
        case .argent: return "Argent"
        case .or: return "Or"
        case .platine: return "Platine"
        case .savant: return "Savant"
        }
    }

    /// Premier niveau de la ligue suivante, nil pour Savant.
    var niveauSuivante: Int? {
        switch self {
        case .bronze: return 5
        case .argent: return 10
        case .or: return 15
        case .platine: return 20
        case .savant: return nil
        }
    }

    /// Dégradé métallique du badge (clair, foncé).
    var couleurs: (Color, Color) {
        switch self {
        case .bronze: return (Color(red: 0.93, green: 0.62, blue: 0.38), Color(red: 0.55, green: 0.30, blue: 0.13))
        case .argent: return (Color(red: 0.92, green: 0.94, blue: 0.97), Color(red: 0.52, green: 0.56, blue: 0.63))
        case .or: return (Color(red: 1.0, green: 0.88, blue: 0.42), Color(red: 0.80, green: 0.55, blue: 0.08))
        case .platine: return (Color(red: 0.75, green: 0.97, blue: 0.97), Color(red: 0.25, green: 0.60, blue: 0.70))
        case .savant: return (Color(red: 0.84, green: 0.65, blue: 1.0), Color(red: 0.42, green: 0.18, blue: 0.72))
        }
    }
}

extension Joueur {
    var ligue: Ligue { Ligue(niveau: niveauCompte) }
    var seuilNiveauSuivant: Int { NiveauCompte.seuil(niveauCompte) }

    /// Ajoute de l'XP de compte et fait monter de niveau autant de fois que nécessaire.
    /// Renvoie le nombre de niveaux gagnés.
    @discardableResult
    func gagnerXPCompte(_ xp: Int) -> Int {
        guard xp > 0 else { return 0 }
        xpCompte += xp
        var gagnes = 0
        while xpCompte >= NiveauCompte.seuil(niveauCompte) {
            xpCompte -= NiveauCompte.seuil(niveauCompte)
            niveauCompte += 1
            gagnes += 1
        }
        return gagnes
    }
}

// MARK: - Vue

/// En haut à gauche de l'accueil : badge de ligue avec le niveau, et barre vers le niveau suivant.
struct JaugeNiveau: View {
    let niveau: Int
    let xp: Int
    let seuil: Int

    private var ligue: Ligue { Ligue(niveau: niveau) }
    private var part: Double { seuil > 0 ? min(1, Double(xp) / Double(seuil)) : 0 }

    var body: some View {
        HStack(spacing: 10) {
            BadgeLigue(ligue: ligue, niveau: niveau)
            VStack(alignment: .leading, spacing: 4) {
                Text("Niv. \(niveau) · \(ligue.nom)")
                    .font(.nom(14, relativeTo: .subheadline))
                    .foregroundStyle(Charte.ivoire)
                    .lineLimit(1)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.15))
                        Capsule()
                            .fill(LinearGradient(colors: [ligue.couleurs.0, ligue.couleurs.1],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(6, geo.size.width * part))
                    }
                }
                .frame(width: 96, height: 7)
                .animation(.easeOut(duration: 0.8), value: part)
                Text("\(xp)/\(seuil) XP")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Niveau \(niveau), ligue \(ligue.nom), \(xp) XP sur \(seuil) pour le niveau suivant")
    }
}

/// Écusson aux couleurs de la ligue, avec le niveau au centre.
struct BadgeLigue: View {
    let ligue: Ligue
    let niveau: Int
    var taille: CGFloat = 46

    var body: some View {
        ZStack {
            Image(systemName: "shield.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(LinearGradient(colors: [ligue.couleurs.0, ligue.couleurs.1],
                                                startPoint: .top, endPoint: .bottom))
                .shadow(color: ligue.couleurs.0.opacity(0.6), radius: 6)
            Image(systemName: "shield")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.white.opacity(0.55))
            Text("\(niveau)")
                .font(.titre(taille * 0.38))
                .foregroundStyle(Charte.marine)
                .minimumScaleFactor(0.5)
                .offset(y: -taille * 0.03)
        }
        .frame(width: taille, height: taille)
    }
}
