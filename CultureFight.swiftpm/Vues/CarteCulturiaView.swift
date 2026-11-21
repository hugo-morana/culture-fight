import SwiftUI
import SwiftData

/// Carte de Culturia (tâche 55) : les 10 pays autour de l'Agora, dessinés en SwiftUI, et chaque
/// combattant à son lieu d'origine (`monde.json` et `histoires.json`, positions écrites par
/// `outils/placer_carte.py` et contrôlées par `outils/verifier.py`). Toucher un combattant ouvre sa fiche ;
/// un combattant pas encore obtenu apparaît en silhouette. Toucher un pays ou un lieu affiche sa description.
struct CarteCulturiaView: View {
    let retour: () -> Void

    /// Côté de la carte à l'échelle 1, en points.
    static let cote: CGFloat = 2400

    @Query private var joueurs: [Joueur]
    @State private var echelle: CGFloat = 0.3
    @State private var echelleDepart: CGFloat?
    @State private var detail: ModeleCombattant?
    @State private var selection: SelectionCarte?
    @State private var apparu = false

    private var possedes: Set<String> { Set(joueurs.first?.reserve.map(\.modeleID) ?? []) }
    private var monde: Monde? { Univers.monde }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let ajustee = min(geo.size.width, geo.size.height) / Self.cote
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    if let monde {
                        PlanCarte(monde: monde, possedes: possedes, echelle: echelle,
                                  apparu: apparu, selection: $selection) { detail = $0 }
                            .frame(width: Self.cote, height: Self.cote)
                            .scaleEffect(echelle, anchor: .topLeading)
                            .frame(width: Self.cote * echelle, height: Self.cote * echelle, alignment: .topLeading)
                    }
                }
                .defaultScrollAnchor(.center)
                .background(Self.mer.ignoresSafeArea())
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { valeur in
                            let depart = echelleDepart ?? echelle
                            echelleDepart = depart
                            echelle = Self.borner(depart * valeur.magnification, ajustee: ajustee)
                        }
                        .onEnded { _ in echelleDepart = nil }
                )
                .onAppear {
                    echelle = ajustee
                    withAnimation(.easeOut(duration: 1.2)) { apparu = true }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Retour", action: retour)
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button { zoomer(1 / 1.6, ajustee: ajustee) } label: {
                            Label("Dézoomer", systemImage: "minus.magnifyingglass")
                        }
                        Button { zoomer(1.6, ajustee: ajustee) } label: {
                            Label("Zoomer", systemImage: "plus.magnifyingglass")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let selection, let monde {
                    PanneauCarte(selection: selection, monde: monde, possedes: possedes,
                                 ouvrir: { detail = $0 }, fermer: { self.selection = nil })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: selection)
            .navigationTitle(monde?.nom ?? "Culturia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $detail) { FicheCombattantView(modele: $0) }
            .sensoryFeedback(.selection, trigger: selection)
        }
    }

    static let mer = LinearGradient(colors: [Color(red: 0.02, green: 0.1, blue: 0.24), Charte.marine],
                                    startPoint: .top, endPoint: .bottom)

    private static func borner(_ valeur: CGFloat, ajustee: CGFloat) -> CGFloat {
        min(1.3, max(ajustee * 0.9, valeur))
    }

    private func zoomer(_ facteur: CGFloat, ajustee: CGFloat) {
        withAnimation(.spring(duration: 0.4)) { echelle = Self.borner(echelle * facteur, ajustee: ajustee) }
    }
}

/// Ce qui est touché sur la carte : un pays, un lieu ou l'Agora.
enum SelectionCarte: Equatable {
    case pays(String)
    case lieu(pays: String, nom: String)
    case agora
}

// MARK: - Le plan

/// La carte à l'échelle 1 (`CarteCulturiaView.cote` points de côté) : mer, pays, routes, lieux et combattants.
private struct PlanCarte: View {
    let monde: Monde
    let possedes: Set<String>
    /// Échelle d'affichage : sert à masquer les petits noms quand on voit toute la carte.
    let echelle: CGFloat
    let apparu: Bool
    @Binding var selection: SelectionCarte?
    let ouvrir: (ModeleCombattant) -> Void

