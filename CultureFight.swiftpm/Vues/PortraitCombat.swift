import SwiftUI

/// Rôle d'un camp pendant le tour : qui pose la question (attaque), qui répond (défense).
enum RoleCombat: Equatable {
    case attaque, defense

    var titre: String { self == .attaque ? "Attaque" : "Défense" }
    var icone: String { self == .attaque ? "bolt.fill" : "shield.lefthalf.filled" }
    var couleur: Color {
        self == .attaque ? Color(red: 1, green: 0.55, blue: 0.15) : Color(red: 0.3, green: 0.65, blue: 1)
    }
}

/// Illustration du combattant actif en combat, mise en avant : liseré et badge de son rôle (attaque ou
/// défense), et des gestes qui racontent le tour. L'attaquant prend son élan puis s'élance vers
/// l'adversaire, le coup arrivant avec l'animation d'attaque (`TempsAttaque.arrivee`) ; le défenseur
/// esquive de côté sur une bonne réponse, ou encaisse le coup (recul et éclair rouge) sur une mauvaise.
struct PortraitCombat: View {
    let modele: ModeleCombattant
    let estKO: Bool
    let role: RoleCombat?
    /// Le camp est en bas de l'écran : il s'élance vers le haut.
    let enBas: Bool
    /// Augmente à chaque geste.
    let coups: Int
    let esquives: Int
    let touches: Int
    var reduit = false

    static let taille = CGSize(width: 84, height: 104)

    struct Elan {
        var y: CGFloat = 0
        var echelle: CGFloat = 1
        var angle: Double = 0
    }

    struct Esquive {
        var x: CGFloat = 0
        var angle: Double = 0
        var echelle: CGFloat = 1
        var texte: Double = 0
    }

    struct Touche {
        var recul: CGFloat = 0
        var rouge: Double = 0
        var angle: Double = 0
    }

    var body: some View {
        let sens: CGFloat = enBas ? -1 : 1
        let teinte = role?.couleur ?? Charte.or
        Color.clear
            .frame(width: Self.taille.width, height: Self.taille.height)
            .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 30) }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(teinte, lineWidth: role == nil ? 1.5 : 3))
            .shadow(color: teinte.opacity(role == .attaque ? 0.8 : 0.4), radius: role == .attaque ? 10 : 5)
            .saturation(estKO ? 0 : 1)
            .overlay(alignment: .bottom) {
                if let role, !estKO {
                    Label(role.titre, systemImage: role.icone)
                        .font(.system(size: 10, weight: .heavy))
                        .textCase(.uppercase)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(role.couleur, in: Capsule())
                        .offset(y: 9)
                        .transition(.scale.combined(with: .opacity))
                        .id(role)
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.4), value: role)
            .scaleEffect(role == .attaque ? 1.06 : 1)
            .animation(.spring(duration: 0.4), value: role == .attaque)
            // Encaisse le coup : recul, inclinaison et éclair rouge à l'arrivée de l'attaque.
            .keyframeAnimator(initialValue: Touche(), trigger: touches) { vue, t in
                vue
                    .overlay(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(t.rouge)).allowsHitTesting(false))
                    .offset(y: -sens * t.recul)
                    .rotationEffect(.degrees(t.angle))
            } keyframes: { _ in
                KeyframeTrack(\.recul) {
                    LinearKeyframe(0, duration: reduit ? 0 : TempsAttaque.arrivee)
                    SpringKeyframe(-14, duration: 0.1)
                    SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                }
                KeyframeTrack(\.rouge) {
                    LinearKeyframe(0, duration: reduit ? 0 : TempsAttaque.arrivee)
                    LinearKeyframe(0.55, duration: 0.06)
                    LinearKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.angle) {
                    LinearKeyframe(0, duration: reduit ? 0 : TempsAttaque.arrivee)
                    LinearKeyframe(reduit ? 0 : -9, duration: 0.08)
                    SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                }
            }
            // Esquive : un pas de côté juste avant que le coup n'arrive, puis retour.
            .keyframeAnimator(initialValue: Esquive(), trigger: esquives) { vue, e in
                vue
                    .offset(x: e.x)
                    .rotationEffect(.degrees(e.angle))
                    .scaleEffect(e.echelle)
                    .overlay(alignment: .top) {
                        Text("Esquive !")
                            .font(.titre(15))
                            .foregroundStyle(RoleCombat.defense.couleur)
                            .shadow(color: .black, radius: 2)
                            .fixedSize()
                            .opacity(e.texte)
                            .scaleEffect(0.6 + 0.5 * e.texte)
                            .offset(y: -22)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.x) {
                    LinearKeyframe(0, duration: reduit ? 0 : 0.2)
                    SpringKeyframe(reduit ? 0 : 46, duration: 0.18, spring: .snappy)
                    LinearKeyframe(reduit ? 0 : 46, duration: 0.3)
                    SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                }
                KeyframeTrack(\.angle) {
                    LinearKeyframe(0, duration: reduit ? 0 : 0.2)
                    SpringKeyframe(reduit ? 0 : 14, duration: 0.18)
                    LinearKeyframe(reduit ? 0 : 14, duration: 0.3)
                    SpringKeyframe(0, duration: 0.45)
                }
                KeyframeTrack(\.echelle) {
                    LinearKeyframe(1, duration: reduit ? 0 : 0.2)
                    SpringKeyframe(0.9, duration: 0.18)
                    LinearKeyframe(0.9, duration: 0.3)
                    SpringKeyframe(1, duration: 0.45)
                }
                KeyframeTrack(\.texte) {
                    LinearKeyframe(0, duration: reduit ? 0 : 0.25)
                    SpringKeyframe(1, duration: 0.2)
                    LinearKeyframe(1, duration: 0.7)
                    LinearKeyframe(0, duration: 0.3)
                }
            }
            // Coup : recul d'élan, puis bond vers l'adversaire au moment où l'attaque part et arrive.
            .keyframeAnimator(initialValue: Elan(), trigger: coups) { vue, e in
                vue
                    .scaleEffect(e.echelle)
                    .rotationEffect(.degrees(e.angle))
                    .offset(y: sens * e.y)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(reduit ? 0 : -12, duration: 0.18)
                    CubicKeyframe(reduit ? 0 : 54, duration: 0.2)
                    LinearKeyframe(reduit ? 0 : 54, duration: 0.12)
                    SpringKeyframe(0, duration: 0.5, spring: .bouncy)
                }
                KeyframeTrack(\.echelle) {
                    CubicKeyframe(0.94, duration: 0.18)
                    CubicKeyframe(1.3, duration: 0.2)
                    LinearKeyframe(1.3, duration: 0.12)
                    SpringKeyframe(1, duration: 0.5)
                }
                KeyframeTrack(\.angle) {
                    CubicKeyframe(reduit ? 0 : -6, duration: 0.18)
                    CubicKeyframe(reduit ? 0 : 8, duration: 0.2)
                    LinearKeyframe(reduit ? 0 : 8, duration: 0.12)
                    SpringKeyframe(0, duration: 0.5)
                }
            }
            .accessibilityHidden(true)
    }
}
