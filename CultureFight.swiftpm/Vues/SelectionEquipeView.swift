import SwiftUI

/// Composition de l'équipe : 3 places ; toucher le « + » d'une place (ou une place prise, pour la changer)
/// ouvre la fenêtre de choix d'un combattant, avec recherche et filtres par domaine. Lancement en bas.
struct SelectionEquipeView: View {
    /// Les combattants de la réserve du joueur, parmi lesquels il compose son équipe.
    let reserve: [ModeleCombattant]
    /// Niveau de chaque combattant de la réserve (stade d'évolution).
    var niveaux: [String: Int] = [:]
    let retour: () -> Void
    let lancer: ([ModeleCombattant], IAAdverse.Niveau) -> Void

    @State private var choisis: [String] = []
    @State private var niveau: IAAdverse.Niveau = .moyen
    @State private var fiche: ModeleCombattant?
    /// Place pour laquelle la fenêtre de choix est ouverte.
    @State private var selecteur: PlaceAChoisir?
    @State private var depart = false
    @State private var flash: [String: Int] = [:]
    /// Dernière équipe lancée, identifiants séparés par des virgules.
    @AppStorage("derniereEquipe") private var derniereEquipe = ""

    private var equipe: [ModeleCombattant] {
        choisis.compactMap { id in reserve.first { $0.id == id } }
    }

    private var complete: Bool { choisis.count == Regles.tailleEquipe }