    private let cote = CarteCulturiaView.cote

    private func point(_ x: Double?, _ y: Double?) -> CGPoint {
        CGPoint(x: CGFloat(x ?? 0.5) * cote, y: CGFloat(y ?? 0.5) * cote)
    }

    /// Les combattants jouables de chaque lieu : « pays|lieu » → combattants.
    private var habitants: [String: [ModeleCombattant]] {
        var dico: [String: [ModeleCombattant]] = [:]
        for modele in Catalogue.prototype {
            guard let h = modele.histoire else { continue }
            dico[h.pays + "|" + h.lieu, default: []].append(modele)
        }
        return dico
    }

    var body: some View {
        let habitants = habitants
        // Les noms des lieux grossissent quand on dézoome, pour rester lisibles.
        let lisible: CGFloat = min(2.6, max(1, 0.55 / echelle))
        ZStack(alignment: .topLeading) {
            FondCarte(monde: monde, apparu: apparu)
                .contentShape(Rectangle())
                .onTapGesture { selection = nil }

            // Agora.
            let agora = point(monde.agora.x, monde.agora.y)
            Button { selection = .agora } label: {
                VStack(spacing: 4) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Charte.or)
                        .shadow(color: Charte.or.opacity(0.7), radius: 12)
                    Text(monde.agora.nom)
                        .font(.titre(26 * lisible))
                        .lettrageLogo()
                        .fixedSize()
                }
            }
            .buttonStyle(.plain)
            .position(agora)

            ForEach(monde.pays) { pays in
                let centre = point(pays.x, pays.y)
                let rayon = CGFloat(pays.rayon ?? 0.1) * cote

                // Lieux et leurs combattants.
                ForEach(pays.lieux, id: \.nom) { lieu in
                    let p = point(lieu.x, lieu.y)
                    let gens = habitants[pays.id + "|" + lieu.nom] ?? []
                    GroupeLieu(lieu: lieu, capitale: lieu.nom == pays.capitale, gens: gens,
                               possedes: possedes, nomVisible: echelle > 0.28, grossi: lisible,
                               choisi: selection == .lieu(pays: pays.id, nom: lieu.nom),
                               toucherLieu: { selection = .lieu(pays: pays.id, nom: lieu.nom) },
                               ouvrir: ouvrir)
                        .position(p)
                }

                // Nom du pays, au-dessus de sa côte.
                Button { selection = .pays(pays.id) } label: {
                    VStack(spacing: 0) {
                        Text(Pictos.domaine(pays.domaine)).font(.system(size: 30 * lisible))
                        Text(pays.nom)
                            .font(.titre(40 * lisible))
                            .lettrageLogo()
                            .fixedSize()
                    }
                }
                .buttonStyle(.plain)
                .position(x: centre.x, y: centre.y - rayon - 14 * lisible)
                .scaleEffect(apparu ? 1 : 0.6)
                .opacity(apparu ? 1 : 0)
            }
        }
    }
}

/// Un lieu : son repère, son nom et ses combattants groupés autour en nid d'abeille.
private struct GroupeLieu: View {
    let lieu: Lieu
    let capitale: Bool
    let gens: [ModeleCombattant]
    let possedes: Set<String>
    let nomVisible: Bool
    let grossi: CGFloat
    let choisi: Bool
    let toucherLieu: () -> Void
    let ouvrir: (ModeleCombattant) -> Void

    static let avatar: CGFloat = 24

    /// Décalage du n-ième combattant autour du repère : 6 par anneau, puis 12, puis 18…
    static func decalage(_ n: Int) -> CGSize {
        var reste = n
        var anneau = 1
        while reste >= 6 * anneau {
            reste -= 6 * anneau
            anneau += 1
        }
        let angle = Double(reste) / Double(6 * anneau) * 2 * .pi - .pi / 2
        let d = CGFloat(anneau) * (avatar + 3)
        return CGSize(width: d * CGFloat(cos(angle)), height: d * CGFloat(sin(angle)))
    }

