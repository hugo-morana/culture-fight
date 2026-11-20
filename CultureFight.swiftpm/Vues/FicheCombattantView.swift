import SwiftUI
import Charts

// Fiche complète d'un combattant, sur le modèle des fiches d'éléments de PM Chimie :
// en-tête animé, tuiles « en un coup d'œil », puis des cartes thématiques qui apparaissent au défilement.
// Lettrage et couleurs : charte de Culture Fight (Cinzel, ivoire, or, marine).

struct FicheCombattantView: View {
    let modele: ModeleCombattant

    @Environment(\.dismiss) private var fermer
    @State private var exemple: String?
    @State private var angle: Double = 0

    private var accent: Color { modele.specialite.couleur }
    private var tableaux: [TableauDonnees] { modele.generateur.apercu }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EnTeteFiche(modele: modele)
                    TuilesFiche(modele: modele, nombreDeQuestions: Self.compter(tableaux))
                    carteDeCombat
                    if let histoire = modele.histoire {
                        CarteFiche(titre: "Histoire", icone: "book.closed.fill", accent: accent) {
                            Text(histoire.histoire)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Charte.ivoire.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let histoire = modele.histoire, let pays = modele.paysDOrigine {
                        CarteOrigine(histoire: histoire, pays: pays, accent: accent)
                    }
                    CarteFiche(titre: "Apparence", icone: "eye.fill", accent: accent) {
                        TexteFiche(texte: modele.apparence)
                    }
                    CarteQuestions(modele: modele, tableaux: tableaux, exemple: exemple, accent: accent)
                    CarteFiche(titre: "Bonus de vitesse · \(modele.familleStyle.effetVitesse.nom)",
                               icone: "hare.fill", accent: accent) {
                        TexteFiche(texte: "Type \(modele.type) : \(modele.familleStyle.effetVitesse.description).")
                    }
                    if !tableaux.isEmpty {
                        CarteFiche(titre: "Données des questions", icone: "tablecells.fill", accent: accent) {
                            VStack(alignment: .leading, spacing: 18) {
                                ForEach(tableaux) { tableau in
                                    TableauFiche(tableau: tableau, accent: accent)
                                }
                            }
                        }
                    }
                    CarteSources(tableaux: tableaux, accent: accent)
                }
                .padding()
            }
            .background { FondFiche(accent: accent) }
            .navigationTitle(modele.nom)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { fermer() }
                }
            }
            .onAppear {
                if exemple == nil { exemple = modele.exempleDeQuestion() }
            }
        }
    }

    private var carteDeCombat: some View {
        CarteFiche(titre: "Carte de combat", icone: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                   accent: accent) {
            VStack(spacing: 8) {
                CarteRetournable(angle: angle, recto: recto, verso: VersoCarte(modele: modele))
                    .frame(height: 280)
                    .shadow(color: accent.opacity(0.6), radius: 16)
                    .modifier(Holographique(toucher: retourner))
                    .sensoryFeedback(.impact(weight: .medium), trigger: angle)
                Text("Touche la carte pour la retourner, glisse pour l'incliner")
                    .font(.system(.caption2, design: .serif).italic())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var recto: some View {
        Color.clear
            .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 80) }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue.opacity(0.85), lineWidth: 2))
    }

    private func retourner() {
        withAnimation(.spring(duration: 0.7, bounce: 0.3)) { angle += 180 }
    }

    /// Nombre total de questions différentes, nil si au moins un générateur en crée à l'infini.
    static func compter(_ tableaux: [TableauDonnees]) -> Int? {
        var total = 0
        for tableau in tableaux {
            guard let n = tableau.nombreDeQuestions else { return nil }
            total += n
        }
        return total
    }
}

// MARK: - Fond

struct FondFiche: View {
    let accent: Color

    var body: some View {
        ZStack {
            Charte.marine
            RadialGradient(colors: [accent.opacity(0.45), .clear], center: .top, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color.blue.opacity(0.25), .clear], center: .bottomTrailing,
                           startRadius: 0, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Carte générique

struct CarteFiche<Contenu: View>: View {
    let titre: String
    var icone: String? = nil
    var accent: Color = Charte.or
    @ViewBuilder let contenu: Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let icone {
                    Image(systemName: icone).foregroundStyle(accent)
                }
                Text(titre)
                    .font(.nom(17, relativeTo: .headline))
                    .foregroundStyle(Charte.ivoire)
            }
            contenu
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
        .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Charte.or.opacity(0.35), lineWidth: 1))
        .scrollTransition(.animated(.spring(duration: 0.5))) { carte, phase in
            carte
                .opacity(phase.isIdentity ? 1 : 0.35)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                .offset(y: phase == .bottomTrailing ? 24 : 0)
        }
    }
}

