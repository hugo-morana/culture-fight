import SwiftUI

// MARK: - Mode « Liste »

/// Mode « Liste » : une ligne par combattant, groupée par domaine, avec ses stats en bref.
struct ListeCollection: View {
    let zoom: Namespace.ID
    let ouvrir: (ModeleCombattant) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8, pinnedViews: [.sectionHeaders]) {
                ForEach(CollectionView.domaines, id: \.self) { domaine in
                    let modeles = Catalogue.prototype.filter { $0.specialite.domaine == domaine }
                    Section {
                        ForEach(modeles) { modele in
                            Button { ouvrir(modele) } label: {
                                LigneCollection(modele: modele)
                            }
                            .buttonStyle(.plain)
                            .modifier(SourceZoom(id: modele.id, espace: zoom))
                        }
                    } header: {
                        Text("\(Pictos.domaine(domaine)) \(domaine) · \(modeles.count)")
                            .font(.titre(18, relativeTo: .headline))
                            .lettrageLogo()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .background(.bar)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

/// Une ligne de la liste : vignette, nom, spécialité, rareté et stats.
struct LigneCollection: View {
    let modele: ModeleCombattant

    private static let fond = Color(red: 0.05, green: 0.08, blue: 0.2)

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: 56, height: 56)
                .overlay(alignment: .top) { IllustrationCombattant(modele: modele, taille: 20) }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(modele.specialite.couleur.opacity(0.9), lineWidth: 1.5))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(modele.nom)
                        .font(.nom(16))
                        .foregroundStyle(Charte.ivoire)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(modele.rarete.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(modele.specialite.couleur.opacity(0.35)))
                }
                Text(modele.sousTitre)
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 10) {
                    stat("heart.fill", modele.pvMax, .green)
                    stat("bolt.fill", modele.attaque, .orange)
                    stat("shield.fill", modele.defense, .cyan)
                    Text(modele.familleStyle.picto)
                    Spacer(minLength: 0)
                }
                .font(.caption2.bold())
            }
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Self.fond))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.35), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Ouvre la fiche")
    }

    private func stat(_ icone: String, _ valeur: Int, _ couleur: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icone).foregroundStyle(couleur)
            Text("\(valeur)").monospacedDigit()
        }
    }
}

// MARK: - Mode « Paquet »

/// Mode « Paquet » : les cartes empilées en paquet. On effeuille la carte du dessus d'un geste
/// du doigt : elle s'envole puis repasse sous le paquet, et les cartes du dessous s'ouvrent en éventail
/// pendant le geste. Toucher la carte du dessus la retourne ; la réglette en bas feuillette vite.
struct PaquetCollection: View {
    let zoom: Namespace.ID
    let ouvrir: (ModeleCombattant) -> Void

    /// Domaine filtré ; nil = tous les combattants.
    @State private var domaine: String?
    /// Position de la carte du dessus dans `cartes`. Croît sans fin : on la ramène dans le paquet par modulo.
    @State private var haut = 0
    @State private var glisse: CGSize = .zero
    @State private var envol: CGSize?
    @State private var retournee = false

    /// Cartes dessinées sous la carte du dessus.
    private static let epaisseur = 5

    private var cartes: [ModeleCombattant] {
        guard let domaine else { return Catalogue.prototype }
        return Catalogue.prototype.filter { $0.specialite.domaine == domaine }
    }

    private func position(_ i: Int) -> Int {
        let n = cartes.count
        return n == 0 ? 0 : ((i % n) + n) % n
    }

    /// 0 au repos, 1 quand la carte du dessus est assez loin pour partir.
    private var tension: Double {
        let d = envol ?? glisse
        return min(1, Double(hypot(d.width, d.height)) / 140)
    }

