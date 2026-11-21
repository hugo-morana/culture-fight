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
        case "XXe siècle": return "📻"
        case "Musées et chefs-d'œuvre": return "🖼️"
        case "Musique classique": return "🎼"
        case "Opéra et danse": return "🎭"
        case "Instruments de musique": return "🎻"
        case "Architecture et monuments": return "🏯"
        case "Romans": return "📚"
        case "Poésie": return "🪶"
        case "Théâtre": return "🎭"
        case "Mythologie grecque": return "⚡"
        case "Mythologie nordique": return "🔨"
        case "Étymologie": return "🔤"
        case "Nombres": return "🔢"
        case "Algèbre": return "✖️"
        case "Mathématiciens": return "📐"
        case "Inventions": return "💡"
        case "Molécules et réactions": return "⚗️"
        case "Mécanique": return "⚙️"
        case "Électricité et magnétisme": return "⚡"
        case "Lumière et ondes": return "🌈"
        case "Chaleur et énergie": return "🔥"
        case "Matériaux": return "🧱"
        case "Savants et laboratoire": return "🧪"
        case "Système solaire": return "🪐"
        case "Lunes et petits corps": return "☄️"
        case "Étoiles": return "⭐"
        case "Constellations": return "✨"
        case "Galaxies et cosmologie": return "🌀"
        case "Phénomènes célestes": return "🌗"
        case "Conquête spatiale": return "🚀"
        case "Astronautes": return "🧑‍🚀"
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
        case "Aïkidoka": return "🙏"
        case "Lutteur": return "🤼"
        case "Mage": return "🔮"
        case "Chevalier noir": return "♞"
        case "Cambrioleur": return "🕵️"
        case "Bretteur": return "⚔️"
        case "Orc": return "👺"
        case "Guerrier celte": return "☘️"
        case "Centaure": return "🐴"
        case "Dieu guerrier": return "⚡"
        case "Dragon": return "🐉"
        case "Samouraï": return "🏯"
        case "Sentinelle": return "💂"
        case "Gorgone": return "🐍"
        case "Inquisiteur": return "📕"
        case "Sumo": return "🍙"
        case "Barbare": return "🔥"
        case "Conquistador": return "⛵"
        case "Maître du tonfa": return "🥢"
        case "Cowboy": return "🤠"
        case "Robot": return "🤖"
        case "Minotaure": return "🐃"
        case "Kung-fu": return "🐉"
        case "Raptor": return "🦖"
        case "Ingénieur de siège": return "🛠️"
        case "Méduse": return "🪼"
        case "Guerrier léopard": return "🐆"
        case "Guerrier antique": return "🏺"
        case "Jiu-jitsu": return "🥋"
        case "Voltigeur": return "🤸"
        case "Catcheur": return "🤼"
        case "Pirate": return "🏴‍☠️"
        case "Empereur guerrier": return "👑"
        case "Fantôme": return "👻"
        case "Loup-garou": return "🐺"
        case "Berserker": return "🪓"
        case "Sabreur": return "🗡️"
        case "Dieu du tonnerre": return "🌩️"
        case "Banshee": return "👻"
        case "Brute": return "💪"
        case "Chevalier errant": return "🐎"
        case "Troll": return "🧌"
        case "Pistolero": return "🔫"
        case "Guerrière": return "🛡️"
        case "Moine guerrier": return "📿"
        case "Maître d'armes": return "🤺"
        case "Titan": return "⛰️"
        case "Officier": return "🧭"
        case "Espion": return "🕶️"
        case "Templier": return "✝️"
        case "Pieuvre": return "🐙"
        case "Ferrailleur": return "⚒️"
        case "Assassin": return "🗡️"
        case "Artificier": return "🎆"
        case "Valkyrie": return "🪽"
        case "Cowboy hors-la-loi": return "🤠"
        case "Bandit": return "🦹"
        case "Roi usurpateur": return "🤴"
        case "Rétiaire": return "🕸️"
        case "Hallebardier": return "⚜️"
        case "Nain guerrier": return "⛏️"
        case "Toréador": return "🌹"
        case "Voleur": return "🧤"
        case "Géant": return "🦶"
        case "Apprentie guerrière": return "🔰"
        case "Militaire": return "⭐"
        case "Guerrier sarrasin": return "🌙"
        case "Chasseuse de primes": return "💸"
        case "Héros grec": return "🫒"
        case "Ours guerrier": return "🐻"
        case "Casse-cou": return "🎪"
        case "Dompteuse": return "🎠"
        case "Taekwondo": return "🦵"
        case "Héros légendaire": return "🏅"
        case "Mercenaire": return "💰"
        case "Bandit masqué": return "🎭"
        case "Médecin de guerre": return "⛑️"
        case "Ombre": return "🌑"
        case "Cavalière": return "🐎"
        case "Gendarme": return "👮"
        case "Alligator guerrier": return "🐊"
        case "Corsaire": return "⚓"
        case "Éclaireur": return "🔭"
        case "Guerrier aztèque": return "🪶"
        case "Hoplite": return "🛡️"
        case "Fusilier": return "🎯"
        case "Cosaque": return "🐎"
        case "Cowboy de rodéo": return "🤠"
        case "Truand": return "🃏"
        case "Colonel": return "🎖️"
        case "Agent secret": return "🕵️"
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