struct TexteFiche: View {
    let texte: String

    var body: some View {
        Text(texte)
            .font(.system(.subheadline, design: .serif))
            .foregroundStyle(Charte.ivoire.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct BadgeFiche: View {
    let texte: String
    var couleur: Color = .white.opacity(0.12)

    var body: some View {
        Text(texte)
            .font(.nom(11, relativeTo: .caption2))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(couleur, in: Capsule())
    }
}

// MARK: - En-tête

struct MouvementTuile {
    var echelle = 1.0
    var rotation = 0.0
    var halo = 0.5
}

struct EnTeteFiche: View {
    let modele: ModeleCombattant
    @State private var declencheur = false
    @State private var apparu = false

    private var accent: Color { modele.specialite.couleur }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            tuile
            VStack(alignment: .leading, spacing: 6) {
                Text(modele.nom)
                    .font(.titre(26, relativeTo: .title))
                    .lettrageLogo()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .opacity(apparu ? 1 : 0)
                    .offset(x: apparu ? 0 : -16)
                Text(modele.sousTitre)
                    .font(.nom(14, relativeTo: .subheadline))
                    .foregroundStyle(Charte.ivoire.opacity(0.8))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(modele.classement)
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 6) {
                    BadgeFiche(texte: modele.rarete.rawValue, couleur: accent.opacity(0.35))
                    BadgeFiche(texte: "Difficulté \(modele.difficulte)")
                    BadgeFiche(texte: modele.familleStyle.picto + " " + modele.familleStyle.rawValue)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .animation(.spring(duration: 0.6, bounce: 0.3).delay(0.2), value: apparu)
        }
        .onAppear { apparu = true }
    }

    private var tuile: some View {
        Color.clear
            .frame(width: 112, height: 150)
            .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 40) }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent, lineWidth: 2))
            .overlay(alignment: .bottomLeading) {
                PastillePicto(picto: modele.pictoStyle, taille: 28).padding(6)
            }
            .keyframeAnimator(initialValue: MouvementTuile(), trigger: declencheur) { vue, v in
                vue
                    .scaleEffect(v.echelle)
                    .rotation3DEffect(.degrees(v.rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                    .shadow(color: accent.opacity(v.halo), radius: 18)
            } keyframes: { _ in
                KeyframeTrack(\.echelle) {
                    MoveKeyframe(0.5)
                    SpringKeyframe(1.12, duration: 0.35, spring: .bouncy)
                    SpringKeyframe(1.0, duration: 0.35)
                }
                KeyframeTrack(\.rotation) {
                    MoveKeyframe(-200)
                    CubicKeyframe(15, duration: 0.5)
                    SpringKeyframe(0, duration: 0.45, spring: .bouncy)
                }
                KeyframeTrack(\.halo) {
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: 0.4)
                    LinearKeyframe(0.5, duration: 0.6)
                }
            }
            .onTapGesture { declencheur.toggle() }
            .onAppear { declencheur.toggle() }
            .sensoryFeedback(.impact(weight: .medium), trigger: declencheur)
    }
}

// MARK: - En un coup d'œil

struct TuilesFiche: View {
    let modele: ModeleCombattant
    let nombreDeQuestions: Int?

    private struct Info {
        let icone: String
        let titre: String
        let valeur: String
    }

    private var infos: [Info] {
        [Info(icone: "heart.fill", titre: "PV", valeur: "\(modele.pvMax)"),
         Info(icone: "bolt.fill", titre: "Attaque", valeur: "\(modele.attaque)"),
         Info(icone: "shield.fill", titre: "Défense", valeur: "\(modele.defense)"),
         Info(icone: "hare.fill", titre: "Bonus", valeur: modele.familleStyle.effetVitesse.nom),
         Info(icone: "map.fill", titre: "Origine", valeur: modele.paysDOrigine?.nom ?? "—"),
         Info(icone: "questionmark.bubble.fill", titre: "Questions",
              valeur: nombreDeQuestions.map { "\($0)" } ?? "∞")]
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            ForEach(Array(infos.enumerated()), id: \.offset) { index, info in
                TuileFiche(icone: info.icone, titre: info.titre, valeur: info.valeur,
                           accent: modele.specialite.couleur, index: index)
            }
        }
    }
}