    var body: some View {
        ZStack {
            Button(action: toucherLieu) {
                ZStack {
                    Circle()
                        .fill(capitale ? Charte.or : Charte.ivoire)
                        .frame(width: capitale ? 16 : 10, height: capitale ? 16 : 10)
                        .overlay(Circle().stroke(Charte.marine, lineWidth: 2))
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    if choisi {
                        Circle().stroke(Charte.or, lineWidth: 3).frame(width: 30, height: 30)
                    }
                }
                .frame(width: 34, height: 34)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(lieu.nom)

            ForEach(Array(gens.enumerated()), id: \.element.id) { n, modele in
                let d = Self.decalage(n)
                let possede = possedes.contains(modele.id)
                Button { ouvrir(modele) } label: {
                    Avatar(modele: modele, taille: Self.avatar)
                        .modifier(Silhouette(active: !possede))
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
                .offset(d)
                .accessibilityLabel(possede ? modele.nom : "\(modele.nom), pas encore obtenu")
            }

            if nomVisible {
                let rayonGroupe = gens.isEmpty ? 10 : Self.decalage(gens.count - 1).height.magnitude + Self.avatar
                Text(lieu.nom)
                    .font(.nom((capitale ? 15 : 12) * grossi))
                    .foregroundStyle(capitale ? Charte.or : Charte.ivoire)
                    .shadow(color: .black, radius: 2)
                    .multilineTextAlignment(.center)
                    .frame(width: 170 * grossi)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: max(18, rayonGroupe) + 8 * grossi)
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Silhouette d'un combattant pas encore obtenu.
private struct Silhouette: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content
                .colorMultiply(Color(white: 0.08))
                .overlay(Text("?").font(.titre(11)).foregroundStyle(Charte.ivoire.opacity(0.8)))
                .opacity(0.85)
        } else {
            content
        }
    }
}

// MARK: - Le fond dessiné

/// Mer, vagues, routes vers l'Agora, côtes des pays et rose des vents, en formes vectorielles :
/// contrairement à un `Canvas`, elles ne coûtent rien hors de la partie visible de la carte.
private struct FondCarte: View {
    let monde: Monde
    let apparu: Bool

    private let cote = CarteCulturiaView.cote

    private func point(_ x: Double?, _ y: Double?) -> CGPoint {
        CGPoint(x: CGFloat(x ?? 0.5) * cote, y: CGFloat(y ?? 0.5) * cote)
    }

    var body: some View {
        let agora = point(monde.agora.x, monde.agora.y)
        ZStack {
            Rectangle().fill(LinearGradient(colors: [Color(red: 0.05, green: 0.2, blue: 0.38), Color(red: 0.02, green: 0.09, blue: 0.24)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing))
            Vagues().stroke(.white.opacity(0.08), lineWidth: 2)
            Rectangle().inset(by: 18).stroke(Charte.or.opacity(0.5), lineWidth: 4)
            Rectangle().inset(by: 30).stroke(Charte.or.opacity(0.25), lineWidth: 1.5)

            Routes(agora: agora, capitales: monde.pays.compactMap { pays in
                pays.lieu(pays.capitale).map { point($0.x, $0.y) }
            })
            .trim(from: 0, to: apparu ? 1 : 0)
            .stroke(Charte.or.opacity(0.45), style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 14]))

            ForEach(Array(monde.pays.enumerated()), id: \.element.id) { i, pays in
                TerrePays(pays: pays, centre: point(pays.x, pays.y),
                          rayon: CGFloat(pays.rayon ?? 0.1) * cote * 1.08, graine: Double(i) * 1.7 + 0.4)
            }

            let rayonAgora = 0.05 * cote
            let ile = Contour(centre: agora, rayon: rayonAgora, graine: 9)
            ile.stroke(Color.cyan.opacity(0.18), lineWidth: 18)
            ile.fill(RadialGradient(colors: [Charte.ivoire, Color(red: 0.85, green: 0.75, blue: 0.5)],
                                    center: UnitPoint(x: agora.x / cote, y: agora.y / cote), startRadius: 0, endRadius: rayonAgora))
            Circle()
                .stroke(Charte.or, style: StrokeStyle(lineWidth: 4, dash: [10, 6]))
                .frame(width: rayonAgora * 1.4, height: rayonAgora * 1.4)
                .position(agora)
            ile.stroke(Charte.or, lineWidth: 4)

            RoseDesVents(rayon: cote * 0.045)
                .position(x: cote * 0.92, y: cote * 0.92)
        }
        .frame(width: cote, height: cote)
        .accessibilityHidden(true)
    }
}

/// Une terre de pays : hauts-fonds, sol coloré selon le domaine, relief et côte.
private struct TerrePays: View {
    let pays: PaysDuMonde
    let centre: CGPoint
    let rayon: CGFloat
    let graine: Double

