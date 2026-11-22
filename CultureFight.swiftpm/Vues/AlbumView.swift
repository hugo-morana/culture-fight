import SwiftUI

// MARK: - Complétion

/// Combattants possédés sur combattants jouables, pour un groupe (domaine, famille, style…).
struct Completion: Equatable {
    var possedes: Int
    var total: Int

    var fraction: Double { total == 0 ? 0 : Double(possedes) / Double(total) }
    var pourcentage: Int { Int((fraction * 100).rounded(.down)) }
    var complete: Bool { total > 0 && possedes == total }
    var texte: String { "\(possedes)/\(total) · \(pourcentage) %" }

    init(possedes: Int = 0, total: Int = 0) {
        self.possedes = possedes
        self.total = total
    }

    init(_ modeles: [ModeleCombattant], possedes ids: Set<String>) {
        self.total = modeles.count
        self.possedes = modeles.filter { ids.contains($0.id) }.count
    }
}

/// Filtre « possédés ou non » de « Ma collection ». Le choix est mémorisé.
enum FiltrePossession: String, CaseIterable, Identifiable {
    case tous, possedes, manquants

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .tous: "Tous"
        case .possedes: "Possédés"
        case .manquants: "À découvrir"
        }
    }

    var icone: String {
        switch self {
        case .tous: "square.stack.3d.up"
        case .possedes: "checkmark.seal"
        case .manquants: "lock"
        }
    }

    func garde(_ modele: ModeleCombattant, possedes: Set<String>) -> Bool {
        switch self {
        case .tous: true
        case .possedes: possedes.contains(modele.id)
        case .manquants: !possedes.contains(modele.id)
        }
    }
}

// MARK: - Éléments graphiques

/// Barre de complétion qui se remplit à l'apparition, dorée quand le groupe est complet.
struct BarreCompletion: View {
    let completion: Completion
    var hauteur: CGFloat = 6

    @State private var affichee: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(completion.complete
                          ? AnyShapeStyle(LinearGradient(colors: [Charte.or, .yellow], startPoint: .leading, endPoint: .trailing))
                          : AnyShapeStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)))
                    .frame(width: geo.size.width * affichee)
            }
        }
        .frame(height: hauteur)
        .onAppear {
            withAnimation(.spring(duration: 0.9, bounce: 0.2).delay(0.1)) { affichee = completion.fraction }
        }
        .onChange(of: completion) { _, nouvelle in
            withAnimation(.spring(duration: 0.6)) { affichee = nouvelle.fraction }
        }
        .accessibilityElement()
        .accessibilityLabel("\(completion.possedes) sur \(completion.total), \(completion.pourcentage) pour cent")
    }
}

/// Anneau de complétion avec le pourcentage au centre.
struct AnneauCompletion: View {
    let completion: Completion
    var taille: CGFloat = 96

    @State private var affichee: Double = 0
    @State private var compte = 0

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: taille * 0.1)
            Circle()
                .trim(from: 0, to: affichee)
                .stroke(AngularGradient(colors: [.cyan, .blue, Charte.or, .cyan], center: .center),
                        style: StrokeStyle(lineWidth: taille * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(compte) %")
                .font(.titre(taille * 0.24))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(compte)))
                .lettrageLogo()
        }
        .frame(width: taille, height: taille)
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.15).delay(0.15)) {
                affichee = completion.fraction
                compte = completion.pourcentage
            }
        }
    }
}

/// En-tête d'un groupe dans la collection : pictogramme, titre, complétion et barre.
struct EnteteGroupe: View {
    let groupe: GroupeCollection
    var taille: CGFloat = 22

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(groupe.picto) \(groupe.titre)")
                    .font(.titre(taille, relativeTo: .title3))
                    .lettrageLogo()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 6)
                if groupe.completion.complete {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Charte.or)
                }
                Text(groupe.completion.texte)
                    .font(.caption.bold())
                    .monospacedDigit()
                    .foregroundStyle(groupe.completion.complete ? Charte.or : .secondary)
            }
            BarreCompletion(completion: groupe.completion, hauteur: 4)
        }
    }
}

