import SwiftUI
import UIKit

@main
struct CultureFightApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentView: View {
    enum Ecran {
        case accueil
        case selection
        case combat(CombatController)
    }

    @State private var ecran: Ecran = .accueil

    var body: some View {
        switch ecran {
        case .accueil:
            AccueilView { ecran = .selection }
        case .selection:
            SelectionEquipeView(retour: { ecran = .accueil }) { equipe, niveau in
                let ia = IAAdverse(niveau: niveau)
                let adverse = ia.choisirEquipe(parmi: Catalogue.prototype)
                ecran = .combat(CombatController(equipeJoueur: equipe, equipeIA: adverse, ia: ia))
            }
        case .combat(let controleur):
            CombatView(controleur: controleur,
                       rejouer: { ecran = .selection },
                       accueil: { ecran = .accueil })
                .id(ObjectIdentifier(controleur))
        }
    }
}

struct AccueilView: View {
    let combattre: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.orange)
            Text("Culture Fight")
                .font(.largeTitle.bold())
            Text("Ton savoir est ton arme.")
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
            Button(action: combattre) {
                Text("Combattre")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            Text("Prototype · 9 combattants · combat contre l'IA")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(32)
    }
}

// MARK: - Éléments communs

extension Specialite {
    /// Une couleur par domaine.
    var couleur: Color {
        switch domaine {
        case "Matière": return .orange
        case "Univers": return .indigo
        case "Terre": return .brown
        case "Vivant": return .green
        case "Corps humain": return .pink
        case "Monde": return .teal
        case "Histoire": return .red
        case "Arts": return .purple
        case "Lettres et mythes": return .yellow
        default: return .blue
        }
    }
}

/// Illustrations des combattants (`Resources/combattant-<id>.jpg`), chargées une fois.
final class Illustrations: @unchecked Sendable {
    static let partage = Illustrations()
    private let cache = NSCache<NSString, UIImage>()

    func image(pour id: String) -> UIImage? {
        if let image = cache.object(forKey: id as NSString) { return image }
        guard let url = Bundle.module.url(forResource: "combattant-\(id)", withExtension: "jpg"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: id as NSString)
        return image
    }
}

/// Portrait du combattant : son illustration, ou ses initiales s'il n'en a pas encore.
struct Avatar: View {
    let modele: ModeleCombattant
    var taille: CGFloat = 48

    var body: some View {
        if let image = Illustrations.partage.image(pour: modele.id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: taille, height: taille, alignment: .top)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: taille * 0.22))
                .overlay(RoundedRectangle(cornerRadius: taille * 0.22)
                    .stroke(modele.specialite.couleur, lineWidth: 2))
        } else {
            ZStack {
                Circle().fill(modele.specialite.couleur.gradient)
                Text(modele.initiales)
                    .font(.system(size: taille * 0.38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: taille, height: taille)
        }
    }
}

struct BarrePV: View {
    let pv: Int
    let pvMax: Int

    private var ratio: Double { pvMax > 0 ? Double(max(0, pv)) / Double(pvMax) : 0 }
    private var couleur: Color { ratio > 0.5 ? .green : (ratio > 0.25 ? .yellow : .red) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(couleur).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.4), value: pv)
    }
}
