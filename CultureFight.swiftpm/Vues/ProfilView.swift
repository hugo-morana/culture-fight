import SwiftUI
import SwiftData

/// Profil du compte : niveau et ligue, Pièces, bilan, progression de la collection,
/// radar de culture par domaine, puis les statistiques détaillées.
struct ProfilView: View {
    let joueur: Joueur
    let retour: () -> Void

    /// Les parties de ce joueur, de la plus ancienne à la plus récente (ordre des statistiques).
    private var parties: [PartieJouee] { joueur.parties.sorted { $0.date < $1.date } }

    /// Les 10 domaines du game design, dans l'ordre du radar.
    static let domaines = ["Matière", "Univers", "Terre", "Vivant", "Corps humain",
                           "Monde", "Histoire", "Arts", "Lettres et mythes", "Maths et techniques"]
    /// Objectif du catalogue complet (10 domaines × 100 combattants).
    static let objectifCatalogue = 1000

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    EnTeteProfil(joueur: joueur)
                    HStack(spacing: 8) {
                        TuileFiche(icone: "dollarsign.circle.fill", titre: "Pièces", valeur: "\(joueur.pieces)",
                                   accent: .yellow, index: 0)
                        TuileFiche(icone: "flag.checkered", titre: "Combats", valeur: "\(joueur.combatsJoues)",
                                   accent: Charte.or, index: 1)
                        TuileFiche(icone: "trophy.fill", titre: "Victoires", valeur: "\(joueur.victoires)",
                                   accent: BarreResultats.vert, index: 2)
                    }
                    CarteRadarCulture(reponses: parties.flatMap(\.reponses))
                    CarteCollectionProfil(possedes: Set(joueur.reserve.map(\.modeleID)))
                    CarteHistorique(parties: joueur.historique)
                    Text("Statistiques")
                        .font(.titre(24, relativeTo: .title2))
                        .lettrageLogo()
                        .padding(.top, 6)
                    StatistiquesView(parties: parties)
                    CarteReglagesSon()
                    NavigationLink {
                        MentionsLegalesView()
                    } label: {
                        Label("Mentions légales et crédits", systemImage: "c.circle")
                            .font(.footnote)
                            .frame(maxWidth: .infinity)
                    }
                    .tint(Charte.ivoire.opacity(0.8))
                    .padding(.top, 12)
                    Text("© \(MentionsLegalesView.annees) Hugo Morana · Tous droits réservés")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background { FondFiche(accent: Charte.or) }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
            }
        }
    }
}

// MARK: - En-tête

struct EnTeteProfil: View {
    let joueur: Joueur
    @State private var apparu = false
    @AppStorage("titrePorte") private var titrePorte = ""