/// Bandeau sous le choix de l'affichage : complétion totale, qui ouvre l'album.
struct BandeauAlbum: View {
    let completion: Completion
    let ouvrir: () -> Void

    var body: some View {
        Button(action: ouvrir) {
            HStack(spacing: 10) {
                Image(systemName: "books.vertical.fill").foregroundStyle(Charte.or)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Album · \(completion.possedes) sur \(completion.total) combattants")
                        .font(.nom(13, relativeTo: .footnote))
                        .foregroundStyle(Charte.ivoire)
                    BarreCompletion(completion: completion, hauteur: 4)
                }
                Text("\(completion.pourcentage) %")
                    .font(.titre(16))
                    .monospacedDigit()
                    .foregroundStyle(Charte.or)
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Ouvre l'album de complétion")
    }
}

/// Voile d'une carte que le joueur ne possède pas encore.
struct VoileNonPossede: ViewModifier {
    let possede: Bool
    /// Cadenas dans le coin (masqué sur les petites vignettes).
    var cadenas = true

    func body(content: Content) -> some View {
        content
            .saturation(possede ? 1 : 0)
            .brightness(possede ? 0 : -0.18)
            .overlay(alignment: .topLeading) {
                if !possede && cadenas {
                    Image(systemName: "lock.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Charte.ivoire)
                        .padding(6)
                        .background(Circle().fill(.black.opacity(0.6)))
                        .padding(6)
                        .accessibilityLabel("Non possédé")
                }
            }
    }
}

// MARK: - L'album

/// « Album » : complétion de la collection par domaine puis par famille, et par style de combat
/// (famille de styles puis style). Un groupe complet est marqué d'un sceau doré.
struct AlbumView: View {
    let possedes: Set<String>

    @Environment(\.dismiss) private var fermer
    @State private var onglet = 0
    @State private var ouverts: Set<String> = []
    /// Titre de famille complète porté dans le profil.
    @AppStorage("titrePorte") private var titrePorte = ""

    private var catalogue: [ModeleCombattant] { Catalogue.prototype }

    private var total: Completion { Completion(catalogue, possedes: possedes) }

