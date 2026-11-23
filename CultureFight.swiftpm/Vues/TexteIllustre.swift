import SwiftUI
import UIKit

/// Logos « émail et or » glissés dans une ligne de texte, à la place des emojis : un `Text` peut contenir
/// une image, redimensionnée ici à la taille de la police (et mise en cache). Sans logo, l'emoji reste.
enum TexteIllustre {
    private static let cache = NSCache<NSString, UIImage>()

    /// Image réduite à `taille` points de haut, nette sur l'écran.
    static func reduite(_ image: UIImage, nom: String, taille: CGFloat) -> UIImage {
        let cle = "\(nom)@\(Int(taille * 10))" as NSString
        if let deja = cache.object(forKey: cle) { return deja }
        let ratio = image.size.height > 0 ? image.size.width / image.size.height : 1
        let cible = CGSize(width: taille * ratio, height: taille)
        let reduite = UIGraphicsImageRenderer(size: cible).image { _ in
            image.draw(in: CGRect(origin: .zero, size: cible))
        }
        cache.setObject(reduite, forKey: cle)
        return reduite
    }

    /// L'icône seule : le logo s'il existe, sinon l'emoji.
    static func icone(_ image: UIImage?, nom: String, emoji: String, taille: CGFloat) -> Text {
        guard let image else { return Text(emoji) }
        return Text(Image(uiImage: reduite(image, nom: nom, taille: taille * 1.25)).renderingMode(.original))
            .baselineOffset(-taille * 0.25)
    }
}

extension ModeleCombattant {
    func iconeStyle(_ taille: CGFloat) -> Text {
        TexteIllustre.icone(IdentiteDomaine.imageStyle(style), nom: "style-" + style, emoji: pictoStyle, taille: taille)
    }
    func iconeFamilleStyle(_ taille: CGFloat) -> Text {
        TexteIllustre.icone(IdentiteDomaine.imageNommee(familleStyle.nomImage), nom: familleStyle.nomImage,
                            emoji: familleStyle.picto, taille: taille)
    }
    func iconeFamille(_ taille: CGFloat) -> Text {
        TexteIllustre.icone(IdentiteDomaine.imageFamille(specialite.famille), nom: "famille-" + specialite.famille,
                            emoji: specialite.pictoFamille, taille: taille)
    }
    func iconeDomaine(_ taille: CGFloat) -> Text {
        TexteIllustre.icone(IdentiteDomaine.image(specialite.domaine), nom: "domaine-" + specialite.domaine,
                            emoji: specialite.pictoDomaine, taille: taille)
    }

    /// « [emblème] Ninja · [logo de famille] Gaz nobles », avec les logos à la taille du texte.
    func sousTitreIllustre(_ taille: CGFloat) -> Text {
        iconeStyle(taille) + Text(" \(style) · ") + iconeFamille(taille) + Text(" \(specialite.nom)")
    }
    /// « [logo] Matière › [logo] Éléments chimiques »
    func classementIllustre(_ taille: CGFloat) -> Text {
        iconeDomaine(taille) + Text(" \(specialite.domaine) › ") + iconeFamille(taille) + Text(" \(specialite.famille)")
    }
    /// « [logo] Ombres »
    func typeIllustre(_ taille: CGFloat) -> Text {
        iconeFamilleStyle(taille) + Text(" \(familleStyle.rawValue)")
    }
}