    var body: some View {
        let couleur = Specialite(id: "", nom: "", famille: "", domaine: pays.domaine).couleur
        let cote = CarteCulturiaView.cote
        let terre = Contour(centre: centre, rayon: rayon, graine: graine)
        ZStack {
            terre.stroke(Color.cyan.opacity(0.12), lineWidth: 34)
            terre.stroke(Color.cyan.opacity(0.18), lineWidth: 14)
            terre.fill(RadialGradient(colors: [couleur.opacity(0.75), couleur.opacity(0.45),
                                               Color(red: 0.25, green: 0.2, blue: 0.12).opacity(0.9)],
                                      center: UnitPoint(x: centre.x / cote, y: centre.y / cote),
                                      startRadius: 0, endRadius: rayon * 1.1))
            ForEach(1...3, id: \.self) { k in
                Contour(centre: centre, rayon: rayon * (1 - CGFloat(k) * 0.22), graine: graine + Double(k))
                    .stroke(.white.opacity(0.06), lineWidth: 2)
            }
            terre.stroke(Charte.ivoire.opacity(0.85), lineWidth: 3)
        }
    }
}

/// Contour irrégulier : un cercle déformé par trois ondulations, lissé en courbes.
private struct Contour: Shape {
    let centre: CGPoint
    let rayon: CGFloat
    let graine: Double

    func path(in rect: CGRect) -> Path {
        let n = 56
        let points: [CGPoint] = (0..<n).map { i in
            let a = Double(i) / Double(n) * 2 * .pi
            let r = 1 + 0.07 * sin(3 * a + graine) + 0.05 * sin(5 * a + graine * 2.3) + 0.025 * sin(11 * a + graine * 4.1)
            return CGPoint(x: centre.x + rayon * CGFloat(r * cos(a)), y: centre.y + rayon * CGFloat(r * sin(a)))
        }
        func milieu(_ p: CGPoint, _ q: CGPoint) -> CGPoint { CGPoint(x: (p.x + q.x) / 2, y: (p.y + q.y) / 2) }
        var chemin = Path()
        chemin.move(to: milieu(points[n - 1], points[0]))
        for i in 0..<n {
            chemin.addQuadCurve(to: milieu(points[i], points[(i + 1) % n]), control: points[i])
        }
        chemin.closeSubpath()
        return chemin
    }
}

/// Petites vagues en arcs, sur une grille décalée.
private struct Vagues: Shape {
    func path(in rect: CGRect) -> Path {
        var vagues = Path()
        let pas: CGFloat = 70
        var ligne = 0
        var y: CGFloat = pas / 2
        while y < rect.height {
            var x: CGFloat = ligne.isMultiple(of: 2) ? pas / 2 : pas
            while x < rect.width {
                vagues.move(to: CGPoint(x: x - 10, y: y))
                vagues.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - 5, y: y - 6))
                vagues.addQuadCurve(to: CGPoint(x: x + 10, y: y), control: CGPoint(x: x + 5, y: y - 6))
                x += pas
            }
            y += pas * 0.6
            ligne += 1
        }
        return vagues
    }
}