    /// Clés dans l'ordre du catalogue.
    private func cles(_ modeles: [ModeleCombattant], _ cle: (ModeleCombattant) -> String) -> [String] {
        var vus: [String] = []
        for modele in modeles where !vus.contains(cle(modele)) { vus.append(cle(modele)) }
        return vus
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    resume
                    recompenses
                    Picker("Album", selection: $onglet.animation(.snappy)) {
                        Text("Domaines").tag(0)
                        Text("Styles").tag(1)
                    }
                    .pickerStyle(.segmented)
                    VStack(spacing: 10) {
                        if onglet == 0 { domaines } else { styles }
                    }
                    .transition(.opacity)
                }
                .padding()
            }
            .background(Charte.marine.ignoresSafeArea())
            .navigationTitle("Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { fermer() }
                }
            }
            .sensoryFeedback(.selection, trigger: onglet)
        }
    }

    private var resume: some View {
        let domainesComplets = cles(catalogue) { $0.specialite.domaine }
            .filter { d in Completion(catalogue.filter { $0.specialite.domaine == d }, possedes: possedes).complete }.count
        let famillesTotal = cles(catalogue) { $0.specialite.famille }
        let famillesCompletes = famillesTotal
            .filter { f in Completion(catalogue.filter { $0.specialite.famille == f }, possedes: possedes).complete }.count
        return HStack(spacing: 18) {
            AnneauCompletion(completion: total)
            VStack(alignment: .leading, spacing: 6) {
                Text("\(total.possedes) sur \(total.total)")
                    .font(.titre(24, relativeTo: .title2))
                    .lettrageLogo()
                Text("combattants jouables possédés")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Label("\(famillesCompletes) famille\(famillesCompletes > 1 ? "s" : "") complète\(famillesCompletes > 1 ? "s" : "") sur \(famillesTotal.count)",
                      systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Charte.or)
                Label("\(domainesComplets) domaine\(domainesComplets > 1 ? "s" : "") complet\(domainesComplets > 1 ? "s" : "")",
                      systemImage: "crown.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Charte.or)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }

    // MARK: Récompenses

    @ViewBuilder
    private var recompenses: some View {
        let familles = Recompenses.famillesCompletes(possedes)
        let legendaires = Legendaires.liste.filter { possedes.contains($0.id) }
        VStack(alignment: .leading, spacing: 10) {
            Label("Récompenses", systemImage: "gift.fill")
                .font(.titre(18, relativeTo: .headline))
                .foregroundStyle(Charte.or)
            Text("Famille complète : un titre et +\(Recompenses.bonusPVFamille) PV pour ses combattants. Domaine complet : son Légendaire exclusif. Style complet : une tenue alternative.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if familles.isEmpty && legendaires.isEmpty {
                Text("Aucune récompense pour l'instant : complète une famille pour gagner ton premier titre.")
                    .font(.caption)
                    .foregroundStyle(Charte.ivoire.opacity(0.8))
            }
            if !familles.isEmpty {
                Text("Titres (touche pour l'afficher dans ton profil)")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(familles, id: \.famille) { f in
                            let titre = Recompenses.titre(famille: f.famille)
                            let porte = titrePorte == titre
                            Button {
                                withAnimation(.snappy) { titrePorte = porte ? "" : titre }
                            } label: {
                                Text("\(Pictos.famille(f.famille, domaine: f.domaine)) \(titre)")
                                    .font(.nom(12, relativeTo: .caption))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .foregroundStyle(porte ? Charte.marine : Charte.ivoire)
                                    .background(porte ? Charte.or : Color.white.opacity(0.08), in: Capsule())
                                    .overlay(Capsule().stroke(Charte.or.opacity(0.6), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: titrePorte)
            }
            if !legendaires.isEmpty {
                HStack(spacing: 10) {
                    ForEach(legendaires) { m in
                        VStack(spacing: 4) {
                            Avatar(modele: m, taille: 44)
                            Text(m.nom).font(.caption2).foregroundStyle(Charte.or).lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.06)))
    }

    // MARK: Domaines → familles

    private var domaines: some View {
        ForEach(cles(catalogue) { $0.specialite.domaine }, id: \.self) { domaine in
            let modeles = catalogue.filter { $0.specialite.domaine == domaine }
            BlocAlbum(cle: "d-" + domaine,
                      picto: Pictos.domaine(domaine),
                      titre: domaine,
                      completion: Completion(modeles, possedes: possedes),
                      ouverts: $ouverts) {
                if let legendaire = Legendaires.duDomaine(domaine) {
                    LigneRecompense(modele: legendaire, obtenu: possedes.contains(legendaire.id),
                                    texte: "Légendaire exclusif du domaine complet")
                }
                ForEach(cles(modeles) { $0.specialite.famille }, id: \.self) { famille in
                    let membres = modeles.filter { $0.specialite.famille == famille }
                    let completion = Completion(membres, possedes: possedes)
                    LigneAlbum(picto: Pictos.famille(famille, domaine: domaine), titre: famille,
                               completion: completion,
                               membres: membres, possedes: possedes,
                               recompense: "Titre « \(Recompenses.titre(famille: famille)) » et +\(Recompenses.bonusPVFamille) PV")
                }
            }
        }
    }

    // MARK: Familles de styles → styles

    private var styles: some View {
        ForEach(cles(catalogue) { $0.familleStyle.rawValue }, id: \.self) { nom in
            let modeles = catalogue.filter { $0.familleStyle.rawValue == nom }
            if let famille = modeles.first?.familleStyle {
                BlocAlbum(cle: "s-" + famille.rawValue,
                          picto: famille.picto,
                          titre: famille.rawValue,
                          completion: Completion(modeles, possedes: possedes),
                          ouverts: $ouverts) {
                    ForEach(cles(modeles) { $0.style }, id: \.self) { style in
                        let membres = modeles.filter { $0.style == style }
                        LigneAlbum(picto: Pictos.style(style, famille: famille), titre: style,
                                   completion: Completion(membres, possedes: possedes),
                                   membres: membres, possedes: possedes,
                                   recompense: membres.contains { Tenues.existe(pour: $0.id) }
                                       ? "Tenue alternative pour \(membres.filter { Tenues.existe(pour: $0.id) }.map(\.nom).joined(separator: ", "))"
                                       : nil)
                    }
                }
            }
        }
    }
}

/// Un domaine (ou une famille de styles) de l'album, qui se déplie sur ses familles (ou ses styles).
private struct BlocAlbum<Contenu: View>: View {
    let cle: String
    let picto: String
    let titre: String
    let completion: Completion
    @Binding var ouverts: Set<String>
    @ViewBuilder let contenu: () -> Contenu

    private var ouvert: Bool { ouverts.contains(cle) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(duration: 0.4)) {
                    if ouvert { ouverts.remove(cle) } else { ouverts.insert(cle) }
                }
            } label: {
                HStack(spacing: 10) {
                    Text(picto).font(.title2)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(titre)
                                .font(.titre(18, relativeTo: .headline))
                                .foregroundStyle(Charte.ivoire)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer(minLength: 4)
                            if completion.complete {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(Charte.or)
                                    .symbolEffect(.bounce, value: completion.complete)
                            }
                            Text(completion.texte)
                                .font(.caption.bold())
                                .monospacedDigit()
                                .foregroundStyle(completion.complete ? Charte.or : .secondary)
                        }
                        BarreCompletion(completion: completion)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(ouvert ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(ouvert ? "Replie" : "Déplie")
            if ouvert {
                VStack(spacing: 10) { contenu() }
                    .padding(.leading, 38)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(completion.complete ? 0.09 : 0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(completion.complete ? Charte.or.opacity(0.7) : Color.blue.opacity(0.3), lineWidth: 1))
    }
}

/// Une famille (ou un style) : complétion et vignettes des combattants, grisées s'ils ne sont pas possédés.
private struct LigneAlbum: View {
    let picto: String
    let titre: String
    let completion: Completion
    let membres: [ModeleCombattant]
    let possedes: Set<String>
    /// Ce que rapporte la complétion du groupe, nil s'il n'y a rien.
    var recompense: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(picto) \(titre)")
                    .font(.nom(14, relativeTo: .subheadline))
                    .foregroundStyle(Charte.ivoire)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if completion.complete {
                    Image(systemName: "checkmark.seal.fill").font(.caption).foregroundStyle(Charte.or)
                }
                Text("\(completion.possedes)/\(completion.total)")
                    .font(.caption2.bold())
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            BarreCompletion(completion: completion, hauteur: 4)
            if let recompense {
                Label(recompense, systemImage: completion.complete ? "gift.fill" : "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(completion.complete ? Charte.or : Color.secondary)
                    .lineLimit(2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(membres) { modele in
                        Avatar(modele: modele, taille: 34)
                            .modifier(VoileNonPossede(possede: possedes.contains(modele.id), cadenas: false))
                            .accessibilityLabel(modele.nom)
                    }
                }
            }
        }
    }
}

/// La récompense d'un domaine : son Légendaire, grisé tant que le domaine n'est pas complet.
private struct LigneRecompense: View {
    let modele: ModeleCombattant
    let obtenu: Bool
    let texte: String

    var body: some View {
        HStack(spacing: 10) {
            Avatar(modele: modele, taille: 40)
                .modifier(VoileNonPossede(possede: obtenu, cadenas: true))
                .shadow(color: obtenu ? Charte.or : .clear, radius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("👑 \(modele.nom)")
                    .font(.nom(14, relativeTo: .subheadline))
                    .foregroundStyle(obtenu ? Charte.or : Charte.ivoire)
                Text(obtenu ? "Obtenu · \(texte.lowercased())" : texte)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Charte.or.opacity(obtenu ? 0.15 : 0.05)))
    }
}
