import SwiftUI
import SwiftData

/// Carte « Tenue alternative » de la fiche d'un combattant possédé qui en a une.
/// Le style complet (tous les combattants du même style possédés) débloque la tenue ; le joueur
/// choisit ensuite entre la tenue d'origine et la tenue alternative.
struct CarteTenue: View {
    let modele: ModeleCombattant
    @Query private var joueurs: [Joueur]
    @AppStorage("tenuesVersion") private var versionTenues = 0

    private var possedes: Set<String> { Set(joueurs.first?.reserve.map(\.modeleID) ?? []) }

    var body: some View {
        if Tenues.existe(pour: modele.id), possedes.contains(modele.id) {
            let debloquee = Tenues.debloquee(modele, possedes: possedes)
            let portee = Tenues.portee(modele.id)
            let progression = Tenues.progression(de: modele, possedes: possedes)
            CarteFiche(titre: "Tenue alternative", icone: "tshirt.fill", accent: modele.specialite.couleur) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        vignette(nom: "combattant-\(modele.id)", titre: "D'origine", active: !portee, ouverte: true) {
                            choisir(false)
                        }
                        vignette(nom: "tenue-\(modele.id)", titre: "Alternative", active: portee, ouverte: debloquee) {
                            choisir(true)
                        }
                    }
                    if debloquee {
                        TexteFiche(texte: "Style \(modele.style) complet : la tenue alternative est débloquée. Touche une vignette pour changer de tenue.")
                    } else {
                        TexteFiche(texte: "Complète le style \(modele.style) pour la débloquer : \(progression.possedes) / \(progression.total) combattants possédés.")
                        ProgressView(value: Double(progression.possedes), total: Double(max(progression.total, 1)))
                            .tint(Charte.or)
                    }
                }
                .sensoryFeedback(.selection, trigger: versionTenues)
            }
        }
    }

    private func choisir(_ alternative: Bool) {
        guard alternative != Tenues.portee(modele.id) else { return }
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            Tenues.porter(modele.id, alternative)
        }
    }

    private func vignette(nom: String, titre: String, active: Bool, ouverte: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let image = Illustrations.partage.ressource(nom, type: "jpg") {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color.black.opacity(0.3)
                    }
                }
                .frame(height: 90)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .saturation(ouverte ? 1 : 0)
                .brightness(ouverte ? 0 : -0.2)
                .overlay {
                    if !ouverte {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundStyle(Charte.ivoire)
                            .accessibilityLabel("Verrouillée")
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(active ? Charte.or : Color.white.opacity(0.15), lineWidth: active ? 3 : 1))
                Text(active ? "\(titre) · portée" : titre)
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(active ? Charte.or : Charte.ivoire.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .disabled(!ouverte)
    }
}
