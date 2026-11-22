import SwiftUI
import UIKit

/// Identité visuelle des 10 domaines (tâche 173, retour bêta n° 7) : une couleur et une vignette illustrée
/// par domaine (`Resources/domaine-<slug>.png`, emblèmes du parchemin enluminé), affichées là où l'on choisit :
/// composition d'équipe, album et boutique.
enum IdentiteDomaine {
    /// Nom de fichier de la vignette. Les anciens et futurs noms d'un domaine renommé pointent vers la même.
    static func slug(_ domaine: String) -> String {
        switch domaine {
        case "Matière": return "matiere"
        case "Univers": return "univers"
        case "Terre": return "terre"
        case "Vivant": return "vivant"
        case "Corps humain": return "corps-humain"
        case "Monde", "Pays et cultures", "Pays et culture": return "monde"
        case "Histoire": return "histoire"
        case "Arts": return "arts"
        case "Lettres et mythes": return "lettres-et-mythes"
        case "Maths et techniques", "Savoirs": return "maths-et-techniques"
        default: return ""
        }
    }

    /// Couleur du domaine, prise sur sa vignette.
    static func couleur(_ domaine: String) -> Color {
        switch slug(domaine) {
        case "matiere": return Color(red: 0.88, green: 0.40, blue: 0.10)
        case "univers": return Color(red: 0.29, green: 0.36, blue: 0.77)
        case "terre": return Color(red: 0.63, green: 0.38, blue: 0.18)
        case "vivant": return Color(red: 0.43, green: 0.56, blue: 0.18)
        case "corps-humain": return Color(red: 0.85, green: 0.44, blue: 0.48)
        case "monde": return Color(red: 0.18, green: 0.55, blue: 0.55)
        case "histoire": return Color(red: 0.72, green: 0.20, blue: 0.17)
        case "arts": return Color(red: 0.48, green: 0.31, blue: 0.65)
        case "lettres-et-mythes": return Color(red: 0.85, green: 0.66, blue: 0.25)
        case "maths-et-techniques": return Color(red: 0.23, green: 0.45, blue: 0.78)
        default: return .blue
        }
    }

    private static let cache = NSCache<NSString, UIImage>()

    /// Vignette illustrée du domaine, ou nil si elle manque.
    static func image(_ domaine: String) -> UIImage? {
        let nom = "domaine-" + slug(domaine)
        if let image = cache.object(forKey: nom as NSString) { return image }
        guard let url = Bundle.module.url(forResource: nom, withExtension: "png")
                ?? Bundle.main.url(forResource: nom, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: nom as NSString)
        return image
    }
}

/// Vignette illustrée d'un domaine ; à défaut, son pictogramme.
struct VignetteDomaine: View {
    let domaine: String
    var taille: CGFloat = 28

    var body: some View {
        Group {
            if let image = IdentiteDomaine.image(domaine) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .shadow(color: .black.opacity(0.35), radius: taille * 0.06, y: taille * 0.03)
            } else {
                Text(Pictos.domaine(domaine)).font(.system(size: taille * 0.7))
            }
        }
        .frame(width: taille, height: taille)
        .accessibilityHidden(true)
    }
}

/// Pastille de filtre par domaine : vignette, nom, et la couleur du domaine quand elle est choisie.
struct PastilleDomaine: View {
    /// nil pour « Tous ».
    let domaine: String?
    let actif: Bool
    let action: () -> Void

    var body: some View {
        let teinte = domaine.map(IdentiteDomaine.couleur) ?? Charte.or
        Button(action: action) {
            HStack(spacing: 6) {
                if let domaine {
                    VignetteDomaine(domaine: domaine, taille: 24)
                        .scaleEffect(actif ? 1.12 : 1)
                }
                Text(domaine ?? "Tous")
                    .font(.nom(13, relativeTo: .caption))
                    .lineLimit(1)
            }
            .padding(.leading, domaine == nil ? 12 : 5)
            .padding(.trailing, 12)
            .padding(.vertical, domaine == nil ? 8 : 4)
            .background(actif ? teinte : Charte.marine.opacity(0.7), in: Capsule())
            .foregroundStyle(actif ? (domaine == nil ? Charte.marine : .white) : Charte.ivoire)
            .overlay(Capsule().stroke(teinte.opacity(actif ? 0 : 0.6), lineWidth: 1))
            .shadow(color: actif ? teinte.opacity(0.5) : .clear, radius: 6)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: actif)
        .sensoryFeedback(.selection, trigger: actif)
        .accessibilityLabel(domaine ?? "Tous les domaines")
        .accessibilityAddTraits(actif ? .isSelected : [])
    }
}