    var body: some View {
        NavigationStack {
            ZStack {
                FondAnime().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        places
                        consigne
                        resume
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Ton équipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Équipe aléatoire", systemImage: "dice") { aleatoire() }
                        if !derniereEquipe.isEmpty {
                            Button("Dernière équipe", systemImage: "clock.arrow.circlepath") { reprendre() }
                        }
                        if !choisis.isEmpty {
                            Button("Vider l'équipe", systemImage: "xmark.circle", role: .destructive) {
                                withAnimation(.spring(duration: 0.4)) { choisis = [] }
                            }
                        }
                    } label: {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { barreLancement }
            .sensoryFeedback(.selection, trigger: choisis)
            .onChange(of: choisis) { _, _ in ServiceSons.partage.jouer(.selection) }
            .sensoryFeedback(.success, trigger: complete) { _, nouveau in nouveau }
            .sheet(item: $fiche) { modele in FicheCombattantView(modele: modele) }
            .sheet(item: $selecteur) { place in
                SelecteurCombattant(reserve: reserve, niveaux: niveaux, equipe: choisis,
                                    remplace: place.index < equipe.count ? equipe[place.index] : nil) { modele in
                    choisir(modele, place: place.index)
                }
            }
        }
    }

    // MARK: Places

    private var places: some View {
        ZStack {
            if Equipe.synergie(equipe) != nil {
                Capsule()
                    .fill(Charte.or.opacity(0.9))
                    .frame(height: 4)
                    .padding(.horizontal, 40)
                    .shadow(color: Charte.or, radius: 8)
                    .phaseAnimator([0.6, 1.0]) { vue, o in vue.opacity(o) } animation: { _ in .easeInOut(duration: 0.9) }
                    .transition(.opacity)
            }
            HStack(spacing: 10) {
                ForEach(0..<Regles.tailleEquipe, id: \.self) { index in
                    place(index)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
        .scaleEffect(depart ? 0.8 : 1)
        .offset(y: depart ? -30 : 0)
        .opacity(depart ? 0 : 1)
        .animation(.spring(duration: 0.5, bounce: 0.3), value: equipe.map(\.id))
    }

    @ViewBuilder
    private func place(_ index: Int) -> some View {
        let modele = index < equipe.count ? equipe[index] : nil
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(modele == nil ? Charte.ivoire.opacity(0.3) : modele!.specialite.couleur,
                              style: StrokeStyle(lineWidth: modele == nil ? 1.5 : 2.5, dash: modele == nil ? [6, 5] : []))
                .background(RoundedRectangle(cornerRadius: 14).fill(Charte.marine.opacity(0.75)))
            if let modele {
                Button {
                    selecteur = PlaceAChoisir(index: index)
                } label: {
                    VStack(spacing: 4) {
                        Color.clear
                            .frame(height: 118)
                            .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 38) }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        Text(Stade(niveau: niveaux[modele.id] ?? 1).nom(de: modele.nom))
                            .font(.nom(12, relativeTo: .caption))
                            .foregroundStyle(Charte.ivoire)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("\(modele.familleStyle.picto) \(modele.specialite.pictoDomaine)")
                            .font(.caption2)
                    }
                    .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Change ce combattant")
                .contextMenu {
                    Button("Voir la fiche", systemImage: "info.circle") { fiche = modele }
                    Button("Retirer de l'équipe", systemImage: "xmark.circle", role: .destructive) { basculer(modele.id) }
                }
                .overlay(alignment: .topTrailing) {
                    Button { basculer(modele.id) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Charte.ivoire, Charte.marine.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 7, y: -7)
                    .accessibilityLabel("Retirer \(modele.nom)")
                }
                .keyframeAnimator(initialValue: 0.0, trigger: flash[modele.id, default: 0]) { vue, eclat in
                    vue.overlay(RoundedRectangle(cornerRadius: 14).fill(Charte.or.opacity(eclat)).allowsHitTesting(false))
                } keyframes: { _ in
                    KeyframeTrack {
                        LinearKeyframe(0.7, duration: 0.12)
                        LinearKeyframe(0, duration: 0.5)
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.3).combined(with: .offset(y: 220)).combined(with: .opacity),
                    removal: .scale(scale: 0.5).combined(with: .opacity)))
            } else {
                Button { selecteur = PlaceAChoisir(index: equipe.count) } label: {
                VStack(spacing: 6) {
                    if index == equipe.count {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundStyle(Charte.or)
                            .phaseAnimator([1.0, 1.25, 1.0, 1.12, 1.0]) { vue, echelle in
                                vue.scaleEffect(echelle)
                            } animation: { echelle in
                                echelle == 1.0 ? .easeIn(duration: 0.35) : .easeOut(duration: 0.14)
                            }
                    } else {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(Charte.ivoire.opacity(0.35))
                    }
                    Text(index == equipe.count ? "Choisir" : "Place libre")
                        .font(.caption2)
                        .foregroundStyle(index == equipe.count ? Charte.ivoire.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choisir un combattant")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 172)
    }

    // MARK: Consigne

    /// Consigne et compteur sous les places : le joueur sait quoi faire dès l'arrivée.
    private var consigne: some View {
        HStack(spacing: 8) {
            Text(complete ? "Équipe prête ! Lance le combat." : "Touche « + » pour choisir tes 3 combattants")
                .font(.subheadline)
                .foregroundStyle(complete ? Charte.or : Charte.ivoire.opacity(0.85))
                .contentTransition(.opacity)
            Spacer(minLength: 4)
            Text("\(choisis.count)/\(Regles.tailleEquipe)")
                .font(.nom(15, relativeTo: .subheadline).monospacedDigit())
                .foregroundStyle(complete ? Charte.marine : Charte.ivoire)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(complete ? Charte.or : Charte.marine.opacity(0.8), in: Capsule())
                .overlay(Capsule().stroke(Charte.or.opacity(0.6), lineWidth: 1))
                .contentTransition(.numericText(value: Double(choisis.count)))
        }
        .padding(.horizontal)
        .animation(.snappy, value: choisis.count)
    }

    // MARK: Résumé de l'équipe

    @ViewBuilder
    private var resume: some View {
        let familles = Dictionary(grouping: equipe, by: \.familleStyle)
        Group {
            if let synergie = Equipe.synergie(equipe) {
                // Le Contre des Arts martiaux n'est pas multiplié par la synergie (outils/simulation.py).
                Label(synergie.effetVitesse == .contre
                      ? "Synergie \(synergie.rawValue) : 3 combattants qui contrent (le Contre reste à son niveau)"
                      : "Synergie \(synergie.rawValue) : bonus de vitesse \(synergie.effetVitesse.nom) ×\(Regles.texteSynergie)",
                      systemImage: "sparkles")
                    .foregroundStyle(Charte.or)
                    .symbolEffect(.bounce, value: synergie.rawValue)
            } else if equipe.count == 2, let paire = familles.first(where: { $0.value.count == 2 })?.key {
                Label("Encore un combattant \(paire.rawValue) \(paire.picto) pour la synergie ×\(Regles.texteSynergie)", systemImage: "link")
                    .foregroundStyle(Charte.ivoire.opacity(0.85))
            } else if equipe.isEmpty {
                Label("Choisis \(Regles.tailleEquipe) combattants. Même famille de styles : bonus ×\(Regles.texteSynergie).",
                      systemImage: "hand.tap")
                    .foregroundStyle(.secondary)
            } else {
                Label("Domaines : \(Array(Set(equipe.map(\.specialite.pictoDomaine))).sorted().joined(separator: " ")) · effets : \(Array(Set(equipe.map(\.familleStyle.effetVitesse.nom))).sorted().joined(separator: ", "))",
                      systemImage: "square.grid.3x3")
                    .foregroundStyle(Charte.ivoire.opacity(0.85))
            }
        }
        .font(.nom(12, relativeTo: .caption))
        .lineLimit(2)
        .minimumScaleFactor(0.8)
        .padding(.horizontal)
        .contentTransition(.opacity)
        .animation(.snappy, value: equipe.map(\.id))
    }

    // MARK: Lancement

    private var barreLancement: some View {
        VStack(spacing: 8) {
            Picker("Niveau de l'IA", selection: $niveau) {
                ForEach(IAAdverse.Niveau.allCases) { n in
                    Text(n.rawValue).tag(n)
                }
            }
            .pickerStyle(.segmented)
            Text("Enjeu : victoire +\(NiveauCompte.xpVictoire(contre: niveau)) Savoir · défaite −\(abs(NiveauCompte.xpDefaite(contre: niveau))) Savoir")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Button {
                partir()
            } label: {
                Label(complete ? "Combattre" : "Choisis encore \(Regles.tailleEquipe - choisis.count)",
                      systemImage: complete ? "flame.fill" : "person.badge.plus")
                    .font(.titre(19, relativeTo: .headline))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(complete ? .orange : .gray)
            .disabled(!complete)
            .phaseAnimator(complete ? [1.0, 1.04] : [1.0]) { vue, echelle in
                vue.scaleEffect(echelle).shadow(color: .orange.opacity(complete ? 0.6 : 0), radius: echelle > 1 ? 14 : 4)
            } animation: { _ in .easeInOut(duration: 0.7) }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: Actions

    private func basculer(_ id: String) {
        Clavier.fermer()
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
            if let i = choisis.firstIndex(of: id) {
                choisis.remove(at: i)
            } else if choisis.count < Regles.tailleEquipe {
                choisis.append(id)
                flash[id, default: 0] += 1
            }
        }
    }

    /// Place le combattant choisi : à la place visée (échange s'il est déjà ailleurs dans l'équipe), sinon à la suite.
    private func choisir(_ modele: ModeleCombattant, place index: Int) {
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
            if let deja = choisis.firstIndex(of: modele.id) {
                if index < choisis.count { choisis.swapAt(deja, index) }
            } else if index < choisis.count {
                choisis[index] = modele.id
                flash[modele.id, default: 0] += 1
            } else if choisis.count < Regles.tailleEquipe {
                choisis.append(modele.id)
                flash[modele.id, default: 0] += 1
            }
        }
    }

    private func aleatoire() {
        let tirage = Array(reserve.shuffled().prefix(Regles.tailleEquipe)).map(\.id)
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) {
            choisis = []
        }
        for (i, id) in tirage.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + 0.18 * Double(i)) { basculer(id) }
        }
    }

    private func reprendre() {
        let ids = derniereEquipe.split(separator: ",").map(String.init).filter { id in reserve.contains { $0.id == id } }
        withAnimation(.spring(duration: 0.5, bounce: 0.35)) { choisis = [] }
        for (i, id) in ids.prefix(Regles.tailleEquipe).enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + 0.18 * Double(i)) { basculer(id) }
        }
    }

    private func partir() {
        guard complete else { return }
        derniereEquipe = choisis.joined(separator: ",")
        let equipeLancee = equipe
        let niveauLance = niveau
        withAnimation(.spring(duration: 0.45, bounce: 0.2)) { depart = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            lancer(equipeLancee, niveauLance)
        }
    }
}

/// La place dont on choisit le combattant.
struct PlaceAChoisir: Identifiable {
    let index: Int
    var id: Int { index }
}

/// Fenêtre de choix d'un combattant pour une place de l'équipe : recherche (comme la collection),
/// filtres par domaine, grille de la réserve. Toucher une carte la place et ferme la fenêtre.
struct SelecteurCombattant: View {
    let reserve: [ModeleCombattant]
    let niveaux: [String: Int]
    /// Identifiants déjà dans l'équipe.
    let equipe: [String]
    /// Combattant de la place qu'on change, nil pour une place vide.
    let remplace: ModeleCombattant?
    let choisir: (ModeleCombattant) -> Void

    @Environment(\.dismiss) private var fermer
    @State private var filtre: String?
    @State private var recherche = ""
    @State private var fiche: ModeleCombattant?

    private let colonnes = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var domaines: [String] {
        var vus: [String] = []
        for modele in reserve where !vus.contains(modele.specialite.domaine) { vus.append(modele.specialite.domaine) }
        return vus
    }

    private var visibles: [ModeleCombattant] {
        let texte = recherche.trimmingCharacters(in: .whitespaces)
        return reserve.filter { m in
            (filtre == nil || m.specialite.domaine == filtre) && (texte.isEmpty || m.correspond(a: texte))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FondAnime().ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 10) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                PastilleDomaine(domaine: nil, actif: filtre == nil) {
                                    withAnimation(.spring(duration: 0.35)) { filtre = nil }
                                }
                                ForEach(domaines, id: \.self) { d in
                                    PastilleDomaine(domaine: d, actif: filtre == d) {
                                        withAnimation(.spring(duration: 0.35)) { filtre = d }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 2)
                        }
                        if visibles.isEmpty {
                            ContentUnavailableView.search(text: recherche)
                        }
                        LazyVGrid(columns: colonnes, spacing: 10) {
                            ForEach(visibles) { modele in
                                CarteChoix(modele: modele,
                                           niveau: niveaux[modele.id] ?? 1,
                                           choisi: equipe.contains(modele.id),
                                           toucher: {
                                               choisir(modele)
                                               fermer()
                                           },
                                           voirFiche: { fiche = modele })
                                    .scrollTransition(.interactive, axis: .vertical) { carte, phase in
                                        carte
                                            .scaleEffect(phase.isIdentity ? 1 : 0.9)
                                            .opacity(phase.isIdentity ? 1 : 0.6)
                                    }
                            }
                        }
                        .padding(.horizontal)
                        .animation(.spring(duration: 0.45, bounce: 0.25), value: filtre)
                        .animation(.spring(duration: 0.45, bounce: 0.25), value: recherche)
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle(remplace.map { "Remplacer \($0.nom)" } ?? "Choisis un combattant")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $recherche, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Nom, spécialité ou style")
            .onSubmit(of: .search) { Clavier.fermer() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { fermer() }
                }
            }
            .sheet(item: $fiche) { modele in FicheCombattantView(modele: modele) }
        }
        .presentationDragIndicator(.visible)
    }
}

