import SwiftUI

/// Présentation des deux équipes au début du combat (tâche 180) : deux bandeaux en diagonale arrivent
/// de part et d'autre (adversaire en haut, joueur en bas), les cartes illustrées entrent une à une,
/// puis « VS » s'abat au centre avec une onde de choc, des étincelles, une secousse et une vibration.
/// Un toucher passe la présentation. Avec « Réduire les animations », tout apparaît en fondu.
struct PresentationEquipesView: View {
    let joueur: Camp
    let adversaire: Camp
    var reduit = false

    /// Durée totale avant le pile ou face, en secondes.
    static func duree(reduit: Bool) -> Double { reduit ? 1.8 : 3.8 }

    @State private var bandeaux = false
    @State private var cartes = false
    @State private var vs = false
    @State private var onde = false
    @State private var balayage = false
    @State private var secousse = 0

    private static let rouge = Color(red: 0.62, green: 0.08, blue: 0.12)
    private static let bleu = Color(red: 0.07, green: 0.22, blue: 0.62)

    var body: some View {
        GeometryReader { geo in
            let largeur = geo.size.width
            ZStack {
                Color.black.opacity(0.88)

                // Bandeaux en diagonale.
                Bandeau(haut: true)
                    .fill(LinearGradient(colors: [Self.rouge, Self.rouge.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .offset(x: bandeaux ? 0 : largeur * 1.2)
                Bandeau(haut: false)
                    .fill(LinearGradient(colors: [Self.bleu.opacity(0.55), Self.bleu], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .offset(x: bandeaux ? 0 : -largeur * 1.2)
                // Trait de lumière sur la diagonale.
                Diagonale()
                    .trim(from: 0, to: bandeaux ? 1 : 0)
                    .stroke(Charte.or, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .shadow(color: Charte.or, radius: 10)

                VStack(spacing: 0) {
                    equipe(adversaire, enHaut: true, largeur: largeur)
                        .padding(.top, geo.size.height * 0.08)
                    Spacer()
                    equipe(joueur, enHaut: false, largeur: largeur)
                        .padding(.bottom, geo.size.height * 0.08)
                }
                .padding(.horizontal)

                // Onde de choc et étincelles autour du VS.
                Circle()
                    .stroke(Charte.or.opacity(onde ? 0 : 0.9), lineWidth: onde ? 1 : 10)
                    .frame(width: 120, height: 120)
                    .scaleEffect(onde ? 4.5 : 0.3)
                    .opacity(vs ? 1 : 0)
                if onde && !reduit {
                    Etincelles(couleur: Charte.or)
                        .frame(width: 320, height: 320)
                }
                texteVS
            }
            .overlay(alignment: .bottom) {
                Text("Touche pour passer")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom, 8)
                    .opacity(cartes ? 1 : 0)
            }
            .keyframeAnimator(initialValue: CGSize.zero, trigger: secousse) { vue, d in
                vue.offset(d)
            } keyframes: { _ in
                KeyframeTrack(\.width) {
                    LinearKeyframe(12, duration: 0.04)
                    LinearKeyframe(-10, duration: 0.05)
                    LinearKeyframe(6, duration: 0.05)
                    SpringKeyframe(0, duration: 0.25)
                }
                KeyframeTrack(\.height) {
                    LinearKeyframe(-8, duration: 0.05)
                    LinearKeyframe(5, duration: 0.05)
                    SpringKeyframe(0, duration: 0.25)
                }
            }
        }
        .ignoresSafeArea()
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1), trigger: secousse)
        .task { await jouer() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(joueur.nom) contre \(adversaire.nom)")
        .accessibilityHint("Touche pour passer")
    }

    // MARK: Séquence

    private func jouer() async {
        if reduit {
            withAnimation(.easeOut(duration: 0.4)) { bandeaux = true; cartes = true; vs = true }
            return
        }
        withAnimation(.spring(duration: 0.55, bounce: 0.15)) { bandeaux = true }
        try? await Task.sleep(for: .seconds(0.35))
        withAnimation { cartes = true }
        for i in 0..<3 {
            ServiceSons.partage.jouer(.carte, apres: Double(i) * 0.12)
        }
        try? await Task.sleep(for: .seconds(0.9))
        withAnimation(.spring(duration: 0.45, bounce: 0.45)) { vs = true }
        try? await Task.sleep(for: .seconds(0.12))
        ServiceSons.partage.jouer(.impact)
        secousse += 1
        withAnimation(.easeOut(duration: 0.7)) { onde = true }
        try? await Task.sleep(for: .seconds(0.45))
        withAnimation(.easeInOut(duration: 0.9)) { balayage = true }
    }

    // MARK: Équipes

    private func equipe(_ camp: Camp, enHaut: Bool, largeur: CGFloat) -> some View {
        let taille = CGSize(width: min(104, (largeur - 64) / 3), height: min(104, (largeur - 64) / 3) * 1.36)
        let titre = Text(camp.nom)
            .font(.titre(22, relativeTo: .title2))
            .lettrageLogo()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .opacity(bandeaux ? 1 : 0)
            .offset(x: bandeaux ? 0 : (enHaut ? 60 : -60))
        return VStack(spacing: 10) {
            if enHaut { titre }
            HStack(spacing: 12) {
                ForEach(Array(camp.combattants.enumerated()), id: \.element.modele.id) { i, enJeu in
                    // L'adversaire entre par la droite, le joueur par la gauche, en décalé.
                    let rang = Double(enHaut ? camp.combattants.count - 1 - i : i)
                    CartePresentation(modele: enJeu.modele, taille: taille, balayage: balayage,
                                      delaiBalayage: rang * 0.08)
                        .rotationEffect(.degrees(cartes ? Double(i - 1) * (enHaut ? -4 : 4) : (enHaut ? 25 : -25)))
                        .offset(x: cartes ? 0 : (enHaut ? largeur : -largeur), y: cartes ? 0 : (enHaut ? -40 : 40))
                        .opacity(cartes ? 1 : 0)
                        .animation(reduit ? .easeOut(duration: 0.4)
                                   : .spring(duration: 0.6, bounce: 0.35).delay(rang * 0.12), value: cartes)
                }
            }
            if !enHaut { titre }
        }
    }

    private var texteVS: some View {
        Text("VS")
            .font(.titre(92, relativeTo: .largeTitle))
            .foregroundStyle(LinearGradient(colors: [.white, Charte.or, Color(red: 0.75, green: 0.5, blue: 0.1)],
                                            startPoint: .top, endPoint: .bottom))
            .shadow(color: .black, radius: 0, x: 3, y: 4)
            .shadow(color: Charte.or.opacity(0.9), radius: vs ? 22 : 0)
            .scaleEffect(vs ? 1 : 3.2)
            .rotationEffect(.degrees(vs ? -8 : -30))
            .opacity(vs ? 1 : 0)
    }
}

/// Une carte de la présentation : illustration, bord de la couleur de rareté, nom, vignette du domaine,
/// et un reflet qui la traverse une fois toutes les cartes posées.
private struct CartePresentation: View {
    let modele: ModeleCombattant
    let taille: CGSize
    let balayage: Bool
    let delaiBalayage: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if let image = Illustrations.partage.image(pour: modele.id) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Avatar(modele: modele, taille: taille.width * 0.8)
                }
                // Reflet.
                LinearGradient(colors: [.clear, .white.opacity(0.55), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: taille.width * 0.45)
                    .rotationEffect(.degrees(20))
                    .offset(x: balayage ? taille.width * 1.3 : -taille.width * 1.3)
                    .animation(.easeInOut(duration: 0.7).delay(delaiBalayage), value: balayage)
                    .blendMode(.plusLighter)
            }
            .frame(width: taille.width, height: taille.height)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(modele.rarete.couleur, lineWidth: 2.5))
            .overlay(alignment: .topLeading) {
                VignetteDomaine(domaine: modele.specialite.domaine, taille: 26)
                    .offset(x: -8, y: -8)
            }
            .shadow(color: modele.rarete.couleur.opacity(0.7), radius: 10)
            Text(modele.nom)
                .font(.nom(12, relativeTo: .caption))
                .foregroundStyle(Charte.ivoire)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: taille.width + 8)
        }
    }
}

/// Moitié de l'écran au-dessus (ou au-dessous) d'une diagonale légèrement inclinée.
private struct Bandeau: Shape {
    let haut: Bool

    func path(in rect: CGRect) -> Path {
        let gauche = CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.06)
        let droite = CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.06)
        var p = Path()
        if haut {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: droite)
            p.addLine(to: gauche)
        } else {
            p.move(to: gauche)
            p.addLine(to: droite)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        p.closeSubpath()
        return p
    }
}

/// La diagonale qui sépare les deux bandeaux.
private struct Diagonale: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.06))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - rect.height * 0.06))
        return p
    }
}
