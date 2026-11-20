import SwiftUI
import SwiftData

/// Façons d'afficher « Ma collection ». Le choix est mémorisé d'une visite à l'autre.
enum ModeCollection: String, CaseIterable, Identifiable {
    case liste, tuiles, paquet

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .liste: "Liste"
        case .tuiles: "Tuiles"
        case .paquet: "Paquet"
        }
    }

    var icone: String {
        switch self {
        case .liste: "list.bullet"
        case .tuiles: "square.grid.2x2"
        case .paquet: "rectangle.stack"
        }
    }
}

/// Critère de regroupement de « Ma collection ». Le choix est mémorisé d'une visite à l'autre.
enum GroupementCollection: String, CaseIterable, Identifiable {
    case domaine, famille, style

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .domaine: "Domaine"
        case .famille: "Famille"
        case .style: "Style de combat"
        }
    }

    var icone: String {
        switch self {
        case .domaine: "globe.europe.africa"
        case .famille: "books.vertical"
        case .style: "figure.martial.arts"
        }
    }
}

/// Un groupe de combattants affiché sous un même titre.
struct GroupeCollection: Identifiable {
    let titre: String
    let picto: String
    let modeles: [ModeleCombattant]
    /// Complétion du groupe entier (sans tenir compte de la recherche ni du filtre).
    var completion = Completion()
    var id: String { titre }
}

extension ModeleCombattant {
    /// Vrai si la recherche apparaît dans le nom, la spécialité, la famille, le domaine ou le style
    /// (sans tenir compte des majuscules ni des accents).
    func correspond(a recherche: String) -> Bool {
        let champs = [nom, specialite.nom, specialite.famille, specialite.domaine, style, familleStyle.rawValue, rarete.rawValue]
        let mots = recherche.split(separator: " ").map(String.init)
        return mots.allSatisfy { mot in champs.contains { $0.localizedStandardContains(mot) } }
    }
}

/// « Ma collection » : tous les combattants, en liste, en tuiles ou en paquet de cartes à effeuiller,
/// groupés par domaine, famille ou style de combat, avec une recherche.
struct CollectionView: View {
    let retour: () -> Void

    @AppStorage("collection.mode") private var mode: ModeCollection = .tuiles
    @AppStorage("collection.groupement") private var groupement: GroupementCollection = .domaine
    @AppStorage("collection.possession") private var filtre: FiltrePossession = .tous
    @State private var recherche = ""
    @State private var detail: ModeleCombattant?
    @State private var albumOuvert = false
    @Namespace private var zoom
    @Query private var joueurs: [Joueur]

    /// Identifiants des combattants de la réserve du joueur.
    private var possedes: Set<String> { Set(joueurs.first?.reserve.map(\.modeleID) ?? []) }

    private static func cle(_ modele: ModeleCombattant, _ groupement: GroupementCollection) -> (cle: String, picto: String) {
        switch groupement {
        case .domaine:
            return (modele.specialite.domaine, Pictos.domaine(modele.specialite.domaine))
        case .famille:
            return (modele.specialite.famille, Pictos.famille(modele.specialite.famille, domaine: modele.specialite.domaine))
        case .style:
            return (modele.familleStyle.rawValue, modele.familleStyle.picto)
        }
    }

    /// Les combattants retenus par la recherche et le filtre, groupés selon `groupement`,
    /// dans l'ordre du catalogue ; chaque groupe porte la complétion de tous ses combattants.
    static func groupes(_ groupement: GroupementCollection, recherche: String,
                        filtre: FiltrePossession = .tous, possedes: Set<String> = []) -> [GroupeCollection] {
        let texte = recherche.trimmingCharacters(in: .whitespaces)
        var ordre: [String] = []
        var parCle: [String: [ModeleCombattant]] = [:]
        var pictos: [String: String] = [:]
        var completions: [String: Completion] = [:]
        for modele in Catalogue.prototype {
            let (cle, picto) = Self.cle(modele, groupement)
            var completion = completions[cle, default: Completion()]
            completion.total += 1
            if possedes.contains(modele.id) { completion.possedes += 1 }
            completions[cle] = completion
            guard texte.isEmpty || modele.correspond(a: texte),
                  filtre.garde(modele, possedes: possedes) else { continue }
            if parCle[cle] == nil {
                ordre.append(cle)
                pictos[cle] = picto
            }
            parCle[cle, default: []].append(modele)
        }
        return ordre.map {
            GroupeCollection(titre: $0, picto: pictos[$0] ?? "", modeles: parCle[$0] ?? [],
                             completion: completions[$0] ?? Completion())
        }
    }

    private var groupes: [GroupeCollection] {
        Self.groupes(groupement, recherche: recherche, filtre: filtre, possedes: possedes)
    }