/// Carte d'un combattant dans la grille de composition.
struct CarteChoix: View {
    let modele: ModeleCombattant
    var niveau: Int = 1
    let choisi: Bool
    let toucher: () -> Void
    let voirFiche: () -> Void

    var body: some View {
        Button(action: toucher) {
            VStack(alignment: .leading, spacing: 4) {
                Color.clear
                    .frame(height: 110)
                    .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 34) }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(alignment: .topLeading) {
                        PastillePicto(picto: modele.familleStyle.picto, taille: 24,
                                      image: IdentiteDomaine.imageStyle(modele.style)).padding(5)
                    }
                    .overlay(alignment: .bottomLeading) {
                        BadgeStade(stade: Stade(niveau: niveau)).padding(5)
                    }
                Text(Stade(niveau: niveau).nom(de: modele.nom))
                    .font(.nom(15, relativeTo: .subheadline))
                    .foregroundStyle(Charte.ivoire)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(modele.sousTitre)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let accroche = modele.accroche {
                    Text(accroche)
                        .font(.system(.caption2, design: .serif).italic())
                        .foregroundStyle(Charte.or.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Label(modele.familleStyle.effetVitesse.nom, systemImage: "hare.fill")
                    .font(.nom(11, relativeTo: .caption2))
                    .foregroundStyle(modele.specialite.couleur)
            }
            .padding(8)
            .background(Charte.marine.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(choisi ? Charte.or : modele.specialite.couleur.opacity(0.5), lineWidth: choisi ? 2.5 : 1))
            .overlay(alignment: .topTrailing) {
                ZStack {
                    if choisi {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Charte.marine, Charte.or)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(action: voirFiche) {
                            Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Charte.ivoire.opacity(0.85), Charte.marine.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
            }
            .opacity(choisi ? 0.55 : 1)
            .scaleEffect(choisi ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.4, bounce: 0.4), value: choisi)
        .contextMenu {
            Button("Voir la fiche", systemImage: "doc.text.magnifyingglass", action: voirFiche)
            Button(choisi ? "Retirer de l'équipe" : "Ajouter à l'équipe",
                   systemImage: choisi ? "minus.circle" : "plus.circle", action: toucher)
        }
    }
}
