import AVFoundation

/// Bruitages du jeu (tâche 35), tirés des packs CC0 de Kenney (liste et sources : onglet
/// « Bruitages » de la feuille « Culture Fight — Musiques », et README).
/// Les sons d'attaque par famille de styles viendront plus tard (ElevenLabs).
///
/// Même session audio que `ServiceAudio` (« ambient ») : muet en mode silencieux.
@MainActor
final class ServiceSons {
    static let partage = ServiceSons()

    enum Son: String, CaseIterable {
        case selection, carte, question
        case bonneReponse = "bonne-reponse"
        case mauvaiseReponse = "mauvaise-reponse"
        case eclair, tic
        case tempsEcoule = "temps-ecoule"
        case jauge, impact, bouclier, ko, soin, objet, pieces, achat, evolution
        case tap, retour, erreur, changement
        // Jingles (ElevenLabs).
        case victoire, defaite, nul, niveau
        case nouveauCombattant = "nouveau-combattant"
        // Un son d'attaque par famille de styles (ElevenLabs), calé pour que le coup tombe à 0,42 s.
        case attaqueShurikens = "attaque-shurikens"
        case attaqueMarteau = "attaque-marteau"
        case attaqueLance = "attaque-lance"
        case attaqueChi = "attaque-chi"
        case attaqueBotte = "attaque-botte"
        case attaqueOrbe = "attaque-orbe"
        case attaqueFeu = "attaque-feu"
        case attaqueAmes = "attaque-ames"
        case attaqueFleches = "attaque-fleches"
        case attaqueSalve = "attaque-salve"

        /// Le son de l'animation d'attaque d'une famille de styles.
        static func attaque(_ famille: FamilleStyle) -> Son {
            switch famille {
            case .ombres: return .attaqueShurikens
            case .guerriersLourds: return .attaqueMarteau
            case .chevaliers: return .attaqueLance
            case .artsMartiaux: return .attaqueChi
            case .bretteurs: return .attaqueBotte
            case .mages: return .attaqueOrbe
            case .creatures: return .attaqueFeu
            case .mortsVivants: return .attaqueAmes
            case .tireurs: return .attaqueFleches
            case .soldats: return .attaqueSalve
            }
        }

        /// Volume propre à chaque son, pour qu'ils sonnent à peu près aussi fort les uns que les autres.
        var volume: Float {
            switch self {
            case .tic, .selection, .tap, .retour: return 0.45
            case .victoire, .defaite, .nul, .niveau, .nouveauCombattant: return 0.7
            case .ko, .impact: return 0.9
            case .attaqueShurikens, .attaqueMarteau, .attaqueLance, .attaqueChi, .attaqueBotte,
                 .attaqueOrbe, .attaqueFeu, .attaqueAmes, .attaqueFleches, .attaqueSalve: return 0.8
            default: return 0.75
            }
        }
    }

    /// Clé du réglage « Effets » du profil (activé par défaut).
    static let cleEffets = "effetsActifs"
    static var effetsActifs: Bool {
        UserDefaults.standard.object(forKey: cleEffets) as? Bool ?? true
    }

    /// Deux lecteurs par son, pour qu'un son puisse se chevaucher avec lui-même (tics, impacts).
    private var lecteurs: [Son: [AVAudioPlayer]] = [:]
    private var prochain: [Son: Int] = [:]

    private init() {
        _ = ServiceAudio.partage   // règle la session audio (« ambient ») avant tout son
        for son in Son.allCases {
            guard let url = Bundle.module.url(forResource: "son-\(son.rawValue)", withExtension: "wav")
                    ?? Bundle.main.url(forResource: "son-\(son.rawValue)", withExtension: "wav") else { continue }
            lecteurs[son] = (0..<2).compactMap { _ in
                let lecteur = try? AVAudioPlayer(contentsOf: url)
                lecteur?.volume = son.volume
                lecteur?.prepareToPlay()
                return lecteur
            }
        }
    }

    /// Charge les sons au lancement, pour que le premier parte sans délai.
    func precharger() { _ = lecteurs.count }

    func jouer(_ son: Son, apres delai: Double = 0) {
        guard Self.effetsActifs else { return }
        if delai > 0 {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(delai))
                self?.jouerMaintenant(son)
            }
        } else {
            jouerMaintenant(son)
        }
    }

    private func jouerMaintenant(_ son: Son) {
        guard Self.effetsActifs, let liste = lecteurs[son], !liste.isEmpty else { return }
        let index = prochain[son, default: 0] % liste.count
        prochain[son] = index + 1
        let lecteur = liste[index]
        lecteur.currentTime = 0
        lecteur.play()
    }
}
