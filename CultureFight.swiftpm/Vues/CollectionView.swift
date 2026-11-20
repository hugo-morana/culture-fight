import SwiftUI

/// « Ma collection » : tous les combattants en cartes, groupés par domaine.
struct CollectionView: View {
    let retour: () -> Void

    @State private var detail: ModeleCombattant?
    @State private var retournes: Set<String> = []
    @Namespace private var zoom
    private let colonnes = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var domaines: [String] {
        var vus: [String] = []
        for modele in Catalogue.prototype where !vus.contains(modele.specialite.domaine) {
            vus.append(modele.specialite.domaine)
        }
        return vus
    }

    private func retourner(_ id: String) {
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            if retournes.contains(id) { retournes.remove(id) } else { retournes.insert(id) }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(domaines, id: \.self) { domaine in
                        let modeles = Catalogue.prototype.filter { $0.specialite.domaine == domaine }
                        Text("\(domaine) · \(modeles.count)")
                            .font(.titre(22, relativeTo: .title3))
                            .lettrageLogo()
                        LazyVGrid(columns: colonnes, spacing: 12) {
                            ForEach(modeles) { modele in
                                CarteAnimee(progression: retournes.contains(modele.id) ? 1 : 0,
                                            modele: modele) { detail = modele }
                                    .frame(height: 200)
                                    .zIndex(retournes.contains(modele.id) ? 1 : 0)
                                    .contentShape(RoundedRectangle(cornerRadius: 12))
                                    .onTapGesture { retourner(modele.id) }
                                    .modifier(SourceZoom(id: modele.id, espace: zoom))
                                    .sensoryFeedback(.impact(weight: .light), trigger: retournes.contains(modele.id))
                                .scrollTransition(.interactive, axis: .vertical) { carte, phase in
                                    carte
                                        .scaleEffect(phase.isIdentity ? 1 : 0.86)
                                        .opacity(phase.isIdentity ? 1 : 0.55)
                                        .rotation3DEffect(.degrees(phase.value * -22), axis: (x: 1, y: 0, z: 0))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Ma collection")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
            }
            .sheet(item: $detail) { modele in
                FicheCombattantView(modele: modele)
                    .modifier(TransitionZoom(id: modele.id, espace: zoom))
            }
        }
    }
}

/// Illustration d'un combattant qui remplit son cadre, ou ses initiales s'il n'en a pas.
struct IllustrationCombattant: View {
    let modele: ModeleCombattant
    var taille: CGFloat = 44

    var body: some View {
        if let image = Illustrations.partage.image(pour: modele.id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(modele.specialite.couleur.gradient)
                Text(modele.initiales)
                    .font(.titre(taille))
                    .foregroundStyle(.white)
            }
        }
    }
}

/// Une carte de la collection, dans le style des cartes du jeu.
struct CarteCollection: View {
    let modele: ModeleCombattant

    private static let fond = Color(red: 0.05, green: 0.08, blue: 0.2)

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(maxHeight: .infinity)
                .overlay(alignment: .top) { IllustrationCombattant(modele: modele) }
                .clipped()
            VStack(spacing: 2) {
                // Place réservée : le nom est dessiné par CarteAnimee pour pouvoir pivoter.
                Text(modele.nom)
                    .font(.nom(17))
                    .lineLimit(1)
                    .hidden()
                Text("\(modele.style) · \(modele.specialite.nom)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(modele.specialite.domaine)
                    .font(.caption.bold())
                    .foregroundStyle(modele.specialite.couleur)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Self.fond)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.85), lineWidth: 2))
        .shadow(color: Color.blue.opacity(0.45), radius: 6)
    }
}

/// La fiche complète d'un combattant.
struct FicheCombattantView: View {
    let modele: ModeleCombattant

    @Environment(\.dismiss) private var fermer
    @State private var exemple: String?
    @State private var angle: Double = 0

    private var recto: some View {
        Color.clear
            .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 80) }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.85), lineWidth: 2))
    }

    private func retourner() {
        withAnimation(.spring(duration: 0.7, bounce: 0.3)) { angle += 180 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    CarteRetournable(angle: angle, recto: recto, verso: VersoCarte(modele: modele))
                        .frame(height: 280)
                        .shadow(color: modele.specialite.couleur.opacity(0.6), radius: 16)
                        .modifier(Holographique(toucher: retourner))
                        .sensoryFeedback(.impact(weight: .medium), trigger: angle)
                    Text("Touche la carte pour la retourner, glisse pour l'incliner")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(modele.nom).font(.titre(32, relativeTo: .largeTitle)).lettrageLogo()
                        Text("\(modele.style) · \(modele.specialite.nom)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("\(modele.specialite.domaine) · \(modele.specialite.famille)")
                            .font(.subheadline.bold())
                            .foregroundStyle(modele.specialite.couleur)
                    }

                    HStack(spacing: 16) {
                        Label("\(modele.pvMax) PV", systemImage: "heart.fill")
                        Label("Att \(modele.attaque)", systemImage: "bolt.fill")
                        Label("Déf \(modele.defense)", systemImage: "shield.fill")
                    }
                    .font(.subheadline.monospacedDigit())

                    rubrique("Rareté", modele.rarete.rawValue)
                    rubrique("Apparence", modele.apparence)
                    rubrique("Questions", modele.questions)
                    rubrique("Bonus de vitesse (\(modele.familleStyle.effetVitesse.nom))",
                             "Famille \(modele.familleStyle.rawValue) : \(modele.familleStyle.effetVitesse.description).")
                    if let exemple {
                        rubrique("Exemple de question", "« \(exemple) »")
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { fermer() }
                }
            }
            .onAppear {
                if exemple == nil { exemple = modele.exempleDeQuestion() }
            }
        }
    }

    private func rubrique(_ titre: String, _ texte: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titre).font(.caption.bold()).foregroundStyle(.secondary)
            Text(texte).font(.body).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Dos de la carte : la fiche technique du combattant.
