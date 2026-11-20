import SwiftUI
import SwiftData

/// Stade d'évolution d'un combattant : change tous les 3 niveaux et fixe la difficulté des questions qu'il pose.
/// Chaque stade porte le nom d'un niveau de difficulté (game design, « Évolution des combattants »).
enum Stade: Int, CaseIterable, Comparable, Identifiable, Sendable {
    case mini = 1, meso, maxi, mega, ultra, hyper, supreme

    var id: Int { rawValue }

    init(niveau: Int) {
        self = Stade(rawValue: min(7, max(1, (niveau - 1) / 3 + 1))) ?? .mini
    }

    static func < (a: Stade, b: Stade) -> Bool { a.rawValue < b.rawValue }

    /// Difficulté des questions posées à ce stade (1 à 7).
    var difficulte: Int { rawValue }
    /// Premier niveau du stade.
    var niveauMin: Int { (rawValue - 1) * 3 + 1 }
    var suivant: Stade? { Stade(rawValue: rawValue + 1) }

    var nom: String {
        switch self {
        case .mini: return "Mini"
        case .meso: return "Méso"
        case .maxi: return "Maxi"
        case .mega: return "Méga"
        case .ultra: return "Ultra"
        case .hyper: return "Hyper"
        case .supreme: return "Suprême"
        }
    }

    var nomDifficulte: String {
        switch self {
        case .mini: return "Facile"
        case .meso: return "Moyen"
        case .maxi: return "Difficile"
        case .mega: return "Très difficile"
        case .ultra: return "Expert"
        case .hyper: return "Maître"
        case .supreme: return "Impossible"
        }
    }

    /// « Mini-Néonja », …, « Néonja Suprême ».
    func nom(de base: String) -> String {
        self == .supreme ? "\(base) Suprême" : "\(nom)-\(base)"
    }

    /// Couleurs du cadre (claire, foncée).
    var couleurs: (Color, Color) {
        switch self {
        case .mini: return (Color(red: 0.93, green: 0.62, blue: 0.38), Color(red: 0.55, green: 0.30, blue: 0.13))
        case .meso: return (Color(red: 0.92, green: 0.94, blue: 0.97), Color(red: 0.52, green: 0.56, blue: 0.63))
        case .maxi: return (Color(red: 1.0, green: 0.88, blue: 0.42), Color(red: 0.80, green: 0.55, blue: 0.08))
        case .mega: return (Color(red: 0.45, green: 0.95, blue: 0.62), Color(red: 0.05, green: 0.50, blue: 0.30))
        case .ultra: return (Color(red: 0.45, green: 0.70, blue: 1.0), Color(red: 0.10, green: 0.25, blue: 0.70))
        case .hyper: return (Color(red: 0.84, green: 0.60, blue: 1.0), Color(red: 0.42, green: 0.15, blue: 0.72))
        case .supreme: return (Color(red: 1.0, green: 0.55, blue: 0.80), Color(red: 0.30, green: 0.85, blue: 1.0))
        }
    }

    var degrade: LinearGradient {
        if self == .supreme {
            return LinearGradient(colors: [.pink, .orange, .yellow, .green, .cyan, .purple],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return LinearGradient(colors: [couleurs.0, couleurs.1], startPoint: .top, endPoint: .bottom)
    }

    /// Stade des combattants de l'IA selon son niveau.
    static func pourIA(_ niveau: IAAdverse.Niveau) -> Stade {
        switch niveau {
        case .facile: return .mini
        case .moyen: return .meso
        case .difficile: return .maxi
        }
    }
}

/// Statistiques d'un combattant à un niveau donné : +5 PV, +1 Attaque, +1 Défense par niveau.
enum Progression {
    static func pv(_ modele: ModeleCombattant, niveau: Int) -> Int { modele.pvMax + 5 * (max(1, niveau) - 1) }
    static func attaque(_ modele: ModeleCombattant, niveau: Int) -> Int { modele.attaque + (max(1, niveau) - 1) }
    static func defense(_ modele: ModeleCombattant, niveau: Int) -> Int { modele.defense + (max(1, niveau) - 1) }
}

/// Un combattant qui a changé de stade à la fin d'un combat.
struct EvolutionCombattant: Identifiable, Sendable {
    let modele: ModeleCombattant
    let avant: Stade
    let apres: Stade
    var id: String { modele.id }
}

extension CombattantPossede {
    var stade: Stade { Stade(niveau: niveau) }
}

extension Joueur {
    /// Niveau de chaque combattant de la réserve.
    var niveaux: [String: Int] {
        Dictionary(reserve.map { ($0.modeleID, $0.niveau) }, uniquingKeysWith: max)
    }
}

// MARK: - Vues

/// Petit badge du stade (« Méso »), aux couleurs de son cadre.
struct BadgeStade: View {
    let stade: Stade
    var taille: CGFloat = 11

    var body: some View {
        Text(stade.nom)
            .font(.nom(taille, relativeTo: .caption2))
            .foregroundStyle(Charte.marine)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(stade.degrade, in: Capsule())
    }
}

/// Carte « Évolution » de la fiche : l'échelle des 7 stades et la progression vers le suivant.
struct CarteEvolution: View {
    let modele: ModeleCombattant
    @Query private var joueurs: [Joueur]
    @State private var apparu = false

    private var possede: CombattantPossede? {
        joueurs.first?.reserve.first { $0.modeleID == modele.id }
    }

    var body: some View {
        if let possede {
            let stade = possede.stade
            CarteFiche(titre: "Évolution · \(stade.nom(de: modele.nom))", icone: "sparkles", accent: stade.couleurs.0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Niveau \(possede.niveau) · \(Progression.pv(modele, niveau: possede.niveau)) PV · Att \(Progression.attaque(modele, niveau: possede.niveau)) · Déf \(Progression.defense(modele, niveau: possede.niveau))")
                        .font(.nom(13, relativeTo: .caption))
                        .foregroundStyle(Charte.ivoire)
                    ForEach(Stade.allCases) { s in
                        let atteint = s <= stade
                        HStack(spacing: 10) {
                            Circle()
                                .fill(atteint ? AnyShapeStyle(s.degrade) : AnyShapeStyle(Color.white.opacity(0.1)))
                                .frame(width: s == stade ? 22 : 14, height: s == stade ? 22 : 14)
                                .overlay(Circle().stroke(Charte.or, lineWidth: s == stade ? 2 : 0))
                                .scaleEffect(apparu || !atteint ? 1 : 0.2)
                                .animation(.spring(duration: 0.5, bounce: 0.5).delay(0.06 * Double(s.rawValue)), value: apparu)
                            Text(s.nom)
                                .font(.nom(14, relativeTo: .subheadline))
                                .foregroundStyle(atteint ? Charte.ivoire : .secondary)
                                .frame(width: 70, alignment: .leading)
                            Text("\(s.nomDifficulte) · niv. \(s.niveauMin)")
                                .font(.caption)
                                .foregroundStyle(atteint ? s.couleurs.0 : .secondary)
                            Spacer()
                            if s == stade {
                                Image(systemName: "location.fill").foregroundStyle(Charte.or)
                            }
                        }
                    }
                    if let suivant = stade.suivant {
                        Text("Prochain stade : \(suivant.nom(de: modele.nom)) au niveau \(suivant.niveauMin) (questions \(suivant.nomDifficulte.lowercased())).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Stade ultime atteint.")
                            .font(.caption)
                            .foregroundStyle(Charte.or)
                    }
                }
            }
            .onAppear { apparu = true }
        }
    }
}

/// Séquence plein écran d'une évolution, en fin de combat.
struct SequenceEvolution: View {
    let evolution: EvolutionCombattant
    let continuer: () -> Void

