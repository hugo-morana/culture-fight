import AVFoundation

/// Musiques du jeu (tâche 35).
/// - Menus : au lancement, le thème Intro joue une fois, puis le thème principal tourne en boucle
///   sur tous les écrans hors combat. Il reprend là où il s'était arrêté au retour d'un combat.
/// - Combat : le thème de combat tourne en boucle, depuis le début à chaque combat.
/// Le passage de l'un à l'autre se fait en fondu enchaîné.
///
/// Session audio « ambient » : l'app se tait quand l'iPhone est en mode silencieux, et ne coupe pas
/// la musique que le joueur écoute déjà (dans ce cas, le jeu ne lance pas la sienne).
@MainActor
final class ServiceAudio: NSObject, AVAudioPlayerDelegate {
    static let partage = ServiceAudio()

    enum Ambiance { case menus, combat }

    /// Clé du réglage « Musique » du profil (activée par défaut).
    static let cleMusique = "musiqueActive"
    static var musiqueActive: Bool {
        UserDefaults.standard.object(forKey: cleMusique) as? Bool ?? true
    }

    private static let volumeMenus: Float = 0.55
    /// Plus bas : la musique de combat ne doit pas gêner la lecture des questions.
    private static let volumeCombat: Float = 0.45
    private static let intro = "musique-intro"
    private static let principal = "musique-accueil"
    private static let combat = "musique-combat"

    private var lecteurMenus: AVAudioPlayer?
    private var lecteurCombat: AVAudioPlayer?
    private var introJouee = false
    private var ambiance: Ambiance = .menus
    private var auPremierPlan = true
    /// Numéro du dernier ordre donné : un fondu de sortie ne met en pause que s'il est toujours le dernier.
    private var ordre = 0

    private override init() {
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    }

    // MARK: - Ordres venant des vues

    func entrer(_ nouvelle: Ambiance) {
        if nouvelle == .combat, ambiance != .combat {
            lecteurCombat?.currentTime = 0
        }
        ambiance = nouvelle
        appliquer()
    }

    func reglageModifie() { appliquer() }

    func premierPlan(_ actif: Bool) {
        auPremierPlan = actif
        if actif {
            appliquer()
        } else {
            ordre += 1
            lecteurMenus?.pause()
            lecteurCombat?.pause()
        }
    }

    // MARK: - Lecture

    private var peutJouer: Bool {
        Self.musiqueActive && auPremierPlan
            && !AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint
    }

    private func appliquer() {
        ordre += 1
        guard peutJouer else {
            effacer(lecteurMenus)
            effacer(lecteurCombat)
            return
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        switch ambiance {
        case .menus:
            effacer(lecteurCombat)
            if let lecteurMenus {
                reprendre(lecteurMenus, volume: Self.volumeMenus)
            } else if introJouee {
                lecteurMenus = creer(Self.principal, enBoucle: true, volume: Self.volumeMenus)
            } else {
                introJouee = true
                lecteurMenus = creer(Self.intro, enBoucle: false, volume: Self.volumeMenus)
            }
        case .combat:
            effacer(lecteurMenus)
            if let lecteurCombat {
                reprendre(lecteurCombat, volume: Self.volumeCombat)
            } else {
                lecteurCombat = creer(Self.combat, enBoucle: true, volume: Self.volumeCombat)
            }
        }
    }

    private func creer(_ nom: String, enBoucle: Bool, volume: Float) -> AVAudioPlayer? {
        guard let url = Bundle.module.url(forResource: nom, withExtension: "m4a")
                ?? Bundle.main.url(forResource: nom, withExtension: "m4a"),
              let lecteur = try? AVAudioPlayer(contentsOf: url) else { return nil }
        lecteur.numberOfLoops = enBoucle ? -1 : 0
        lecteur.delegate = self
        lecteur.volume = 0
        lecteur.prepareToPlay()
        lecteur.play()
        lecteur.setVolume(volume, fadeDuration: 1.5)
        return lecteur
    }

    private func reprendre(_ lecteur: AVAudioPlayer, volume: Float) {
        if !lecteur.isPlaying {
            lecteur.volume = 0
            lecteur.play()
        }
        lecteur.setVolume(volume, fadeDuration: 1.2)
    }

    /// Fondu de sortie, puis pause : la lecture peut reprendre au même endroit.
    private func effacer(_ lecteur: AVAudioPlayer?) {
        guard let lecteur, lecteur.isPlaying else { return }
        let numero = ordre
        lecteur.setVolume(0, fadeDuration: 0.8)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(900))
            guard let self, self.ordre == numero else { return }
            lecteur.pause()
        }
    }

    // MARK: - AVAudioPlayerDelegate

    /// Fin du thème Intro : le thème principal prend le relais.
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let menus = self.lecteurMenus, ObjectIdentifier(menus) == id else { return }
            self.lecteurMenus = nil
            if self.ambiance == .menus { self.appliquer() }
        }
    }
}