/// Routes courbes de l'Agora vers chaque capitale.
private struct Routes: Shape {
    let agora: CGPoint
    let capitales: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var routes = Path()
        for capitale in capitales {
            routes.move(to: agora)
            let milieu = CGPoint(x: (agora.x + capitale.x) / 2 + (capitale.y - agora.y) * 0.12,
                                 y: (agora.y + capitale.y) / 2 - (capitale.x - agora.x) * 0.12)
            routes.addQuadCurve(to: capitale, control: milieu)
        }
        return routes
    }
}

/// Rose des vents à 8 branches.
private struct RoseDesVents: View {
    let rayon: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Branche(longueur: i.isMultiple(of: 2) ? 1 : 0.55)
                    .fill(i.isMultiple(of: 2) ? Charte.or : Charte.ivoire.opacity(0.7))
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle().stroke(Charte.or.opacity(0.6), lineWidth: 2).frame(width: rayon * 1.5, height: rayon * 1.5)
            Text("N")
                .font(.titre(rayon * 0.35))
                .foregroundStyle(Charte.or)
                .offset(y: -rayon * 1.25)
        }
        .frame(width: rayon * 2, height: rayon * 2)
    }

    /// Une branche pointée vers le haut, de longueur relative au rayon.
    private struct Branche: Shape {
        let longueur: CGFloat

        func path(in rect: CGRect) -> Path {
            let c = CGPoint(x: rect.midX, y: rect.midY)
            let r = rect.width / 2
            var p = Path()
            p.move(to: CGPoint(x: c.x, y: c.y - r * longueur))
            p.addLine(to: CGPoint(x: c.x + r * 0.15, y: c.y))
            p.addLine(to: CGPoint(x: c.x - r * 0.15, y: c.y))
            p.closeSubpath()
            return p
        }
    }
}

// MARK: - Panneau de description

/// Panneau en bas de l'écran : description du pays, du lieu ou de l'Agora touché, et ses combattants.
private struct PanneauCarte: View {
    let selection: SelectionCarte
    let monde: Monde
    let possedes: Set<String>
    let ouvrir: (ModeleCombattant) -> Void
    let fermer: () -> Void

    private var contenu: (titre: String, sousTitre: String, texte: String, gens: [ModeleCombattant]) {
        switch selection {
        case .agora:
            return (monde.agora.nom, "Cité neutre", monde.agora.description, [])
        case .pays(let id):
            guard let pays = Univers.pays(id) else { return ("", "", "", []) }
            let gens = Catalogue.prototype.filter { $0.histoire?.pays == id }
            return (pays.nom, "\(Pictos.domaine(pays.domaine)) \(pays.domaine) · capitale \(pays.capitale)", pays.description, gens)
        case .lieu(let id, let nom):
            guard let pays = Univers.pays(id), let lieu = pays.lieu(nom) else { return ("", "", "", []) }
            let gens = Catalogue.prototype.filter { $0.histoire?.pays == id && $0.histoire?.lieu == nom }
            return (lieu.nom, "\(Pictos.domaine(pays.domaine)) \(pays.nom)", lieu.description, gens)
        }
    }

    var body: some View {
        let c = contenu
        let obtenus = c.gens.filter { possedes.contains($0.id) }.count
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.titre)
                        .font(.titre(20, relativeTo: .title3))
                        .lettrageLogo()
                    Text(c.sousTitre)
                        .font(.nom(12, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: fermer) {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .accessibilityLabel("Fermer")
            }
            Text(c.texte)
                .font(.footnote)
                .foregroundStyle(Charte.ivoire)
                .fixedSize(horizontal: false, vertical: true)
            if !c.gens.isEmpty {
                Text("\(obtenus) sur \(c.gens.count) combattant\(c.gens.count > 1 ? "s" : "") obtenu\(obtenus > 1 ? "s" : "")")
                    .font(.caption.bold())
                    .foregroundStyle(Charte.or)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(c.gens) { modele in
                            Button { ouvrir(modele) } label: {
                                Avatar(modele: modele, taille: 44)
                                    .modifier(Silhouette(active: !possedes.contains(modele.id)))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(modele.nom)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Charte.or.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
}