    var body: some View {
        VStack(spacing: 14) {
            filtres
            GeometryReader { geo in
                let largeur = min(geo.size.width * 0.74, geo.size.height / 1.5, 340)
                let taille = CGSize(width: largeur, height: largeur * 1.42)
                ZStack {
                    ForEach(visibles) { element in
                        carte(element.modele, rang: element.rang, taille: taille)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            commandes
        }
        .padding(.vertical)
        .sensoryFeedback(.impact(weight: .light), trigger: haut)
        .sensoryFeedback(.selection, trigger: retournee)
        .onChange(of: domaine) { _, _ in
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                haut = 0
                retournee = false
            }
        }
    }

    /// Une carte du paquet à son rang (0 = dessus). Identifiée par le combattant,
    /// pour qu'une carte glisse d'un rang à l'autre au lieu d'être redessinée.
    private struct CartePaquet: Identifiable {
        let rang: Int
        let modele: ModeleCombattant
        var id: String { modele.id }
    }

    /// Les cartes à dessiner, du dessus (rang 0) vers le dessous.
    private var visibles: [CartePaquet] {
        let n = cartes.count
        guard n > 0 else { return [] }
        return (0..<min(n, Self.epaisseur + 1)).map { rang in
            CartePaquet(rang: rang, modele: cartes[position(haut + rang)])
        }
    }

    @ViewBuilder
    private func carte(_ modele: ModeleCombattant, rang: Int, taille: CGSize) -> some View {
        let dessus = rang == 0
        let r = Double(rang)
        // Sous la carte du dessus : un paquet légèrement décalé, qui s'ouvre en éventail pendant le geste.
        let angleRepos = rang.isMultiple(of: 2) ? r * 1.2 : -r * 1.4
        let eventail = (r * 7 - 3) * tension
        let decalage = dessus ? (envol ?? glisse) : CGSize(width: r * 2 * tension * 6, height: r * 7 * (1 - tension * 0.4))
        let rotation = dessus ? Double((envol ?? glisse).width) / 14 : angleRepos + eventail
        let echelle = dessus ? 1 : 1 - r * 0.035 + 0.025 * tension

        CarteAnimee(progression: dessus && retournee ? 1 : 0, modele: modele) { ouvrir(modele) }
            .frame(width: taille.width, height: taille.height)
            .modifier(SourceZoom(id: modele.id, espace: zoom))
            .brightness(dessus ? 0 : -0.06 * r)
            .shadow(color: .black.opacity(dessus ? 0.5 : 0.25), radius: dessus ? 14 : 4, y: dessus ? 8 : 2)
            .scaleEffect(echelle)
            .rotationEffect(.degrees(rotation), anchor: dessus ? .center : .bottom)
            .offset(decalage)
            .zIndex(Double(-rang))
            .transition(.asymmetric(insertion: .opacity, removal: .identity))
            .allowsHitTesting(dessus)
            .onTapGesture {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) { retournee.toggle() }
            }
            .gesture(effeuillage(taille: taille))
            .accessibilityAddTraits(dessus ? .isButton : [])
            .accessibilityHidden(!dessus)
            .accessibilityAction(named: "Carte suivante") { suivante(sens: 1) }
            .accessibilityAction(named: "Carte précédente") { precedente() }
    }

    /// Glisser la carte du dessus ; au-delà d'un seuil (ou d'un geste vif), elle s'envole.
    private func effeuillage(taille: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { geste in
                guard envol == nil else { return }
                glisse = geste.translation
            }
            .onEnded { geste in
                guard envol == nil else { return }
                let vers = geste.predictedEndTranslation
                let assez = abs(geste.translation.width) > taille.width * 0.35
                    || abs(vers.width) > taille.width * 0.9
                    || abs(geste.translation.height) > taille.height * 0.35
                if assez && cartes.count > 1 {
                    let dx = vers.width == 0 ? 1 : vers.width
                    let facteur = 900 / max(1, hypot(dx, vers.height))
                    envoler(vers: CGSize(width: dx * facteur, height: vers.height * facteur))
                } else {
                    withAnimation(.spring(duration: 0.45, bounce: 0.4)) { glisse = .zero }
                }
            }
    }

    /// La carte du dessus part dans la direction du geste, puis repasse sous le paquet.
    private func envoler(vers destination: CGSize) {
        withAnimation(.easeIn(duration: 0.22)) {
            envol = destination
        } completion: {
            // Une seule transaction : l'éventail se referme, les cartes montent d'un rang
            // et la carte envolée revient se glisser sous le paquet (ou disparaît s'il est épais).
            withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
                retournee = false
                envol = nil
                glisse = .zero
                haut += 1
            }
        }
    }

    private func suivante(sens: Int) {
        guard cartes.count > 1, envol == nil else { return }
        envoler(vers: CGSize(width: -900 * CGFloat(sens), height: -120))
    }

    private func precedente() {
        guard cartes.count > 1, envol == nil else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
            retournee = false
            haut -= 1
        }
    }

    // MARK: Filtres et commandes

    private var filtres: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                puce("Tous", choisi: domaine == nil) { domaine = nil }
                ForEach(CollectionView.domaines, id: \.self) { d in
                    puce("\(Pictos.domaine(d)) \(d)", choisi: domaine == d) { domaine = d }
                }
            }
            .padding(.horizontal)
        }
    }

    private func puce(_ titre: String, choisi: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titre)
                .font(.nom(13, relativeTo: .footnote))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(choisi ? Color.blue.opacity(0.55) : Color.white.opacity(0.08)))
                .overlay(Capsule().stroke(choisi ? Charte.or : Color.clear, lineWidth: 1))
                .foregroundStyle(Charte.ivoire)
        }
        .buttonStyle(.plain)
    }

    private var commandes: some View {
        let n = cartes.count
        return VStack(spacing: 6) {
            HStack(spacing: 24) {
                Button(action: precedente) {
                    Image(systemName: "arrow.uturn.backward.circle.fill").font(.title)
                }
                .accessibilityLabel("Carte précédente")
                Text("\(n == 0 ? 0 : position(haut) + 1) / \(n)")
                    .font(.titre(20, relativeTo: .title3))
                    .monospacedDigit()
                    .lettrageLogo()
                    .contentTransition(.numericText())
                    .frame(minWidth: 90)
                Button { suivante(sens: 1) } label: {
                    Image(systemName: "arrow.forward.circle.fill").font(.title)
                }
                .accessibilityLabel("Carte suivante")
            }
            .tint(Charte.or)
            .disabled(n < 2)
            if n > 2 {
                Slider(value: Binding(
                    get: { Double(position(haut)) },
                    set: { nouvelle in
                        let cible = Int(nouvelle.rounded())
                        guard cible != position(haut) else { return }
                        retournee = false
                        withAnimation(.snappy(duration: 0.18)) { haut = cible }
                    }), in: 0...Double(n - 1), step: 1)
                    .tint(Charte.or)
                    .padding(.horizontal, 40)
                    .accessibilityLabel("Feuilleter le paquet")
            }
            Text("Glisse la carte pour l'effeuiller · touche-la pour la retourner")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
