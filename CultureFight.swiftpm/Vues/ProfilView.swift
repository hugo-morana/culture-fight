import SwiftUI
import SwiftData

/// Profil du compte : niveau et ligue, Pièces, bilan, progression de la collection,
/// radar de culture par domaine, puis les statistiques détaillées.
struct ProfilView: View {
    let joueur: Joueur
    let retour: () -> Void

    @Query(sort: \PartieJouee.date) private var parties: [PartieJouee]

    /// Les 10 domaines du game design, dans l'ordre du radar.
    static let domaines = ["Matière", "Univers", "Terre", "Vivant", "Corps humain",
                           "Monde", "Histoire", "Arts", "Lettres et mythes", "Savoirs"]
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
                    CarteRadarCulture(scores: scoresParDomaine)
                    CarteCollectionProfil(possedes: Set(joueur.reserve.map(\.modeleID)))
                    Text("Statistiques")
                        .font(.titre(24, relativeTo: .title2))
                        .lettrageLogo()
                        .padding(.top, 6)
                    StatistiquesView(parties: parties)
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

    /// Précision par domaine, sur toutes les parties sauvegardées.
    private var scoresParDomaine: [String: Score] {
        var scores: [String: Score] = [:]
        for r in parties.flatMap(\.reponses) { scores[r.domaine, default: Score()].ajouter(r.correct) }
        return scores
    }
}

// MARK: - En-tête

struct EnTeteProfil: View {
    let joueur: Joueur
    @State private var apparu = false

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

struct CarteRadarCulture: View {
    let scores: [String: Score]
    @State private var progression = 0.0
    @State private var choisi: String?

    private var domaines: [String] { ProfilView.domaines }
    private var valeurs: [Double] { domaines.map { scores[$0]?.precision ?? 0 } }

    var body: some View {
        CarteFiche(titre: "Radar de culture", icone: "hexagon.fill", accent: Charte.or) {
            VStack(spacing: 12) {
                GeometryReader { geo in
                    let cadre = CGRect(origin: .zero, size: geo.size).insetBy(dx: 52, dy: 30)
                    ZStack {
                        ForEach([25.0, 50, 75, 100], id: \.self) { niveau in
                            FormeRadar(valeurs: Array(repeating: niveau, count: domaines.count), progression: 1)
                                .stroke(Color.white.opacity(niveau == 100 ? 0.25 : 0.1), lineWidth: 1)
                                .frame(width: cadre.width, height: cadre.height)
                                .position(x: cadre.midX, y: cadre.midY)
                        }
                        Path { p in
                            for i in domaines.indices {
                                p.move(to: CGPoint(x: cadre.midX, y: cadre.midY))
                                p.addLine(to: FormeRadar.point(i, sur: domaines.count, rayon: 1, dans: cadre))
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
                        ForEach(Array(domaines.enumerated()), id: \.offset) { i, domaine in
                            let p = FormeRadar.point(i, sur: domaines.count, rayon: valeurs[i] / 100 * progression, dans: cadre)
                            Circle()
                                .fill(Specialite(id: "", nom: "", famille: "", domaine: domaine).couleur)
                                .frame(width: choisi == domaine ? 12 : 7, height: choisi == domaine ? 12 : 7)
                                .position(p)
                            let etiquette = FormeRadar.point(i, sur: domaines.count, rayon: 1.28, dans: cadre)
                            Button {
                                withAnimation(.snappy) { choisi = choisi == domaine ? nil : domaine }
                            } label: {
                                VStack(spacing: 0) {
                                    Text(Pictos.domaine(domaine)).font(.system(size: 18))
                                    Text(scores[domaine].map { "\(Int($0.precision)) %" } ?? "—")
                                        .font(.caption2.monospacedDigit().bold())
                                        .foregroundStyle(choisi == domaine ? Charte.or : Charte.ivoire.opacity(0.8))
                                }
                            }
                            .buttonStyle(.plain)
                            .position(etiquette)
                        }
                    }
                }
                .frame(height: 300)
                Group {
                    if let choisi {
                        let s = scores[choisi] ?? Score()
                        Text("\(Pictos.domaine(choisi)) \(choisi) · \(s.total == 0 ? "aucune question encore" : "\(s.bonnes) bonnes réponses sur \(s.total)")")
                    } else {
                        Text("Précision par domaine. Touche un pictogramme pour le détail.")
                    }
                }
                .font(.nom(13, relativeTo: .caption))
                .foregroundStyle(Charte.ivoire.opacity(0.85))
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
            }
        }
        .onAppear { withAnimation(.spring(duration: 1.4, bounce: 0.25).delay(0.3)) { progression = 1 } }
        .sensoryFeedback(.selection, trigger: choisi)
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