    @State private var phase = 0

    private struct Mouvement {
        var echelle = 0.4
        var rotation = 0.0
        var eclat = 0.0
    }

    var body: some View {
        ZStack {
            Charte.marine.opacity(0.94).ignoresSafeArea()
            RadialGradient(colors: [evolution.apres.couleurs.0.opacity(phase >= 1 ? 0.6 : 0), .clear],
                           center: .center, startRadius: 10, endRadius: 320)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 1.2), value: phase)
            if phase >= 1 {
                Etincelles(couleur: evolution.apres.couleurs.0)
                    .allowsHitTesting(false)
            }
            VStack(spacing: 18) {
                Text("Évolution !")
                    .font(.titre(40, relativeTo: .largeTitle))
                    .lettrageLogo()
                    .scaleEffect(phase >= 1 ? 1 : 0.3)
                    .opacity(phase >= 1 ? 1 : 0)
                carte
                Text((phase >= 1 ? evolution.apres : evolution.avant).nom(de: evolution.modele.nom))
                    .font(.titre(26, relativeTo: .title))
                    .foregroundStyle(Charte.ivoire)
                    .contentTransition(.numericText())
                Text("Questions posées : \(evolution.avant.nomDifficulte) → \(evolution.apres.nomDifficulte)")
                    .font(.nom(15, relativeTo: .subheadline))
                    .foregroundStyle(evolution.apres.couleurs.0)
                    .opacity(phase >= 1 ? 1 : 0)
                Button("Continuer", action: continuer)
                    .font(.titre(18, relativeTo: .headline))
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .opacity(phase >= 1 ? 1 : 0)
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation(.spring(duration: 0.7, bounce: 0.4)) { phase = 1 }
            }
        }
        .sensoryFeedback(.success, trigger: phase)
    }

    private var carte: some View {
        let stade = phase >= 1 ? evolution.apres : evolution.avant
        return Color.clear
            .frame(width: 170, height: 230)
            .overlay(alignment: .top) { IllustrationCombattant(modele: evolution.modele, taille: 50) }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(stade.degrade, lineWidth: 5))
            .overlay(alignment: .topTrailing) { BadgeStade(stade: stade, taille: 13).padding(8) }
            .keyframeAnimator(initialValue: Mouvement(), trigger: phase == 0) { vue, m in
                vue
                    .scaleEffect(m.echelle)
                    .rotation3DEffect(.degrees(m.rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                    .overlay(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(m.eclat)))
                    .shadow(color: stade.couleurs.0.opacity(0.9), radius: 30)
            } keyframes: { _ in
                KeyframeTrack(\.echelle) {
                    SpringKeyframe(1.0, duration: 0.5, spring: .bouncy)
                    LinearKeyframe(1.15, duration: 0.6)
                    SpringKeyframe(1.0, duration: 0.6, spring: .bouncy)
                }
                KeyframeTrack(\.rotation) {
                    LinearKeyframe(0, duration: 0.3)
                    CubicKeyframe(720, duration: 1.0)
                    SpringKeyframe(720, duration: 0.4)
                }
                KeyframeTrack(\.eclat) {
                    LinearKeyframe(0, duration: 0.8)
                    LinearKeyframe(0.95, duration: 0.4)
                    LinearKeyframe(0, duration: 0.6)
                }
            }
    }
}
