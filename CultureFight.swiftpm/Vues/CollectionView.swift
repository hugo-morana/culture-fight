import SwiftUI

/// « Ma collection » : tous les combattants en cartes, groupés par domaine.
struct CollectionView: View {
    let retour: () -> Void

    @State private var detail: ModeleCombattant?
    @Namespace private var zoom
    private let colonnes = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private var domaines: [String] {
        var vus: [String] = []
        for modele in Catalogue.prototype where !vus.contains(modele.specialite.domaine) {
            vus.append(modele.specialite.domaine)
        }
        return vus
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(domaines, id: \.self) { domaine in
                        let modeles = Catalogue.prototype.filter { $0.specialite.domaine == domaine }
                        Text("\(domaine) · \(modeles.count)")
                            .font(.title3.bold())
                        LazyVGrid(columns: colonnes, spacing: 12) {
                            ForEach(modeles) { modele in
                                Button {
                                    detail = modele
                                } label: {
                                    CarteCollection(modele: modele)
                                        .modifier(SourceZoom(id: modele.id, espace: zoom))
                                }
                                .buttonStyle(.plain)
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
                    .font(.system(size: taille, weight: .heavy, design: .rounded))
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
                .frame(height: 130)
                .overlay(alignment: .top) { IllustrationCombattant(modele: modele) }
                .clipped()
            VStack(spacing: 2) {
                Text(modele.nom)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Color.clear
                        .frame(height: 280)
                        .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 80) }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.85), lineWidth: 2))
                        .shadow(color: modele.specialite.couleur.opacity(0.6), radius: 16)
                        .modifier(Holographique())
                    Text("Incline la carte avec le doigt")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(modele.nom).font(.largeTitle.bold())
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
