import SwiftUI

/// Pictogrammes : un par domaine, par famille de spécialités,
/// par type (famille de styles) et par sous-type (style) de combattant.
enum Pictos {
    static func domaine(_ nom: String) -> String {
        switch nom {
        case "Matière": return "⚛️"
        case "Univers": return "🌌"
        case "Terre": return "🌍"
        case "Vivant": return "🌿"
        case "Corps humain": return "🫀"
        case "Monde": return "🗺️"
        case "Histoire": return "🏛️"
        case "Arts": return "🎨"
        case "Lettres et mythes": return "📜"
        case "Savoirs": return "🧠"
        default: return "❓"
        }
    }

    static func famille(_ nom: String, domaine: String) -> String {
        switch nom {
        case "Éléments chimiques": return "🧪"
        case "Atome et particules": return "☢️"
        case "Unités et mesures": return "📏"
        case "Calcul mental": return "🧮"
        case "Capitales": return "🏙️"
        case "Animaux préhistoriques": return "🦖"
        case "Arbres": return "🌳"
        case "Champignons et microbes": return "🍄"
        case "Fleurs et plantes": return "🌸"
        case "Fleuves": return "🏞️"
        case "Insectes et arachnides": return "🐞"
        case "Lacs": return "💧"
        case "Mammifères": return "🐘"
        case "Muscles": return "💪"
        case "Océans et mers": return "🌊"
        case "Oiseaux": return "🦅"
        case "Organes": return "🫁"
        case "Peinture": return "🖌️"
        case "Reptiles et amphibiens": return "🐊"
        case "Squelette": return "🦴"
        case "Séismes et tectonique": return "📳"
        case "Volcans": return "🌋"
        case "Reliefs": return "⛰️"
        case "Minéraux": return "💎"
        case "Drapeaux": return "🚩"
        case "Monnaies": return "💰"
        case "Langues": return "🗣️"
        case "Villes et populations": return "🌆"
        case "France": return "🥖"
        case "Antiquité": return "🏛️"
        case "Moyen Âge": return "🏰"
        case "Temps modernes": return "👑"
        case "Époque contemporaine": return "🎖️"
        default: return Pictos.domaine(domaine)
        }
    }

    static func style(_ nom: String, famille: FamilleStyle) -> String {
        switch nom {
        case "Amazone": return "🏹"
        case "Arquebusier": return "💥"
        case "Flibustier": return "🏴‍☠️"
        case "Bourreau": return "🪓"
        case "Champion": return "🏆"
        case "Gladiateur": return "🔱"
        case "Guerrier": return "⚔️"
        case "Viking": return "🛶"
        case "Boxeur": return "🥊"
        case "Judoka": return "🥋"
        case "Karatéka": return "👊"
        case "Moine shaolin": return "🧘"
        case "Centurion": return "🦅"
        case "Guérillero": return "🌴"
        case "Zouave": return "🎺"
        case "Cuirassier": return "🐎"
        case "Paladin": return "🌟"
        case "Druide": return "🌿"
        case "Nécromancien": return "☠️"
        case "Sorcier": return "🧙"
        case "Escrimeur": return "🤺"
        case "Golem": return "🗿"
        case "Kraken": return "🐙"
        case "Ogre": return "👹"
        case "Momie": return "⚱️"
        case "Vampire": return "🧛"
        case "Zombie": return "🧟"
        case "Ninja": return "🥷"
        case "Yéti": return "❄️"
        case "Mamelouk": return "🐪"
        case "Illusionniste": return "🎩"
        case "Manticore": return "🦁"
        case "Mousquetaire": return "🪶"
        case "Chevalier": return "🛡️"
        case "Matador": return "🐂"
        case "Guerrier maori": return "🌺"
        case "Automate": return "⚙️"
        case "Lancier": return "🏇"
        case "Arbalétrier": return "🎯"
        case "Horde barbare": return "👥"
        case "Cyclope": return "👁️"
        case "Colosse": return "🗽"
        case "Shérif": return "🤠"
        case "Légionnaire": return "🪂"
        case "Ronin": return "🗡️"
        case "Spartiate": return "🪖"
        case "Croisé": return "✝️"
        case "Archer": return "🏹"
        case "Bonze": return "📿"
        case "Soldat": return "🧭"
        case "Grenadier": return "💣"
        case "Grognard": return "🎖️"
        default: return famille.picto
        }
    }
}

extension FamilleStyle {
    /// Pictogramme du type de combattant.
    var picto: String {
        switch self {
        case .guerriersLourds: return "🪓"
        case .artsMartiaux: return "🥋"
        case .tireurs: return "🎯"
        case .creatures: return "🐉"
        case .mortsVivants: return "💀"
        case .chevaliers: return "🛡️"
        case .soldats: return "🎖️"
        case .mages: return "🔮"
        case .ombres: return "🌑"
        case .bretteurs: return "🗡️"
        }
    }
}

extension Specialite {
    var pictoDomaine: String { Pictos.domaine(domaine) }
    var pictoFamille: String { Pictos.famille(famille, domaine: domaine) }
}

extension ModeleCombattant {
    var pictoStyle: String { Pictos.style(style, famille: familleStyle) }
    /// « 🥷 Ninja · 🧪 Gaz nobles »
    var sousTitre: String { "\(pictoStyle) \(style) · \(specialite.pictoFamille) \(specialite.nom)" }
    /// « 🌑 Ombres »
    var type: String { "\(familleStyle.picto) \(familleStyle.rawValue)" }
    /// « ⚛️ Matière › 🧪 Éléments chimiques »
    var classement: String {
        "\(specialite.pictoDomaine) \(specialite.domaine) › \(specialite.pictoFamille) \(specialite.famille)"
    }
}

/// Pastille ronde contenant un pictogramme, aux couleurs de la charte.
struct PastillePicto: View {
    let picto: String
    var taille: CGFloat = 26

    var body: some View {
        Text(picto)
            .font(.system(size: taille * 0.55))
            .frame(width: taille, height: taille)
            .background(Circle().fill(Charte.marine.opacity(0.85)))
            .overlay(Circle().stroke(Charte.or.opacity(0.9), lineWidth: 1.5))
    }
}
