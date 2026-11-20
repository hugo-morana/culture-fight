import SwiftUI
import UIKit
import CoreText

/// Charte graphique : lettrage du logo (Cinzel, empattements gravés) et couleurs.
enum Charte {
    static let ivoire = Color(red: 0.98, green: 0.94, blue: 0.84)
    static let or = Color(red: 1.0, green: 0.78, blue: 0.24)
    static let marine = Color(red: 0.03, green: 0.06, blue: 0.2)

    static let policeBlack = "CinzelRoman-Black"
    static let policeBold = "CinzelRoman-Bold"

    /// Enregistre les polices fournies avec l'app et habille les barres de navigation.
    static func installer() {
        for nom in ["Cinzel-Black", "Cinzel-Bold"] {
            let url = Bundle.module.url(forResource: nom, withExtension: "ttf")
                ?? Bundle.module.url(forResource: nom, withExtension: "ttf", subdirectory: "Polices")
                ?? Bundle.main.url(forResource: nom, withExtension: "ttf")
            if let url {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        let ivoireUI = UIColor(red: 0.98, green: 0.94, blue: 0.84, alpha: 1)
        if let grand = UIFont(name: policeBlack, size: 30) {
            UINavigationBar.appearance().largeTitleTextAttributes = [.font: grand, .foregroundColor: ivoireUI]
        }
        if let petit = UIFont(name: policeBold, size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [.font: petit, .foregroundColor: ivoireUI]
        }
    }
}

extension Font {
    /// Grands titres, chiffres de dégâts : Cinzel Black.
    static func titre(_ taille: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(Charte.policeBlack, size: taille, relativeTo: style)
    }

    /// Noms de combattants, boutons, en-têtes : Cinzel Bold.
    static func nom(_ taille: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom(Charte.policeBold, size: taille, relativeTo: style)
    }
}

/// Lettrage du logo : ivoire, liseré marine et halo bleu.
struct LettrageLogo: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Charte.ivoire)
            .shadow(color: Charte.marine, radius: 0, x: 0, y: 2)
            .shadow(color: Color.blue.opacity(0.7), radius: 8)
    }
}

extension View {
    func lettrageLogo() -> some View { modifier(LettrageLogo()) }
}
