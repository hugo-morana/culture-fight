import SwiftUI

// MARK: - Une attaque en cours

/// Une animation d'attaque à jouer, d'un camp vers l'autre, dans le style de la famille de l'attaquant.
struct AttaqueJouee: Equatable {
    let id: Int
    let famille: FamilleStyle
    /// Camp qui attaque (0 = joueur, en bas ; 1 = adversaire, en haut).
    let depuis: Int
    let vers: Int
    let debut: Date
}

/// Réglages communs : l'impact tombe au même moment pour toutes les familles, pour que la carte touchée
/// tremble et que le chiffre des dégâts monte à l'arrivée du coup.
enum TempsAttaque {
    /// Fin du trajet, début de l'impact (secondes).
    static let arrivee: Double = 0.42
    /// Durée totale de l'animation.
    static let duree: Double = 1.05
}

extension FamilleStyle {
    /// Force de la secousse de l'écran à l'impact (points).
    var secousse: CGFloat {
        switch self {
        case .guerriersLourds: return 14
        case .soldats: return 10
        case .creatures: return 9
        case .artsMartiaux: return 7
        case .chevaliers: return 6
        case .mortsVivants, .mages, .tireurs: return 4
        case .ombres, .bretteurs: return 3
        }
    }

    /// Nom de l'animation, pour l'accessibilité et le game design.
    var nomAttaque: String {
        switch self {
        case .ombres: return "Pluie de shurikens"
        case .guerriersLourds: return "Coup de marteau"
        case .chevaliers: return "Charge à la lance"
        case .artsMartiaux: return "Combo de chi"
        case .bretteurs: return "Botte en Z"
        case .mages: return "Orbe arcanique"
        case .creatures: return "Souffle de feu"
        case .mortsVivants: return "Âmes errantes"
        case .tireurs: return "Volée de flèches"
        case .soldats: return "Feu de salve"
        }
    }
}

// MARK: - Couche d'animation

/// Dessine l'attaque par-dessus l'écran de combat, sans capter les touchers.
struct CoucheAttaque: View {
    let attaque: AttaqueJouee
    let depart: CGPoint
    let arrivee: CGPoint