    private var ligue: Ligue { joueur.ligue }
    private var part: Double {
        let seuil = joueur.seuilNiveauSuivant
        return seuil > 0 ? min(1, Double(joueur.xpCompte) / Double(seuil)) : 0
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [ligue.couleurs.0.opacity(0.55), .clear],
                                         center: .center, startRadius: 0, endRadius: 110))
                    .frame(width: 220, height: 220)
                    .scaleEffect(apparu ? 1 : 0.4)
                Circle()
                    .trim(from: 0, to: apparu ? part : 0)
                    .stroke(LinearGradient(colors: [ligue.couleurs.0, ligue.couleurs.1],
                                           startPoint: .top, endPoint: .bottom),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 150, height: 150)
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 150, height: 150)
                BadgeLigue(ligue: ligue, niveau: joueur.niveauCompte, taille: 96)
                    .phaseAnimator([false, true]) { vue, haut in
                        vue.offset(y: haut ? -3 : 3)
                    } animation: { _ in .easeInOut(duration: 2) }
                    .rotation3DEffect(.degrees(apparu ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            Text("Ligue \(ligue.nom)")
                .font(.titre(26, relativeTo: .title))
                .lettrageLogo()
            if !titrePorte.isEmpty, Recompenses.famillesCompletes(joueur.idsPossedes)
                .contains(where: { Recompenses.titre(famille: $0.famille) == titrePorte }) {
                Label(titrePorte, systemImage: "rosette")
                    .font(.nom(14, relativeTo: .subheadline))
                    .foregroundStyle(Charte.or)
            }
            Text("Niveau \(joueur.niveauCompte) · \(joueur.xpCompte) / \(joueur.seuilNiveauSuivant) XP")
                .font(.nom(14, relativeTo: .subheadline))
                .foregroundStyle(Charte.ivoire.opacity(0.85))
            if let suivante = ligue.niveauSuivante {
                Text("Ligue suivante au niveau \(suivante)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear { withAnimation(.spring(duration: 1.1, bounce: 0.3).delay(0.1)) { apparu = true } }
        .sensoryFeedback(.impact(weight: .light), trigger: apparu)
    }
}

// MARK: - Radar de culture

/// Polygone d'un radar à n axes ; `progression` (0 → 1) le fait grandir depuis le centre.
struct FormeRadar: Shape {
    var valeurs: [Double]
    var progression: Double

    var animatableData: Double {
        get { progression }
        set { progression = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var chemin = Path()
        guard valeurs.count >= 3 else { return chemin }
        for (i, v) in valeurs.enumerated() {
            let p = FormeRadar.point(i, sur: valeurs.count, rayon: v / 100 * progression, dans: rect)
            if i == 0 { chemin.move(to: p) } else { chemin.addLine(to: p) }
        }
        chemin.closeSubpath()
        return chemin
    }

    /// Point de l'axe `i` à `rayon` (0 → 1) du centre ; le premier axe pointe vers le haut.
    static func point(_ i: Int, sur n: Int, rayon: Double, dans rect: CGRect) -> CGPoint {
        let angle = Double(i) / Double(n) * 2 * Double.pi - Double.pi / 2
        let r = min(rect.width, rect.height) / 2 * rayon
        return CGPoint(x: rect.midX + r * cos(angle), y: rect.midY + r * sin(angle))
    }
}

/// Un axe du radar : un domaine, une famille ou une spécialité.
struct AxeRadar: Identifiable {
    let nom: String
    let picto: String
    let score: Score
    var id: String { nom }
    var valeur: Double { score.precision }
}

/// Spider chart des 10 domaines ; toucher un domaine zoome sur ses familles, puis une famille sur ses spécialités.
struct CarteRadarCulture: View {
    let reponses: [ReponseJouee]

    enum Niveau: Equatable {
        case domaines
        case familles(String)
        case specialites(String, String)
    }

    @State private var niveau = Niveau.domaines
    @State private var progression = 0.0
    @State private var choisi: String?

    /// Les 10 familles du plan de chaque domaine (feuille « 1 000 combattants », onglet Plan).
    static let plan: [String: [String]] = [
        "Matière": ["Éléments chimiques", "Molécules et réactions", "Mécanique", "Électricité et magnétisme",
                    "Lumière et ondes", "Chaleur et énergie", "Atome et particules", "Unités et mesures",
                    "Matériaux", "Savants et laboratoire"],
        "Univers": ["Système solaire", "Lunes et petits corps", "Étoiles", "Constellations", "Galaxies et cosmologie",
                    "Phénomènes célestes", "Conquête spatiale", "Astronautes", "Instruments d'observation", "Astronomes"],
        "Terre": ["Volcans", "Séismes et tectonique", "Fleuves", "Lacs", "Océans et mers", "Montagnes", "Déserts",
                  "Îles", "Minéraux et roches", "Climat et météo"],
        "Vivant": ["Mammifères", "Oiseaux", "Reptiles et amphibiens", "Poissons et vie marine", "Insectes et arachnides",
                   "Animaux préhistoriques", "Arbres", "Fleurs et plantes", "Champignons et microbes", "Écologie"],
        "Corps humain": ["Squelette", "Muscles", "Organes", "Cerveau et nerfs", "Cœur et sang", "Les sens",
                         "Maladies et médecine", "Nutrition", "Génétique", "Grands médecins"],
        "Monde": ["Capitales", "Drapeaux", "Monnaies", "Langues", "Grandes villes", "Populations",
                  "France : régions et départements", "Pays et frontières", "Gastronomie du monde", "Fêtes et traditions"],
        "Histoire": ["Préhistoire", "Égypte ancienne", "Grèce antique", "Rome antique", "Moyen Âge",
                     "Renaissance et grandes découvertes", "Ancien Régime", "Révolution et Empire", "XIXe siècle", "XXe siècle"],
        "Arts": ["Peinture", "Sculpture", "Architecture et monuments", "Musique classique", "Opéra et danse",
                 "Instruments de musique", "Photographie", "Cinéma", "Musées et chefs-d'œuvre", "Arts décoratifs"],
        "Lettres et mythes": ["Romans", "Poésie", "Théâtre", "Contes et fables", "Mythologie grecque",
                              "Mythologie nordique", "Mythologies du monde", "Philosophie", "Langue française", "Étymologie"],
        "Maths et techniques": ["Calcul mental", "Algèbre", "Géométrie", "Nombres", "Probabilités et logique", "Mathématiciens",
                                "Inventions", "Informatique", "Transports", "Télécommunications"],
    ]

    private var axes: [AxeRadar] {
        switch niveau {
        case .domaines:
            return ProfilView.domaines.map { d in
                AxeRadar(nom: d, picto: Pictos.domaine(d), score: score { $0.domaine == d })
            }
        case .familles(let d):
            var noms = Self.plan[d] ?? []
            for r in reponses where r.domaine == d && !noms.contains(r.famille) { noms.append(r.famille) }
            return noms.map { f in
                AxeRadar(nom: f, picto: Pictos.famille(f, domaine: d),
                         score: score { $0.domaine == d && $0.famille == f })
            }
        case .specialites(let d, let f):
            var noms = Catalogue.prototype
                .filter { $0.specialite.domaine == d && $0.specialite.famille == f }
                .map(\.specialite.nom)
            for r in reponses where r.domaine == d && r.famille == f && !noms.contains(r.specialite) {
                noms.append(r.specialite)
            }
            var liste = noms.map { n in
                AxeRadar(nom: n, picto: Pictos.famille(f, domaine: d),
                         score: score { $0.domaine == d && $0.famille == f && $0.specialite == n })
            }
            // Un radar demande au moins 3 axes : on complète avec des spécialités à venir.
            var k = 1
            while liste.count < 3 {
                liste.append(AxeRadar(nom: "À venir \(k)", picto: "🔒", score: Score()))
                k += 1
            }
            return liste
        }
    }

    private func score(_ filtre: (ReponseJouee) -> Bool) -> Score {
        var s = Score()
        reponses.filter(filtre).forEach { s.ajouter($0.correct) }
        return s
    }

    private var titre: String {
        switch niveau {
        case .domaines: return "Radar de culture"
        case .familles(let d): return "\(Pictos.domaine(d)) \(d)"
        case .specialites(_, let f): return f
        }
    }

    var body: some View {
        CarteFiche(titre: titre, icone: "hexagon.fill", accent: Charte.or) {
            VStack(spacing: 12) {
                if niveau != .domaines {
                    Button {
                        remonter()
                    } label: {
                        Label(niveau == .domaines ? "" : retourLibelle, systemImage: "chevron.left")
                            .font(.nom(13, relativeTo: .caption))
                    }
                    .tint(Charte.or)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                RadarVue(axes: axes, progression: progression, choisi: choisi) { axe in
                    toucher(axe)
                }
                .frame(height: 320)
                .id(niveau == .domaines ? "d" : titre)
                .transition(.asymmetric(insertion: .scale(scale: 0.3).combined(with: .opacity),
                                        removal: .scale(scale: 1.8).combined(with: .opacity)))
                legende
                    .font(.nom(13, relativeTo: .caption))
                    .foregroundStyle(Charte.ivoire.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .clipped()
        }
        .onAppear { tracer() }
        .sensoryFeedback(.impact(weight: .medium), trigger: niveau)
        .sensoryFeedback(.selection, trigger: choisi)
    }

    @ViewBuilder
    private var legende: some View {
        if let choisi, let axe = axes.first(where: { $0.nom == choisi }) {
            Text("\(axe.picto) \(axe.nom) · " + (axe.score.total == 0 ? "aucune question encore"
                 : "\(axe.score.bonnes) bonnes réponses sur \(axe.score.total) (\(Int(axe.valeur)) %)"))
        } else {
            switch niveau {
            case .domaines: Text("Précision par domaine. Touche un domaine pour zoomer sur ses familles.")
            case .familles: Text("Touche une famille pour zoomer sur ses spécialités.")
            case .specialites: Text("Touche une spécialité pour voir son détail.")
            }
        }
    }

    private var retourLibelle: String {
        if case .specialites(let d, _) = niveau { return d }
        return "Domaines"
    }

    private func toucher(_ axe: AxeRadar) {
        switch niveau {
        case .domaines: zoomer(.familles(axe.nom))
        case .familles(let d): zoomer(.specialites(d, axe.nom))
        case .specialites:
            withAnimation(.snappy) { choisi = choisi == axe.nom ? nil : axe.nom }
        }
    }

    private func zoomer(_ suivant: Niveau) {
        choisi = nil
        progression = 0
        withAnimation(.spring(duration: 0.6, bounce: 0.25)) { niveau = suivant }
        tracer()
    }

    private func remonter() {
        switch niveau {
        case .specialites(let d, _): zoomer(.familles(d))
        default: zoomer(.domaines)
        }
    }

    private func tracer() {
        withAnimation(.spring(duration: 1.3, bounce: 0.25).delay(0.25)) { progression = 1 }
    }
}

/// Le dessin du radar : grille, axes, polygone animé et étiquettes touchables.
struct RadarVue: View {
    let axes: [AxeRadar]
    let progression: Double
    let choisi: String?
    let toucher: (AxeRadar) -> Void

    var body: some View {
        GeometryReader { geo in
            let cadre = CGRect(origin: .zero, size: geo.size).insetBy(dx: 58, dy: 40)
            let valeurs = axes.map(\.valeur)
            ZStack {
                ForEach([25.0, 50, 75, 100], id: \.self) { palier in
                    FormeRadar(valeurs: Array(repeating: palier, count: axes.count), progression: 1)
                        .stroke(Color.white.opacity(palier == 100 ? 0.25 : 0.1), lineWidth: 1)
                        .frame(width: cadre.width, height: cadre.height)
                        .position(x: cadre.midX, y: cadre.midY)
                }
                Path { p in
                    for i in axes.indices {
                        p.move(to: CGPoint(x: cadre.midX, y: cadre.midY))
                        p.addLine(to: FormeRadar.point(i, sur: axes.count, rayon: 1, dans: cadre))
                    }
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                FormeRadar(valeurs: valeurs, progression: progression)
                    .fill(LinearGradient(colors: [Charte.or.opacity(0.55), Color.blue.opacity(0.35)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: cadre.width, height: cadre.height)
                    .position(x: cadre.midX, y: cadre.midY)
                FormeRadar(valeurs: valeurs, progression: progression)
                    .stroke(Charte.or, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                    .shadow(color: Charte.or.opacity(0.8), radius: 6)
                    .frame(width: cadre.width, height: cadre.height)
                    .position(x: cadre.midX, y: cadre.midY)
                ForEach(Array(axes.enumerated()), id: \.offset) { i, axe in
                    Circle()
                        .fill(Charte.or)
                        .frame(width: choisi == axe.nom ? 12 : 6, height: choisi == axe.nom ? 12 : 6)
                        .position(FormeRadar.point(i, sur: axes.count, rayon: axe.valeur / 100 * progression, dans: cadre))
                    etiquette(axe)
                        .position(FormeRadar.point(i, sur: axes.count, rayon: 1.3, dans: cadre))
                }
            }
        }
    }

    private func etiquette(_ axe: AxeRadar) -> some View {
        Button {
            toucher(axe)
        } label: {
            VStack(spacing: 0) {
                Text(axe.picto).font(.system(size: axes.count > 8 ? 15 : 18))
                if axes.count <= 10 {
                    Text(axe.nom)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Charte.ivoire.opacity(0.75))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                }
                Text(axe.score.total > 0 ? "\(Int(axe.valeur)) %" : "—")
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(choisi == axe.nom ? Charte.or : Charte.ivoire)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progression de la collection

struct CarteCollectionProfil: View {
    let possedes: Set<String>
    @State private var deploye = false

    private var total: Int { Catalogue.prototype.count }
    private var nombre: Int { Catalogue.prototype.filter { possedes.contains($0.id) }.count }

    var body: some View {
        CarteFiche(titre: "Collection", icone: "square.stack.3d.up.fill", accent: Charte.or) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 18) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.1), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: deploye ? Double(nombre) / Double(max(1, total)) : 0)
                            .stroke(AngularGradient(colors: [Charte.or, .orange, Charte.or], center: .center),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text("\(nombre)")
                                .font(.titre(30))
                                .foregroundStyle(Charte.ivoire)
                            Text("sur \(total)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 110, height: 110)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Combattants jouables")
                            .font(.nom(15, relativeTo: .headline))
                            .foregroundStyle(Charte.ivoire)
                        Text("\(nombre) sur les \(ProfilView.objectifCatalogue) prévus au catalogue complet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: deploye ? Double(nombre) : 0, total: Double(ProfilView.objectifCatalogue))
                            .tint(Charte.or)
                    }
                }
                ForEach(Array(ProfilView.domaines.enumerated()), id: \.offset) { index, domaine in
                    ligne(domaine, index: index)
                }
            }
        }
        .onAppear { withAnimation(.spring(duration: 1.2, bounce: 0.2).delay(0.3)) { deploye = true } }
    }

    @ViewBuilder
    private func ligne(_ domaine: String, index: Int) -> some View {
        let duDomaine = Catalogue.prototype.filter { $0.specialite.domaine == domaine }
        let a = duDomaine.filter { possedes.contains($0.id) }.count
        let couleur = Specialite(id: "", nom: "", famille: "", domaine: domaine).couleur
        HStack(spacing: 10) {
            Text(Pictos.domaine(domaine)).frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(domaine)
                        .font(.nom(13, relativeTo: .subheadline))
                        .foregroundStyle(Charte.ivoire)
                    Spacer()
                    Text(duDomaine.isEmpty ? "bientôt" : "\(a) / \(duDomaine.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.08))
                        Capsule()
                            .fill(couleur.gradient)
                            .frame(width: deploye && !duDomaine.isEmpty
                                   ? geo.size.width * CGFloat(a) / CGFloat(duDomaine.count) : 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .opacity(deploye ? 1 : 0)
        .offset(x: deploye ? 0 : -16)
        .animation(.spring(duration: 0.6).delay(0.3 + 0.05 * Double(index)), value: deploye)
    }
}

// MARK: - Réglages du son

/// Réglages « Musique » (thèmes) et « Effets » (bruitages), mémorisés sur l'appareil.
struct CarteReglagesSon: View {
    @AppStorage(ServiceAudio.cleMusique) private var musique = true
    @AppStorage(ServiceSons.cleEffets) private var effets = true

    var body: some View {
        CarteFiche(titre: "Son", icone: "speaker.wave.2.fill", accent: Charte.or) {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $musique) {
                    Label("Musique", systemImage: "music.note")
                }
                .tint(Charte.or)
                Toggle(isOn: $effets) {
                    Label("Effets sonores", systemImage: "speaker.wave.1")
                }
                .tint(Charte.or)
                TexteFiche(texte: "Le son se coupe aussi quand l'iPhone est en mode silencieux "
                           + "ou, pour la musique, quand vous écoutez déjà la vôtre.")
            }
        }
        .onChange(of: musique) { _, _ in
            ServiceAudio.partage.reglageModifie()
        }
        .onChange(of: effets) { _, actif in
            if actif { ServiceSons.partage.jouer(.selection) }
        }
    }
}