struct TuileFiche: View {
    let icone: String
    let titre: String
    let valeur: String
    let accent: Color
    let index: Int

    @State private var rebond = false
    @State private var visible = false

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icone)
                .symbolEffect(.bounce, value: rebond)
                .font(.title2)
                .foregroundStyle(accent)
                .frame(height: 28)
            Text(titre)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(valeur)
                .font(.nom(13, relativeTo: .caption))
                .foregroundStyle(Charte.ivoire)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(6)
        .background(Charte.marine.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Charte.or.opacity(0.3), lineWidth: 1))
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 18)
        .scaleEffect(visible ? 1 : 0.85)
        .onAppear {
            let delai = 0.08 * Double(index)
            withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(delai + 0.3)) { visible = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + delai + 0.6) { rebond.toggle() }
        }
        .onTapGesture { rebond.toggle() }
    }
}

// MARK: - Origine

struct CarteOrigine: View {
    let histoire: HistoireCombattant
    let pays: PaysDuMonde
    let accent: Color

    private var allies: [ModeleCombattant] {
        histoire.liens.compactMap { id in Catalogue.prototype.first { $0.id == id } }
    }

    var body: some View {
        CarteFiche(titre: "Origine", icone: "map.fill", accent: accent) {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(pays.nom) › \(histoire.lieu)")
                    .font(.nom(15, relativeTo: .subheadline))
                    .foregroundStyle(Charte.or)
                if let lieu = pays.lieu(histoire.lieu) {
                    TexteFiche(texte: lieu.description)
                }
                Text("\(pays.nom), pays du domaine \(pays.domaine) · capitale \(pays.capitale)")
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(accent)
                TexteFiche(texte: pays.description)
                if !allies.isEmpty {
                    Text("Alliés et rivaux")
                        .font(.nom(13, relativeTo: .caption))
                        .foregroundStyle(Charte.or)
                        .padding(.top, 4)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allies) { allie in
                                VStack(spacing: 4) {
                                    Avatar(modele: allie, taille: 52)
                                    Text(allie.nom)
                                        .font(.nom(11, relativeTo: .caption2))
                                        .foregroundStyle(Charte.ivoire)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                        .frame(width: 76)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Questions (répartition en anneau)

struct CarteQuestions: View {
    let modele: ModeleCombattant
    let tableaux: [TableauDonnees]
    let exemple: String?
    let accent: Color

    private struct Part: Identifiable {
        let titre: String
        let nombre: Int
        var id: String { titre }
    }

    private var parts: [Part] {
        tableaux.compactMap { t in t.nombreDeQuestions.map { Part(titre: t.titre, nombre: $0) } }
    }

    @State private var choisie: String?
    @State private var angleChoisi: Int?
    @State private var revele = 0

    static let palette: [Color] = [Color(red: 0.97, green: 0.51, blue: 0.67), Color(red: 0.30, green: 0.67, blue: 0.97),
                                   Color(red: 1.0, green: 0.66, blue: 0.30), Color(red: 0.22, green: 0.85, blue: 0.66),
                                   Color(red: 0.69, green: 0.59, blue: 0.99), Color(red: 1.0, green: 0.83, blue: 0.23)]

    var body: some View {
        CarteFiche(titre: "Questions", icone: "questionmark.bubble.fill", accent: accent) {
            VStack(alignment: .leading, spacing: 12) {
                TexteFiche(texte: modele.questions)
                if parts.count > 1 { anneau }
                if let exemple {
                    Text("Exemple")
                        .font(.nom(13, relativeTo: .caption))
                        .foregroundStyle(Charte.or)
                    Text("« \(exemple) »")
                        .font(.system(.subheadline, design: .serif).italic())
                        .foregroundStyle(accent)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var total: Int { parts.reduce(0) { $0 + $1.nombre } }

    private var montree: Part? {
        parts.first { $0.titre == choisie } ?? parts.max { $0.nombre < $1.nombre }
    }

    @ViewBuilder
    private var anneau: some View {
        let liste = Array(parts.enumerated())
        Chart(liste, id: \.element.id) { index, part in
            SectorMark(angle: .value("Questions", index < revele ? Double(part.nombre) : 0.0001),
                       innerRadius: .ratio(0.6),
                       outerRadius: .ratio(part.titre == montree?.titre ? 1.0 : 0.9),
                       angularInset: 2)
                .cornerRadius(5)
                .foregroundStyle(Self.palette[index % Self.palette.count])
                .opacity(part.titre == montree?.titre ? 1 : 0.7)
        }
        .chartLegend(.hidden)
        .chartAngleSelection(value: $angleChoisi)
        .onChange(of: angleChoisi) { _, valeur in
            guard let valeur else { return }
            var cumul = 0
            for part in parts {
                cumul += part.nombre
                if valeur <= cumul { choisie = part.titre; break }
            }
        }
        .chartBackground { _ in
            VStack(spacing: 2) {
                Text("\(montree?.nombre ?? total)")
                    .font(.titre(26))
                    .foregroundStyle(Charte.ivoire)
                    .contentTransition(.numericText(value: Double(montree?.nombre ?? total)))
                Text("sur \(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 200)
        .animation(.spring(duration: 0.35), value: choisie)
        .sensoryFeedback(.selection, trigger: choisie)
        .onAppear {
            revele = 0
            for k in 1...max(1, parts.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + 0.12 * Double(k)) {
                    withAnimation(.spring(duration: 0.6, bounce: 0.3)) { revele = k }
                }
            }
        }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(liste, id: \.element.id) { index, part in
                Button {
                    withAnimation(.snappy) { choisie = part.titre }
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(Self.palette[index % Self.palette.count]).frame(width: 10, height: 10)
                        Text(part.titre).font(.caption).foregroundStyle(Charte.ivoire).lineLimit(2)
                        Spacer()
                        Text("\(part.nombre)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Tableaux de données

struct TableauFiche: View {
    let tableau: TableauDonnees
    let accent: Color

    @State private var toutVoir = false
    private static let apercu = 8

    private var lignesVisibles: [[String]] {
        toutVoir ? tableau.lignes : Array(tableau.lignes.prefix(Self.apercu))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(tableau.titre)
                .font(.nom(14, relativeTo: .subheadline))
                .foregroundStyle(Charte.or)
                .fixedSize(horizontal: false, vertical: true)
            if let note = tableau.note {
                Text(note)
                    .font(.system(.caption, design: .serif).italic())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(tableau.entetes.enumerated()), id: \.offset) { _, entete in
                        Text(entete)
                            .font(.nom(11, relativeTo: .caption2))
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 4)
                ForEach(Array(lignesVisibles.enumerated()), id: \.offset) { index, ligne in
                    GridRow {
                        ForEach(Array(ligne.enumerated()), id: \.offset) { colonne, cellule in
                            Text(cellule)
                                .font(colonne == ligne.count - 1 ? .caption.weight(.semibold) : .caption)
                                .foregroundStyle(Charte.ivoire.opacity(colonne == ligne.count - 1 ? 1 : 0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 5)
                    .background(index.isMultiple(of: 2) ? Color.white.opacity(0.05) : Color.clear)
                }
            }
            if tableau.lignes.count > Self.apercu {
                Button {
                    withAnimation(.snappy) { toutVoir.toggle() }
                } label: {
                    Label(toutVoir ? "Réduire" : "Tout afficher (\(tableau.lignes.count))",
                          systemImage: toutVoir ? "chevron.up" : "chevron.down")
                        .font(.nom(12, relativeTo: .caption))
                }
                .tint(accent)
            }
        }
    }
}

// MARK: - Sources

struct CarteSources: View {
    let tableaux: [TableauDonnees]
    let accent: Color

    private var sources: [SourceDonnees] {
        var vues: [SourceDonnees] = []
        for jeu in tableaux.compactMap(\.jeu) {
            for source in Univers.sources[jeu] ?? [] where !vues.contains(source) {
                vues.append(source)
            }
        }
        return vues
    }

    var body: some View {
        CarteFiche(titre: "Sources", icone: "books.vertical.fill", accent: accent) {
            if sources.isEmpty {
                TexteFiche(texte: "Questions calculées par l'app : pas de source externe.")
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sources, id: \.self) { source in
                        if let url = URL(string: source.url) {
                            Link(destination: url) {
                                Label(source.titre, systemImage: "link")
                                    .font(.subheadline)
                            }
                            .tint(accent)
                        }
                    }
                    Text("Données vérifiées par outils/verifier.py. Textes reformulés.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