    var body: some View {
        TimelineView(.animation) { contexte in
            let t = contexte.date.timeIntervalSince(attaque.debut)
            Canvas { ctx, _ in
                guard t >= 0, t < TempsAttaque.duree else { return }
                DessinAttaque(famille: attaque.famille, t: t, a: depart, b: arrivee).dessiner(&ctx)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Secoue tout l'écran à l'impact, d'autant plus fort que l'attaque est lourde.
struct SecousseAttaque: ViewModifier {
    let declencheur: Int
    let force: CGFloat

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: CGSize.zero, trigger: declencheur) { vue, d in
            vue.offset(d)
        } keyframes: { _ in
            KeyframeTrack(\.width) {
                LinearKeyframe(0, duration: TempsAttaque.arrivee)
                LinearKeyframe(force, duration: 0.04)
                LinearKeyframe(-force * 0.8, duration: 0.05)
                LinearKeyframe(force * 0.5, duration: 0.05)
                LinearKeyframe(-force * 0.25, duration: 0.05)
                SpringKeyframe(0, duration: 0.2)
            }
            KeyframeTrack(\.height) {
                LinearKeyframe(0, duration: TempsAttaque.arrivee)
                LinearKeyframe(-force * 0.6, duration: 0.05)
                LinearKeyframe(force * 0.4, duration: 0.05)
                SpringKeyframe(0, duration: 0.25)
            }
        }
    }
}

/// Élan au moment où le combattant pose sa question : son pictogramme de style jaillit de son avatar.
struct ElanAttaque: View {
    let declencheur: Int
    let picto: String

    struct Valeurs {
        var echelle: CGFloat = 0.2
        var opacite: Double = 0
        var y: CGFloat = 0
        var angle: Double = -20
    }

    var body: some View {
        Text(picto)
            .font(.system(size: 34))
            .shadow(color: .white.opacity(0.8), radius: 6)
            .keyframeAnimator(initialValue: Valeurs(), trigger: declencheur) { vue, v in
                vue.scaleEffect(v.echelle).opacity(v.opacite).offset(y: v.y).rotationEffect(.degrees(v.angle))
            } keyframes: { _ in
                KeyframeTrack(\.echelle) {
                    SpringKeyframe(1.5, duration: 0.25, spring: .bouncy)
                    LinearKeyframe(1.5, duration: 0.3)
                    CubicKeyframe(0.6, duration: 0.3)
                }
                KeyframeTrack(\.opacite) {
                    LinearKeyframe(1, duration: 0.1)
                    LinearKeyframe(1, duration: 0.55)
                    LinearKeyframe(0, duration: 0.25)
                }
                KeyframeTrack(\.y) {
                    CubicKeyframe(-26, duration: 0.4)
                    CubicKeyframe(-40, duration: 0.5)
                }
                KeyframeTrack(\.angle) {
                    SpringKeyframe(12, duration: 0.3)
                    SpringKeyframe(0, duration: 0.4)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Les 10 dessins

/// Dessin d'une attaque à l'instant `t`, de `a` (avatar de l'attaquant) à `b` (avatar de la cible).
/// Avant `TempsAttaque.arrivee` : le trajet ; après : l'impact.
struct DessinAttaque {
    let famille: FamilleStyle
    let t: Double
    let a: CGPoint
    let b: CGPoint

    /// Avancement du trajet, de 0 à 1.
    private var trajet: Double { min(1, max(0, t / TempsAttaque.arrivee)) }
    /// Avancement de l'impact, de 0 à 1 (0 tant que le coup n'est pas arrivé).
    private var impact: Double {
        let reste = TempsAttaque.duree - TempsAttaque.arrivee
        return min(1, max(0, (t - TempsAttaque.arrivee) / reste))
    }
    private var arrive: Bool { t >= TempsAttaque.arrivee }

    func dessiner(_ ctx: inout GraphicsContext) {
        switch famille {
        case .ombres: shurikens(&ctx)
        case .guerriersLourds: marteau(&ctx)
        case .chevaliers: lance(&ctx)
        case .artsMartiaux: chi(&ctx)
        case .bretteurs: botte(&ctx)
        case .mages: orbe(&ctx)
        case .creatures: souffle(&ctx)
        case .mortsVivants: ames(&ctx)
        case .tireurs: fleches(&ctx)
        case .soldats: salve(&ctx)
        }
    }

    // MARK: Ombres : trois shurikens qui tournoient, puis des entailles et une fumée violette

    private func shurikens(_ ctx: inout GraphicsContext) {
        let violet = Color(red: 0.55, green: 0.3, blue: 0.95)
        for i in 0..<3 {
            let retard = Double(i) * 0.06
            let p = min(1, max(0, (t - retard) / (TempsAttaque.arrivee - 0.06)))
            guard p > 0, p < 1 else { continue }
            let ecart = CGFloat(i - 1) * 46
            for trace in 0..<4 {
                let q = max(0, p - Double(trace) * 0.05)
                let pos = Geo.courbe(a, b, Geo.sortie(q), bosse: ecart)
                ctx.drawLayer { couche in
                    couche.opacity = trace == 0 ? 1 : 0.35 / Double(trace)
                    couche.translateBy(x: pos.x, y: pos.y)
                    couche.rotate(by: .radians(q * 26))
                    couche.fill(Geo.etoile(rayon: 13, creux: 4, branches: 4), with: .color(trace == 0 ? .white : violet))
                    couche.fill(Path(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6)), with: .color(.black))
                }
            }
        }
        guard arrive else { return }
        let k = impact
        // Trois entailles croisées.
        for i in 0..<3 {
            let angle = Double(i) * 1.05 + 0.4
            let long = 46 * CGFloat(min(1, k * 4))
            var trait = Path()
            trait.move(to: CGPoint(x: b.x - cs(angle) * long, y: b.y - sn(angle) * long))
            trait.addLine(to: CGPoint(x: b.x + cs(angle) * long, y: b.y + sn(angle) * long))
            ctx.stroke(trait, with: .color(.white.opacity(1 - k)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        // Fumée.
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: 8))
            for i in 0..<7 {
                let angle = Double(i) / 7 * 2 * .pi
                let d = CGFloat(10 + 40 * k)
                let r = CGFloat(14 + 16 * k)
                let c = CGPoint(x: b.x + cs(angle) * d, y: b.y + sn(angle) * d * 0.6)
                couche.fill(Path(ellipseIn: Geo.carre(c, r)), with: .color(violet.opacity(0.55 * (1 - k))))
            }
        }
    }

    // MARK: Guerriers lourds : un marteau qui tourne, une entaille en croissant et une onde de choc

    private func marteau(_ ctx: inout GraphicsContext) {
        if !arrive {
            let p = Geo.entree(trajet)
            let pos = Geo.courbe(a, b, p, bosse: -70)
            var symbole = ctx.resolve(Image(systemName: "hammer.fill"))
            symbole.shading = .color(Color(red: 0.85, green: 0.85, blue: 0.9))
            ctx.drawLayer { couche in
                couche.translateBy(x: pos.x, y: pos.y)
                couche.rotate(by: .radians(p * 9))
                couche.scaleBy(x: 1.6 + p, y: 1.6 + p)
                couche.draw(symbole, at: .zero)
            }
            // Traînée de poussière.
            for i in 0..<5 {
                let q = max(0, p - Double(i) * 0.07)
                let c = Geo.courbe(a, b, q, bosse: -70)
                ctx.fill(Path(ellipseIn: Geo.carre(c, 6 - CGFloat(i))), with: .color(.orange.opacity(0.4 - Double(i) * 0.07)))
            }
            return
        }
        let k = impact
        // Entaille en croissant.
        var croissant = Path()
        let debut = Angle.degrees(200), fin = Angle.degrees(200 + 140 * min(1, k * 3))
        croissant.addArc(center: b, radius: 54, startAngle: debut, endAngle: fin, clockwise: false)
        ctx.stroke(croissant, with: .color(Color(red: 1, green: 0.55, blue: 0.1).opacity(1 - k)),
                   style: StrokeStyle(lineWidth: CGFloat(12 * (1 - k) + 2), lineCap: .round))
        ctx.stroke(croissant, with: .color(.white.opacity(1 - k)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        // Onde de choc.
        for i in 0..<2 {
            let q = max(0, k - Double(i) * 0.15)
            let r = CGFloat(20 + 110 * Geo.sortie(q))
            ctx.stroke(Path(ellipseIn: CGRect(x: b.x - r, y: b.y - r * 0.45, width: 2 * r, height: r * 0.9)),
                       with: .color(.orange.opacity(0.8 * (1 - q))), lineWidth: CGFloat(5 * (1 - q) + 1))
        }
        // Éclats.
        for i in 0..<10 {
            let angle = Double(i) / 10 * 2 * .pi + 0.3
            let d = CGFloat(70 * Geo.sortie(k))
            let c = CGPoint(x: b.x + cs(angle) * d, y: b.y + sn(angle) * d - CGFloat(30 * k - 60 * k * k))
            ctx.fill(Path(CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(.brown.opacity(1 - k)))
        }
    }

    // MARK: Chevaliers : la lance dorée qui charge, puis un éclat en croix et un bouclier

    private func lance(_ ctx: inout GraphicsContext) {
        let or = Color(red: 1, green: 0.82, blue: 0.3)
        let p = Geo.entree(trajet)
        let pointe = Geo.ligne(a, b, p)
        let talon = Geo.ligne(a, b, max(0, p - 0.45))
        if !arrive || impact < 0.3 {
            var hampe = Path()
            hampe.move(to: talon)
            hampe.addLine(to: pointe)
            let fondu = arrive ? 1 - impact / 0.3 : 1
            ctx.stroke(hampe, with: .linearGradient(Gradient(colors: [or.opacity(0), or]), startPoint: talon, endPoint: pointe),
                       style: StrokeStyle(lineWidth: 7, lineCap: .round))
            ctx.opacity = fondu
            ctx.fill(Path(ellipseIn: Geo.carre(pointe, 7)), with: .color(.white))
            ctx.opacity = 1
        }
        guard arrive else { return }
        let k = impact
        ctx.drawLayer { couche in
            couche.blendMode = .plusLighter
            for i in 0..<4 {
                let angle = Double(i) * .pi / 2 + .pi / 4 * k
                let long = CGFloat(80 * Geo.sortie(min(1, k * 2)) * (1 - k * 0.5))
                var rayon = Path()
                rayon.move(to: b)
                rayon.addLine(to: CGPoint(x: b.x + cs(angle) * long, y: b.y + sn(angle) * long))
                let epaisseur = CGFloat(6 * (1 - k) + 1)
                couche.stroke(rayon, with: .color(or.opacity(1 - k)), style: StrokeStyle(lineWidth: epaisseur, lineCap: .round))
            }
            let eclat = CGFloat(26 * (1 - k) + 4)
            couche.fill(Path(ellipseIn: Geo.carre(b, eclat)),
                        with: .radialGradient(Gradient(colors: [.white, or.opacity(0)]), center: b, startRadius: 0, endRadius: 30))
        }
        var bouclier = ctx.resolve(Image(systemName: "shield.lefthalf.filled"))
        bouclier.shading = .color(or)
        ctx.drawLayer { couche in
            couche.opacity = k < 0.6 ? 1 : (1 - k) / 0.4
            couche.translateBy(x: b.x, y: b.y - 10 - 20 * k)
            couche.scaleBy(x: 1.2 + k, y: 1.2 + k)
            couche.draw(bouclier, at: .zero)
        }
    }

    // MARK: Arts martiaux : une boule de chi, puis un combo de trois coups

    private func chi(_ ctx: inout GraphicsContext) {
        let rouge = Color(red: 1, green: 0.3, blue: 0.2)
        let jaune = Color(red: 1, green: 0.9, blue: 0.3)
        if !arrive {
            let p = Geo.entree(trajet)
            let pos = Geo.ligne(a, b, p)
            ctx.drawLayer { couche in
                couche.blendMode = .plusLighter
                // Lignes de vitesse.
                for i in 0..<6 {
                    let decale = CGFloat(i - 3) * 6
                    let queue = Geo.ligne(a, b, max(0, p - 0.25))
                    var ligne = Path()
                    ligne.move(to: CGPoint(x: queue.x + decale, y: queue.y))
                    ligne.addLine(to: CGPoint(x: pos.x + decale * 0.3, y: pos.y))
                    couche.stroke(ligne, with: .color(jaune.opacity(0.35)), lineWidth: 2)
                }
                let r: CGFloat = 16 + 4 * CGFloat(sin(t * 40))
                couche.fill(Path(ellipseIn: Geo.carre(pos, r * 1.8)),
                            with: .radialGradient(Gradient(colors: [jaune, rouge.opacity(0)]), center: pos, startRadius: 0, endRadius: r * 1.8))
                couche.fill(Path(ellipseIn: Geo.carre(pos, r * 0.6)), with: .color(.white))
            }
            return
        }
        // Trois coups rapprochés autour de la cible.
        let decalages: [CGPoint] = [CGPoint(x: -22, y: -8), CGPoint(x: 20, y: 6), CGPoint(x: 0, y: 0)]
        for (i, d) in decalages.enumerated() {
            let q = min(1, max(0, (impact - Double(i) * 0.18) / 0.45))
            guard q > 0, q < 1 else { continue }
            let c = CGPoint(x: b.x + d.x, y: b.y + d.y)
            let taille: CGFloat = i == 2 ? 1.6 : 1
            ctx.drawLayer { couche in
                couche.opacity = 1 - q
                couche.translateBy(x: c.x, y: c.y)
                couche.rotate(by: .radians(Double(i) * 0.5))
                couche.scaleBy(x: taille * (0.6 + 0.8 * q), y: taille * (0.6 + 0.8 * q))
                couche.fill(Geo.etoile(rayon: 26, creux: 11, branches: 8), with: .color(jaune))
                couche.fill(Geo.etoile(rayon: 15, creux: 7, branches: 8), with: .color(.white))
            }
        }
        // Onde de chi finale.
        let q = min(1, max(0, (impact - 0.36) / 0.64))
        if q > 0 {
            let r = CGFloat(18 + 90 * Geo.sortie(q))
            ctx.stroke(Path(ellipseIn: Geo.carre(b, r)), with: .color(rouge.opacity(1 - q)), lineWidth: 4)
        }
    }

    // MARK: Bretteurs : une fente éclair, puis trois estafilades en Z et des étincelles

    private func botte(_ ctx: inout GraphicsContext) {
        let acier = Color(red: 0.75, green: 0.88, blue: 1)
        if !arrive {
            let p = Geo.entree(trajet)
            let pointe = Geo.ligne(a, b, p)
            let queue = Geo.ligne(a, b, max(0, p - 0.3))
            var trait = Path()
            trait.move(to: queue)
            trait.addLine(to: pointe)
            ctx.stroke(trait, with: .linearGradient(Gradient(colors: [acier.opacity(0), .white]), startPoint: queue, endPoint: pointe),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            return
        }
        // Le Z : trois segments tracés l'un après l'autre.
        let l: CGFloat = 34
        let points = [CGPoint(x: b.x - l, y: b.y - l * 0.8), CGPoint(x: b.x + l, y: b.y - l * 0.8),
                      CGPoint(x: b.x - l, y: b.y + l * 0.8), CGPoint(x: b.x + l, y: b.y + l * 0.8)]
        for i in 0..<3 {
            let q = min(1, max(0, (impact - Double(i) * 0.12) / 0.12))
            guard q > 0 else { continue }
            let fin = Geo.ligne(points[i], points[i + 1], q)
            var trait = Path()
            trait.move(to: points[i])
            trait.addLine(to: fin)
            let fondu = max(0, 1 - max(0, impact - 0.5) * 2)
            ctx.stroke(trait, with: .color(.white.opacity(fondu)), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            ctx.stroke(trait, with: .color(acier.opacity(0.5 * fondu)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        }
        // Étincelles.
        for i in 0..<8 {
            let angle = Double(i) / 8 * 2 * .pi + 0.2
            let d = CGFloat(20 + 50 * Geo.sortie(impact))
            let c = CGPoint(x: b.x + cs(angle) * d, y: b.y + sn(angle) * d)
            ctx.drawLayer { couche in
                couche.opacity = 1 - impact
                couche.translateBy(x: c.x, y: c.y)
                couche.fill(Geo.etoile(rayon: 5, creux: 1.5, branches: 4), with: .color(.white))
            }
        }
    }

    // MARK: Mages : un orbe qui file en spirale d'étincelles, puis un cercle de runes

    private func orbe(_ ctx: inout GraphicsContext) {
        let mauve = Color(red: 0.7, green: 0.4, blue: 1)
        let cyan = Color(red: 0.4, green: 0.95, blue: 1)
        if !arrive {
            let p = Geo.entree(trajet)
            let pos = Geo.courbe(a, b, p, bosse: 40)
            ctx.drawLayer { couche in
                couche.blendMode = .plusLighter
                for i in 0..<14 {
                    let q = max(0, p - Double(i) * 0.025)
                    let centre = Geo.courbe(a, b, q, bosse: 40)
                    let angle = q * 30 + Double(i)
                    let c = CGPoint(x: centre.x + cs(angle) * 12, y: centre.y + sn(angle) * 12)
                    couche.fill(Path(ellipseIn: Geo.carre(c, 3.5 - CGFloat(i) * 0.2)),
                                with: .color((i.isMultiple(of: 2) ? cyan : mauve).opacity(1 - Double(i) / 14)))
                }
                couche.fill(Path(ellipseIn: Geo.carre(pos, 22)),
                            with: .radialGradient(Gradient(colors: [.white, mauve, mauve.opacity(0)]), center: pos, startRadius: 0, endRadius: 22))
            }
            return
        }
        let k = impact
        let r = CGFloat(30 + 24 * Geo.sortie(min(1, k * 2)))
        ctx.drawLayer { couche in
            couche.opacity = 1 - k * k
            couche.translateBy(x: b.x, y: b.y)
            couche.scaleBy(x: 1, y: 0.55)
            couche.rotate(by: .radians(k * 3))
            couche.stroke(Path(ellipseIn: Geo.carre(.zero, r)), with: .color(cyan), lineWidth: 2.5)
            couche.stroke(Path(ellipseIn: Geo.carre(.zero, r * 0.72)), with: .color(mauve), lineWidth: 1.5)
            // Runes : petits traits entre les deux cercles.
            for i in 0..<12 {
                let angle = Double(i) / 12 * 2 * .pi
                var rune = Path()
                rune.move(to: CGPoint(x: cs(angle) * r * 0.76, y: sn(angle) * r * 0.76))
                rune.addLine(to: CGPoint(x: cs(angle + 0.12) * r * 0.95, y: sn(angle + 0.12) * r * 0.95))
                couche.stroke(rune, with: .color(.white), lineWidth: 2)
            }
        }
        ctx.drawLayer { couche in
            couche.blendMode = .plusLighter
            for i in 0..<12 {
                let angle = Double(i) / 12 * 2 * .pi
                let d = CGFloat(10 + 60 * Geo.sortie(k))
                let c = CGPoint(x: b.x + cs(angle) * d, y: b.y + sn(angle) * d - CGFloat(20 * k))
                couche.opacity = 1 - k
                couche.drawLayer { etoile in
                    etoile.translateBy(x: c.x, y: c.y)
                    etoile.fill(Geo.etoile(rayon: 6, creux: 2, branches: 4), with: .color(i.isMultiple(of: 2) ? cyan : .white))
                }
            }
        }
    }

    // MARK: Créatures : un souffle de feu en cône, puis une gerbe de flammes

    private func souffle(_ ctx: inout GraphicsContext) {
        let couleurs: [Color] = [.white, .yellow, .orange, Color(red: 0.9, green: 0.2, blue: 0.05)]
        let dx = b.x - a.x, dy = b.y - a.y
        let longueur = max(1, hypot(dx, dy))
        let normale = CGPoint(x: -dy / longueur, y: dx / longueur)
        ctx.drawLayer { couche in
            couche.blendMode = .plusLighter
            // Le souffle dure jusqu'au milieu de l'impact.
            let emission = min(t, TempsAttaque.arrivee + 0.2)
            for i in 0..<70 {
                let graine = Double(i) + 1
                let ne = Double(i) / 70 * emission
                let age = t - ne
                let vie = 0.42
                guard age >= 0, age < vie else { continue }
                let q = age / vie
                let ecart = CGFloat(sin(graine * 12.9898)) * 34 * CGFloat(q)
                let base = Geo.ligne(a, b, min(1.05, q * 1.05))
                let c = CGPoint(x: base.x + normale.x * ecart, y: base.y + normale.y * ecart)
                let r: CGFloat = 5 + 16 * CGFloat(q)
                let teinte = couleurs[min(3, Int(q * 4))]
                couche.fill(Path(ellipseIn: Geo.carre(c, r)), with: .color(teinte.opacity(0.55 * (1 - q))))
            }
        }
        guard arrive else { return }
        let k = impact
        ctx.drawLayer { couche in
            couche.blendMode = .plusLighter
            for i in 0..<9 {
                let angle = -Double.pi / 2 + (Double(i) - 4) * 0.28
                let haut = CGFloat((40 + Double(i % 3) * 14) * Geo.sortie(min(1, k * 2)) * (1 - k * 0.6))
                let c = CGPoint(x: b.x + cs(angle) * haut * 0.6, y: b.y + sn(angle) * haut)
                couche.fill(Path(ellipseIn: Geo.carre(c, CGFloat(10 * (1 - k) + 2))), with: .color(Color.orange.opacity(1 - k)))
            }
        }
    }

    // MARK: Morts-vivants : trois âmes qui ondulent, puis un crâne et une brume verte

    private func ames(_ ctx: inout GraphicsContext) {
        let vert = Color(red: 0.45, green: 1, blue: 0.5)
        for i in 0..<3 {
            let retard = Double(i) * 0.05
            let p = min(1, max(0, (t - retard) / (TempsAttaque.arrivee - 0.1)))
            guard p > 0, p < 1 else { continue }
            for trace in 0..<8 {
                let q = max(0, p - Double(trace) * 0.03)
                let ondule = CGFloat(sin(q * 14 + Double(i) * 2)) * 18
                let c = Geo.courbe(a, b, q, bosse: CGFloat(i - 1) * 50 + ondule)
                let r = 9 - CGFloat(trace)
                ctx.fill(Path(ellipseIn: Geo.carre(c, max(1, r))), with: .color(vert.opacity(0.75 - Double(trace) * 0.09)))
                if trace == 0 {
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4, y: c.y - 2, width: 3, height: 3)), with: .color(.black))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x + 1, y: c.y - 2, width: 3, height: 3)), with: .color(.black))
                }
            }
        }
        guard arrive else { return }
        let k = impact
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: 10))
            let r = CGFloat(30 + 50 * Geo.sortie(k))
            couche.fill(Path(ellipseIn: CGRect(x: b.x - r, y: b.y - r * 0.6, width: 2 * r, height: 1.2 * r)),
                        with: .color(vert.opacity(0.45 * (1 - k))))
        }
        // Crâne qui monte et s'efface.
        ctx.drawLayer { couche in
            couche.opacity = k < 0.5 ? 1 : (1 - k) * 2
            couche.translateBy(x: b.x, y: b.y - 40 * k)
            let e = 0.7 + 0.5 * Geo.sortie(min(1, k * 3))
            couche.scaleBy(x: e, y: e)
            couche.fill(Path(ellipseIn: CGRect(x: -16, y: -18, width: 32, height: 28)), with: .color(.white))
            couche.fill(Path(roundedRect: CGRect(x: -9, y: 6, width: 18, height: 10), cornerRadius: 3), with: .color(.white))
            couche.fill(Path(ellipseIn: CGRect(x: -11, y: -8, width: 9, height: 10)), with: .color(Color(red: 0.1, green: 0.3, blue: 0.1)))
            couche.fill(Path(ellipseIn: CGRect(x: 2, y: -8, width: 9, height: 10)), with: .color(Color(red: 0.1, green: 0.3, blue: 0.1)))
        }
    }

    // MARK: Tireurs : une volée de flèches en cloche, puis les flèches plantées

    private func fleches(_ ctx: inout GraphicsContext) {
        let bois = Color(red: 0.85, green: 0.65, blue: 0.4)
        for i in 0..<5 {
            let retard = Double(i) * 0.035
            let p = min(1, max(0, (t - retard) / (TempsAttaque.arrivee - 0.14)))
            guard p > 0 else { continue }
            let decale = CGPoint(x: CGFloat(i - 2) * 14, y: CGFloat((i * 7) % 5 - 2) * 5)
            let cible = CGPoint(x: b.x + decale.x, y: b.y + decale.y)
            let bosse: CGFloat = 90 + CGFloat(i) * 8
            let pos = Geo.courbe(a, cible, p, bosse: bosse)
            let avant = Geo.courbe(a, cible, max(0, p - 0.04), bosse: bosse)
            let angle = p < 1 ? atan2(pos.y - avant.y, pos.x - avant.x) : atan2(cible.y - a.y, cible.x - a.x)
            let fondu = arrive ? max(0, 1 - impact * 1.4) : 1
            ctx.drawLayer { couche in
                couche.opacity = fondu
                couche.translateBy(x: pos.x, y: pos.y)
                couche.rotate(by: .radians(Double(angle)))
                var tige = Path()
                tige.move(to: CGPoint(x: -26, y: 0))
                tige.addLine(to: CGPoint(x: 0, y: 0))
                couche.stroke(tige, with: .color(bois), lineWidth: 2.5)
                var pointe = Path()
                pointe.move(to: CGPoint(x: 6, y: 0))
                pointe.addLine(to: CGPoint(x: -2, y: -4))
                pointe.addLine(to: CGPoint(x: -2, y: 4))
                pointe.closeSubpath()
                couche.fill(pointe, with: .color(.white))
                var plume = Path()
                plume.move(to: CGPoint(x: -26, y: 0))
                plume.addLine(to: CGPoint(x: -32, y: -5))
                plume.move(to: CGPoint(x: -26, y: 0))
                plume.addLine(to: CGPoint(x: -32, y: 5))
                couche.stroke(plume, with: .color(.red), lineWidth: 2)
            }
            if p >= 1 && arrive {
                let r = CGFloat(4 + 18 * Geo.sortie(impact))
                ctx.stroke(Path(ellipseIn: Geo.carre(cible, r)), with: .color(bois.opacity(0.7 * (1 - impact))), lineWidth: 1.5)
            }
        }
    }

    // MARK: Soldats : éclair de bouche à feu, trois balles traçantes, puis une explosion

    private func salve(_ ctx: inout GraphicsContext) {
        let feu = Color(red: 1, green: 0.6, blue: 0.15)
        // Éclair de départ.
        if t < 0.18 {
            let k = t / 0.18
            ctx.drawLayer { couche in
                couche.blendMode = .plusLighter
                couche.fill(Path(ellipseIn: Geo.carre(a, CGFloat(10 + 22 * k))),
                            with: .radialGradient(Gradient(colors: [.white, feu.opacity(0)]), center: a, startRadius: 0, endRadius: CGFloat(10 + 22 * k)))
            }
        }
        for i in 0..<3 {
            let depart = 0.08 + Double(i) * 0.07
            let p = min(1, max(0, (t - depart) / (TempsAttaque.arrivee - depart)))
            guard p > 0, p < 1 else { continue }
            let decale = CGFloat(i - 1) * 10
            let pa = CGPoint(x: a.x + decale, y: a.y)
            let pb = CGPoint(x: b.x + decale, y: b.y)
            let tete = Geo.ligne(pa, pb, p)
            let queue = Geo.ligne(pa, pb, max(0, p - 0.18))
            var trait = Path()
            trait.move(to: queue)
            trait.addLine(to: tete)
            ctx.stroke(trait, with: .linearGradient(Gradient(colors: [feu.opacity(0), .yellow]), startPoint: queue, endPoint: tete),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
            ctx.fill(Path(ellipseIn: Geo.carre(tete, 3)), with: .color(.white))
        }
        guard arrive else { return }
        let k = impact
        ctx.drawLayer { couche in
            couche.blendMode = .plusLighter
            let r = CGFloat(12 + 50 * Geo.sortie(min(1, k * 1.6)))
            couche.fill(Path(ellipseIn: Geo.carre(b, r)),
                        with: .radialGradient(Gradient(colors: [.white.opacity(1 - k), feu.opacity(1 - k), .red.opacity(0)]),
                                              center: b, startRadius: 0, endRadius: r))
        }
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: 6))
            for i in 0..<6 {
                let angle = Double(i) / 6 * 2 * .pi
                let d = CGFloat(20 + 40 * k)
                let c = CGPoint(x: b.x + cs(angle) * d, y: b.y + sn(angle) * d * 0.7 - CGFloat(20 * k))
                couche.fill(Path(ellipseIn: Geo.carre(c, CGFloat(12 + 10 * k))), with: .color(.gray.opacity(0.5 * (1 - k))))
            }
        }
    }
}

// MARK: - Géométrie

private func cs(_ angle: Double) -> CGFloat { CGFloat(Foundation.cos(angle)) }
private func sn(_ angle: Double) -> CGFloat { CGFloat(Foundation.sin(angle)) }

private enum Geo {
    static func ligne(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        let f = CGFloat(t)
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }

    /// Point d'une courbe de Bézier de `a` à `b`, bombée de `bosse` points perpendiculairement au trajet.
    static func courbe(_ a: CGPoint, _ b: CGPoint, _ t: Double, bosse: CGFloat) -> CGPoint {
        let dx = b.x - a.x, dy = b.y - a.y
        let longueur = max(1, hypot(dx, dy))
        let milieu = CGPoint(x: (a.x + b.x) / 2 - dy / longueur * bosse, y: (a.y + b.y) / 2 + dx / longueur * bosse)
        let f = CGFloat(t), g = 1 - f
        return CGPoint(x: g * g * a.x + 2 * g * f * milieu.x + f * f * b.x,
                       y: g * g * a.y + 2 * g * f * milieu.y + f * f * b.y)
    }

    static func entree(_ t: Double) -> Double { t * t }
    static func sortie(_ t: Double) -> Double { 1 - (1 - t) * (1 - t) }

    static func carre(_ c: CGPoint, _ r: CGFloat) -> CGRect {
        CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
    }

    /// Étoile centrée sur l'origine.
    static func etoile(rayon: CGFloat, creux: CGFloat, branches: Int) -> Path {
        var p = Path()
        for i in 0..<(branches * 2) {
            let angle = Double(i) * .pi / Double(branches) - .pi / 2
            let r = i.isMultiple(of: 2) ? rayon : creux
            let point = CGPoint(x: cs(angle) * r, y: sn(angle) * r)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Repères des cartes

/// Cadres des cartes des deux camps, pour faire partir et arriver les attaques sur les avatars.
struct CadresCamps: PreferenceKey {
    static let defaultValue: [Int: Anchor<CGRect>] = [:]
    static func reduce(value: inout [Int: Anchor<CGRect>], nextValue: () -> [Int: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}