struct VersoCarte: View {
    let modele: ModeleCombattant

    private static let fond = Color(red: 0.05, green: 0.08, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(modele.nom)
                    .font(.titre(22, relativeTo: .title2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Text(modele.rarete.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(modele.specialite.couleur.opacity(0.35)))
            }
            Text("\(modele.style) · \(modele.specialite.nom)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            jauge("PV", "heart.fill", modele.pvMax, sur: 150, couleur: .green)
            jauge("Attaque", "bolt.fill", modele.attaque, sur: 80, couleur: .orange)
            jauge("Défense", "shield.fill", modele.defense, sur: 20, couleur: .cyan)
            Spacer(minLength: 0)
            Label("Bonus de vitesse : \(modele.familleStyle.effetVitesse.nom)", systemImage: "hare.fill")
                .font(.footnote.bold())
                .foregroundStyle(modele.specialite.couleur)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.fond)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.85), lineWidth: 2))
    }

    private func jauge(_ titre: String, _ icone: String, _ valeur: Int, sur maximum: Int, couleur: Color) -> some View {
        let part = min(1.0, Double(valeur) / Double(maximum))
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Label(titre, systemImage: icone)
                Spacer()
                Text("\(valeur)").monospacedDigit()
            }
            .font(.caption.bold())
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(couleur.gradient)
                        .frame(width: geo.size.width * part)
                }
            }
            .frame(height: 6)
        }
    }
}

/// Dos d'une carte de la grille : les stats en bref et l'accès à la fiche.
struct VersoCollection: View {
    let modele: ModeleCombattant
    let ouvrir: () -> Void

    private static let fond = Color(red: 0.05, green: 0.08, blue: 0.2)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(modele.rarete.rawValue)
                .font(.caption2.bold())
                .foregroundStyle(modele.specialite.couleur)
            ligne("heart.fill", "PV", modele.pvMax, sur: 150, couleur: .green)
            ligne("bolt.fill", "Att", modele.attaque, sur: 80, couleur: .orange)
            ligne("shield.fill", "Déf", modele.defense, sur: 20, couleur: .cyan)
            Label(modele.familleStyle.effetVitesse.nom, systemImage: "hare.fill")
                .font(.caption2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Button(action: ouvrir) {
                Label("Voir la fiche", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(modele.specialite.couleur)
        }
        .padding(10)
        .padding(.leading, 26) // le nom vertical occupe le bord gauche
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 12).fill(Self.fond))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(modele.specialite.couleur.opacity(0.9), lineWidth: 2))
        .shadow(color: modele.specialite.couleur.opacity(0.45), radius: 6)
    }

    private func ligne(_ icone: String, _ titre: String, _ valeur: Int, sur maximum: Int, couleur: Color) -> some View {
        let part = min(1.0, Double(valeur) / Double(maximum))
        return HStack(spacing: 6) {
            Image(systemName: icone)
                .foregroundStyle(couleur)
                .frame(width: 14)
            Capsule().fill(Color.white.opacity(0.12))
                .frame(height: 5)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule().fill(couleur.gradient).frame(width: geo.size.width * part)
                    }
                }
            Text("\(valeur)")
                .monospacedDigit()
                .frame(width: 26, alignment: .trailing)
        }
        .font(.caption2.bold())
        .accessibilityLabel("\(titre) \(valeur)")
    }
}

/// Carte de la grille animée de bout en bout par une seule valeur, de 0 (recto) à 1 (verso) :
/// la carte pivote en 3D, grossit à mi-course, et le nom glisse du bas de la carte
/// jusqu'au bord gauche en tournant de 90° et en grossissant.
struct CarteAnimee: View, Animatable {
    var progression: Double
    let modele: ModeleCombattant
    let ouvrir: () -> Void

    var animatableData: Double {
        get { progression }
        set { progression = newValue }
    }

    private static func melange(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    var body: some View {
        let t = CGFloat(progression)
        let zoom = 1 + 0.16 * sin(progression * Double.pi)
        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                CarteRetournable(angle: progression * 180,
                                 recto: CarteCollection(modele: modele),
                                 verso: VersoCollection(modele: modele, ouvrir: ouvrir))
                Text(modele.nom)
                    .font(.custom(Charte.policeBlack, size: Self.melange(17, 21, t)))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Charte.ivoire)
                    .shadow(color: Charte.marine, radius: 0, x: 0, y: 1.5)
                    .shadow(color: .black.opacity(0.6), radius: 3)
                    .frame(width: Self.melange(w - 16, h - 24, t))
                    .rotationEffect(.degrees(-90 * progression))
                    .position(x: Self.melange(w / 2, 20, t),
                              y: Self.melange(h - 49, h / 2, t))
                    .allowsHitTesting(false)
            }
        }
        .scaleEffect(zoom)
        .shadow(color: modele.specialite.couleur.opacity(0.5 * sin(progression * Double.pi)), radius: 14)
    }
}
