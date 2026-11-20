import SwiftUI
import SwiftData

/// Tactique d'un combattant : comment évolue la difficulté des questions qu'il pose au fil du combat.
/// Réglée dans la collection (fiche du combattant), débloquée au niveau 2 du combattant.
enum ProfilDifficulte: String, CaseIterable, Identifiable, Sendable {
    case aleatoire, montee, frappe, constant

    var id: String { rawValue }

    /// Niveau du combattant à partir duquel on peut choisir une tactique.
    static let niveauDeblocage = 2

    var nom: String {
        switch self {
        case .aleatoire: return "Aléatoire"
        case .montee: return "Montée en puissance"
        case .frappe: return "Frappe d'entrée"
        case .constant: return "Constant"
        }
    }

    var icone: String {
        switch self {
        case .aleatoire: return "dice.fill"
        case .montee: return "chart.line.uptrend.xyaxis"
        case .frappe: return "bolt.fill"
        case .constant: return "equal.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .aleatoire: return "Difficulté tirée au hasard autour de celle du combattant (−1 à +1). Imprévisible."
        case .montee: return "Commence facile puis monte d'un cran à chaque question : l'adversaire se fait piéger en fin de combat."
        case .frappe: return "Commence très difficile pour viser le K.O. rapide, puis redescend. Attention aux contre-attaques."
        case .constant: return "Toujours la difficulté du combattant : régulier et prévisible."
        }
    }

    /// Difficulté (1 à 5) de la question numéro `rang` (0 = la première) posée par un combattant de difficulté `base`.
    func difficulte(base: Int, rang: Int) -> Int {
        let d: Int
        switch self {
        case .aleatoire: d = base + Int.random(in: -1...1)
        case .montee: d = base - 1 + rang
        case .frappe: d = base + 2 - rang
        case .constant: d = base
        }
        return min(5, max(1, d))
    }

    /// Les 6 premières difficultés, pour l'aperçu (sans hasard pour Aléatoire : la base).
    func apercu(base: Int) -> [Int] {
        (0..<6).map { self == .aleatoire ? min(5, max(1, base)) : difficulte(base: base, rang: $0) }
    }
}

extension CombattantPossede {
    var profil: ProfilDifficulte { ProfilDifficulte(rawValue: tactique) ?? .aleatoire }
    var tactiqueDebloquee: Bool { niveau >= ProfilDifficulte.niveauDeblocage }
}

extension Joueur {
    /// Profil de chaque combattant de la réserve (tactique débloquée seulement).
    var profils: [String: ProfilDifficulte] {
        var dico: [String: ProfilDifficulte] = [:]
        for c in reserve where c.tactiqueDebloquee { dico[c.modeleID] = c.profil }
        return dico
    }
}

/// Carte « Tactique » de la fiche : choix du profil de difficulté, avec aperçu animé.
struct CarteTactique: View {
    let modele: ModeleCombattant
    @Query private var joueurs: [Joueur]
    @Environment(\.modelContext) private var contexte

    private var possede: CombattantPossede? {
        joueurs.first?.reserve.first { $0.modeleID == modele.id }
    }

    var body: some View {
        if let possede {
            CarteFiche(titre: "Tactique", icone: "slider.horizontal.3", accent: modele.specialite.couleur) {
                if possede.tactiqueDebloquee {
                    contenu(possede)
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(Charte.or)
                            .symbolEffect(.pulse)
                        TexteFiche(texte: "Débloquée au niveau \(ProfilDifficulte.niveauDeblocage) du combattant (actuellement niveau \(possede.niveau)). Questions en difficulté aléatoire d'ici là.")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contenu(_ possede: CombattantPossede) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            TexteFiche(texte: "Choisis comment évolue la difficulté des questions que pose \(modele.nom) pendant le combat.")
            ForEach(ProfilDifficulte.allCases) { profil in
                let actif = possede.profil == profil
                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.3)) { possede.tactique = profil.rawValue }
                    Sauvegarde.enregistrer(contexte)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: profil.icone)
                            .font(.title3)
                            .foregroundStyle(actif ? Charte.marine : Charte.or)
                            .frame(width: 36, height: 36)
                            .background(actif ? Charte.or : Charte.marine, in: Circle())
                            .symbolEffect(.bounce, value: actif)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profil.nom)
                                .font(.nom(15, relativeTo: .subheadline))
                                .foregroundStyle(Charte.ivoire)
                            Text(profil.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            ApercuDifficulte(valeurs: profil.apercu(base: modele.difficulte),
                                             couleur: modele.specialite.couleur, aleatoire: profil == .aleatoire)
                        }
                        Spacer(minLength: 0)
                        if actif {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Charte.marine, Charte.or)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(10)
                    .background(Charte.marine.opacity(actif ? 0.9 : 0.5), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(actif ? Charte.or : Color.white.opacity(0.1),
                                                                        lineWidth: actif ? 2 : 1))
                }
                .buttonStyle(.plain)
            }
        }
        .sensoryFeedback(.selection, trigger: possede.tactique)
    }
}

/// Six barres : la difficulté des 6 premières questions posées.
struct ApercuDifficulte: View {
    let valeurs: [Int]
    let couleur: Color
    var aleatoire = false

    @State private var monte = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(valeurs.enumerated()), id: \.offset) { i, v in
                RoundedRectangle(cornerRadius: 2)
                    .fill(couleur.gradient)
                    .frame(width: 14, height: monte ? CGFloat(v) * 6 : 2)
                    .overlay(alignment: .top) {
                        if aleatoire {
                            Text("?").font(.system(size: 8, weight: .bold)).foregroundStyle(Charte.ivoire).offset(y: -10)
                        }
                    }
                    .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.05 * Double(i)), value: monte)
            }
        }
        .frame(height: 32, alignment: .bottom)
        .onAppear { monte = true }
    }
}