    var body: some View {
        NavigationStack {
            Group {
                let groupes = groupes
                if groupes.isEmpty {
                    if recherche.trimmingCharacters(in: .whitespaces).isEmpty {
                        ContentUnavailableView(filtre == .manquants ? "Collection complète !" : "Aucun combattant",
                                               systemImage: filtre == .manquants ? "checkmark.seal.fill" : "rectangle.stack",
                                               description: Text(filtre == .manquants
                                                                 ? "Tu possèdes tous les combattants jouables."
                                                                 : "Gagne des Pièces en combat pour en acheter à la boutique."))
                    } else {
                        ContentUnavailableView.search(text: recherche)
                    }
                } else {
                    switch mode {
                    case .liste:
                        ListeCollection(groupes: groupes, possedes: possedes, zoom: zoom) { detail = $0 }
                    case .tuiles:
                        TuilesCollection(groupes: groupes, possedes: possedes, zoom: zoom) { detail = $0 }
                    case .paquet:
                        PaquetCollection(groupes: groupes, possedes: possedes, zoom: zoom) { detail = $0 }
                    }
                }
            }
            .transition(.opacity)
            .animation(.snappy, value: groupement)
            .animation(.snappy, value: filtre)
            .searchable(text: $recherche, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Nom, spécialité, style…")
            .autocorrectionDisabled()
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Affichage", selection: $mode.animation(.snappy)) {
                    ForEach(ModeCollection.allCases) { choix in
                        Label(choix.titre, systemImage: choix.icone).tag(choix)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(.bar)
                .sensoryFeedback(.selection, trigger: mode)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                BandeauAlbum(completion: Completion(Catalogue.prototype, possedes: possedes)) { albumOuvert = true }
                    .background(.bar)
            }
            .navigationTitle("Ma collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Grouper par", selection: $groupement) {
                            ForEach(GroupementCollection.allCases) { choix in
                                Label(choix.titre, systemImage: choix.icone).tag(choix)
                            }
                        }
                        Picker("Afficher", selection: $filtre) {
                            ForEach(FiltrePossession.allCases) { choix in
                                Label(choix.titre, systemImage: choix.icone).tag(choix)
                            }
                        }
                    } label: {
                        Label("Grouper par \(groupement.titre.lowercased())", systemImage: "rectangle.3.group")
                    }
                    .sensoryFeedback(.selection, trigger: groupement)
                }
            }
            .sheet(isPresented: $albumOuvert) {
                AlbumView(possedes: possedes)
            }
            .sheet(item: $detail) { modele in
                FicheCombattantView(modele: modele)
                    .modifier(TransitionZoom(id: modele.id, espace: zoom))
            }
        }
    }
}

/// Mode « Tuiles » : les cartes en grille de deux colonnes, groupées par domaine ;
/// toucher une carte la retourne.
struct TuilesCollection: View {
    let groupes: [GroupeCollection]
    let possedes: Set<String>
    let zoom: Namespace.ID
    let ouvrir: (ModeleCombattant) -> Void

    @State private var retournes: Set<String> = []
    private let colonnes = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    private func retourner(_ id: String) {
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            if retournes.contains(id) { retournes.remove(id) } else { retournes.insert(id) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ForEach(groupes) { groupe in
                    EnteteGroupe(groupe: groupe)
                    LazyVGrid(columns: colonnes, spacing: 12) {
                        ForEach(groupe.modeles) { modele in
                            CarteAnimee(progression: retournes.contains(modele.id) ? 1 : 0,
                                        modele: modele) { ouvrir(modele) }
                                .modifier(VoileNonPossede(possede: possedes.contains(modele.id)))
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
                .overlay(alignment: .topLeading) {
                    PastillePicto(picto: modele.familleStyle.picto).padding(6)
                }
                .overlay(alignment: .topTrailing) {
                    PastillePicto(picto: modele.specialite.pictoDomaine).padding(6)
                }
            VStack(spacing: 2) {
                // Place réservée : le nom est dessiné par CarteAnimee pour pouvoir pivoter.
                Text(modele.nom)
                    .font(.nom(17))
                    .lineLimit(1)
                    .hidden()
                Text(modele.sousTitre)
                    .font(.nom(11, relativeTo: .caption2))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(modele.specialite.pictoDomaine) \(modele.specialite.domaine)")
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(modele.specialite.couleur)
                    .lineLimit(1)
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
            Text(modele.sousTitre)
                .font(.nom(14, relativeTo: .subheadline))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(modele.classement)
                .font(.nom(12, relativeTo: .caption))
                .foregroundStyle(modele.specialite.couleur)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            jauge("PV", "heart.fill", modele.pvMax, sur: 150, couleur: .green)
            jauge("Attaque", "bolt.fill", modele.attaque, sur: 80, couleur: .orange)
            jauge("Défense", "shield.fill", modele.defense, sur: 20, couleur: .cyan)
            Spacer(minLength: 0)
            Label("\(modele.type) · bonus \(modele.familleStyle.effetVitesse.nom)", systemImage: "hare.fill")
                .font(.nom(13, relativeTo: .footnote))
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
            .font(.nom(12, relativeTo: .caption))
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
                .font(.nom(11, relativeTo: .caption2))
                .foregroundStyle(modele.specialite.couleur)
            Text(modele.type)
                .font(.nom(11, relativeTo: .caption2))
                .foregroundStyle(Charte.or)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            ligne("heart.fill", "PV", modele.pvMax, sur: 150, couleur: .green)
            ligne("bolt.fill", "Att", modele.attaque, sur: 80, couleur: .orange)
            ligne("shield.fill", "Déf", modele.defense, sur: 20, couleur: .cyan)
            Label(modele.familleStyle.effetVitesse.nom, systemImage: "hare.fill")
                .font(.nom(11, relativeTo: .caption2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Button(action: ouvrir) {
                Label("Voir la fiche", systemImage: "arrow.up.left.and.arrow.down.right")
                    .font(.nom(12, relativeTo: .caption))
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
