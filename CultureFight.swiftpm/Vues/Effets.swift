import SwiftUI

// MARK: - Fond animé

/// Fond de l'accueil : un dégradé maillé qui ondule (iOS 18), ou un dégradé simple (iOS 17).
struct FondAnime: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation) { contexte in
                MeshGradient(width: 3, height: 3,
                             points: Self.points(t: contexte.date.timeIntervalSinceReferenceDate),
                             colors: Self.couleurs)
            }
            .ignoresSafeArea()
        } else {
            LinearGradient(colors: [Color(red: 0.05, green: 0.10, blue: 0.35), Color(red: 0.02, green: 0.03, blue: 0.12)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    /// Les 9 points du maillage ; ceux du milieu et des bords bougent lentement.
    private static func points(t: Double) -> [SIMD2<Float>] {
        func f(_ x: Double) -> Float { Float(x) }
        let haut: SIMD2<Float> = [f(0.5 + 0.15 * sin(t * 0.4)), 0]
        let gauche: SIMD2<Float> = [0, f(0.5 + 0.12 * cos(t * 0.5))]
        let centre: SIMD2<Float> = [f(0.5 + 0.22 * sin(t * 0.6)), f(0.5 + 0.22 * cos(t * 0.45))]
        let droite: SIMD2<Float> = [1, f(0.5 + 0.12 * sin(t * 0.55))]
        let bas: SIMD2<Float> = [f(0.5 + 0.15 * cos(t * 0.35)), 1]
        let coins: [SIMD2<Float>] = [[0, 0], [1, 0], [0, 1], [1, 1]]
        return [coins[0], haut, coins[1], gauche, centre, droite, coins[2], bas, coins[3]]
    }

    private static let nuit = Color(red: 0.03, green: 0.05, blue: 0.18)
    private static let bleu = Color(red: 0.05, green: 0.12, blue: 0.40)
    private static let violet = Color(red: 0.10, green: 0.05, blue: 0.30)
    private static let lueur = Color(red: 0.95, green: 0.55, blue: 0.10).opacity(0.55)
    private static let bleuClair = Color(red: 0.05, green: 0.15, blue: 0.45)
    private static let encre = Color(red: 0.02, green: 0.03, blue: 0.12)
    private static let pourpre = Color(red: 0.12, green: 0.06, blue: 0.32)

    private static let couleurs: [Color] = [
        nuit, bleu, nuit,
        violet, lueur, bleuClair,
        encre, pourpre, encre,
    ]
}

// MARK: - Particules

/// Gerbe d'étincelles qui part du centre, jouée une fois (bonus « Éclair »).
struct Etincelles: View {
    var couleur: Color = .yellow
    @State private var debut = Date()
    private let duree = 1.2

    var body: some View {
        TimelineView(.animation) { contexte in
            let t = contexte.date.timeIntervalSince(debut)
            Canvas { ctx, taille in
                guard t < duree else { return }
                let centre = CGPoint(x: taille.width / 2, y: taille.height / 2)
                let progression = t / duree
                ctx.opacity = 1 - progression
                for i in 0..<28 {
                    let angle = Double(i) / 28 * 2 * .pi + Double(i % 3) * 0.2
                    let distance = 16 + progression * (120 + Double(i % 4) * 25)
                    let point = CGPoint(x: centre.x + cos(angle) * distance, y: centre.y + sin(angle) * distance)
                    let rayon = 2 + 4 * (1 - progression)
                    let disque = CGRect(x: point.x - rayon, y: point.y - rayon, width: 2 * rayon, height: 2 * rayon)
                    ctx.fill(Path(ellipseIn: disque), with: .color(i % 2 == 0 ? couleur : .white))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Pluie de confettis (victoire). Positions pseudo-aléatoires mais stables d'une image à l'autre.
struct Confettis: View {
    @State private var debut = Date()
    private let couleurs: [Color] = [.orange, .yellow, .pink, .cyan, .green, .purple]

    var body: some View {
        TimelineView(.animation) { contexte in
            let t = contexte.date.timeIntervalSince(debut)
            Canvas { ctx, taille in
                let hauteur = taille.height + 40
                for i in 0..<90 {
                    let graine = Double(i) + 1
                    let x = abs(sin(graine * 12.9898)) * taille.width
                    let vitesse = 70 + abs(sin(graine * 3.7)) * 140
                    let depart = abs(sin(graine * 7.13)) * hauteur
                    let y = (depart + t * vitesse).truncatingRemainder(dividingBy: hauteur) - 20
                    let derive = sin(t * 2 + graine) * 14
                    let morceau = Path(roundedRect: CGRect(x: -5, y: -2.5, width: 10, height: 5), cornerRadius: 1.5)
                    ctx.drawLayer { couche in
                        couche.translateBy(x: x + derive, y: y)
                        couche.rotate(by: .radians(t * 4 + graine))
                        couche.fill(morceau, with: .color(couleurs[i % couleurs.count]))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Secousse et chiffres qui s'envolent

/// Valeurs animées quand un combattant gagne ou perd des PV.
struct Impact {
    var decalage: CGFloat = 0
    var echelle: CGFloat = 1
    var flash: Double = 0
}

/// Secoue la vue, la fait briller en rouge (dégâts) ou en vert (soin) à chaque nouveau `declencheur`.
struct EffetImpact: ViewModifier {
    let declencheur: Int
    /// Variation de PV : négative pour des dégâts, positive pour un soin.
    let variation: Int

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: Impact(), trigger: declencheur) { vue, v in
                vue
                    .offset(x: variation < 0 ? v.decalage : 0)
                    .scaleEffect(v.echelle)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(variation < 0 ? Color.red : Color.green)
                            .opacity(v.flash)
                            .allowsHitTesting(false)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.decalage) {
                    LinearKeyframe(0, duration: 0.01)
                    SpringKeyframe(-14, duration: 0.07)
                    SpringKeyframe(12, duration: 0.07)
                    SpringKeyframe(-8, duration: 0.07)
                    SpringKeyframe(5, duration: 0.07)
                    SpringKeyframe(0, duration: 0.2)
                }
                KeyframeTrack(\.echelle) {
                    LinearKeyframe(1, duration: 0.01)
                    SpringKeyframe(variation < 0 ? 0.95 : 1.05, duration: 0.12)
                    SpringKeyframe(1, duration: 0.35)
                }
                KeyframeTrack(\.flash) {
                    LinearKeyframe(0.45, duration: 0.05)
                    LinearKeyframe(0, duration: 0.45)
                }
            }
    }
}

/// Valeurs animées du chiffre qui s'envole.
struct Envol {
    var y: CGFloat = 0
    var opacite: Double = 0
    var echelle: CGFloat = 0.6
}

/// « −56 » en rouge ou « +15 » en vert qui monte et s'efface à chaque nouveau `declencheur`.
struct ChiffreEnvole: View {
    let declencheur: Int
    let variation: Int

    var body: some View {
        Text(variation < 0 ? "\(variation)" : "+\(variation)")
            .font(.system(size: 34, weight: .black, design: .rounded))
            .foregroundStyle(variation < 0 ? Color.red : Color.green)
            .shadow(color: .black.opacity(0.6), radius: 3)
            .keyframeAnimator(initialValue: Envol(), trigger: declencheur) { vue, v in
                vue.offset(y: v.y).opacity(v.opacite).scaleEffect(v.echelle)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    LinearKeyframe(0, duration: 0.01)
                    CubicKeyframe(-70, duration: 1.0)
                }
                KeyframeTrack(\.opacite) {
                    LinearKeyframe(1, duration: 0.08)
                    LinearKeyframe(1, duration: 0.55)
                    LinearKeyframe(0, duration: 0.4)
                }
                KeyframeTrack(\.echelle) {
                    SpringKeyframe(1.3, duration: 0.18)
                    SpringKeyframe(1, duration: 0.3)
                    LinearKeyframe(0.9, duration: 0.5)
                }
            }
            .allowsHitTesting(false)
    }
}

// MARK: - Transition « zoom » (iOS 18)

/// Marque la vue d'origine d'une transition zoom.
struct SourceZoom: ViewModifier {
    let id: String
    let espace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.matchedTransitionSource(id: id, in: espace)
        } else {
            content
        }
    }
}

/// Fait apparaître la vue présentée en zoomant depuis sa source.
struct TransitionZoom: ViewModifier {
    let id: String
    let espace: Namespace.ID

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.navigationTransition(.zoom(sourceID: id, in: espace))
        } else {
            content
        }
    }
}

// MARK: - Carte holographique

/// Incline la vue en 3D sous le doigt, avec un reflet qui suit le mouvement.
struct Holographique: ViewModifier {
    @State private var inclinaison: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(colors: [.clear, .white.opacity(0.35), .cyan.opacity(0.2), .clear],
                               startPoint: UnitPoint(x: 0.0 + inclinaison.width / 300, y: 0),
                               endPoint: UnitPoint(x: 1.0 + inclinaison.width / 300, y: 1))
                    .blendMode(.overlay)
                    .allowsHitTesting(false)
            }
            .rotation3DEffect(.degrees(Double(inclinaison.width) / 9), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(Double(-inclinaison.height) / 9), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { geste in
                        inclinaison = CGSize(width: max(-120, min(120, geste.translation.width)),
                                             height: max(-120, min(120, geste.translation.height)))
                    }
                    .onEnded { _ in
                        withAnimation(.spring(duration: 0.6, bounce: 0.45)) { inclinaison = .zero }
                    }
            )
    }
}
