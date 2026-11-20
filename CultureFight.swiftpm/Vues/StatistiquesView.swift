import SwiftUI
import Charts

// Statistiques du profil, à la manière des « Perspectives » de Chess.com, adaptées à Culture Fight :
// aperçu des résultats, précision dans le temps, par question, par rapidité, par difficulté,
// par niveau de l'IA, puis détail domaine → famille → spécialité et points d'amélioration.

// MARK: - Calculs

/// Bonnes réponses sur un total.
struct Score: Sendable {
    var bonnes = 0
    var total = 0

    var manquees: Int { total - bonnes }
    var precision: Double { total > 0 ? Double(bonnes) / Double(total) * 100 : 0 }

    mutating func ajouter(_ correct: Bool) {
        total += 1
        if correct { bonnes += 1 }
    }
}

/// Un domaine, une famille ou une spécialité avec son score.
struct LigneScore: Identifiable, Sendable {
    let nom: String
    let picto: String
    var score: Score
    var enfants: [LigneScore] = []
    var chemin: String = ""
    var id: String { chemin.isEmpty ? nom : chemin }
}

struct AnalyseStats {
    let parties: [PartieJouee]

    var reponses: [ReponseJouee] { parties.flatMap(\.reponses) }
    var victoires: Int { parties.filter(\.estVictoire).count }
    var nuls: Int { parties.filter(\.estNul).count }
    var defaites: Int { parties.filter(\.estDefaite).count }

    var precision: Double {
        var s = Score()
        reponses.forEach { s.ajouter($0.correct) }
        return s.precision
    }

    func precision(_ filtre: (PartieJouee) -> Bool) -> Double? {
        var s = Score()
        parties.filter(filtre).flatMap(\.reponses).forEach { s.ajouter($0.correct) }
        return s.total > 0 ? s.precision : nil
    }

    /// Parties par jour sur les 14 derniers jours.
    var partiesParJour: [(jour: Date, nombre: Int)] {
        let cal = Calendar.current
        let aujourdhui = cal.startOfDay(for: Date())
        return (0..<14).reversed().map { decalage in
            let jour = cal.date(byAdding: .day, value: -decalage, to: aujourdhui) ?? aujourdhui
            let n = parties.filter { cal.isDate($0.date, inSameDayAs: jour) }.count
            return (jour, n)
        }
    }

    /// Précision de chacune des 30 dernières parties.
    var precisionParPartie: [(numero: Int, precision: Double)] {
        let recentes = parties.suffix(30)
        let debut = parties.count - recentes.count
        return recentes.enumerated().compactMap { i, p in
            p.precision.map { (debut + i + 1, $0) }
        }
    }

    /// Précision selon le rang de la question dans la partie (1re, 2e…), jusqu'à 15.
    var precisionParRang: [(rang: Int, precision: Double)] {
        var scores: [Int: Score] = [:]
        for r in reponses where r.rang <= 15 { scores[r.rang, default: Score()].ajouter(r.correct) }
        return scores.keys.sorted().compactMap { k in
            guard let s = scores[k], s.total > 0 else { return nil }
            return (k, s.precision)
        }
    }

    var precisionParDifficulte: [(difficulte: Int, score: Score)] {
        var scores: [Int: Score] = [:]
        for r in reponses { scores[r.difficulte, default: Score()].ajouter(r.correct) }
        return scores.keys.sorted().map { ($0, scores[$0] ?? Score()) }
    }

    var repartitionRapidite: [(appreciation: Appreciation, nombre: Int)] {
        var compte: [Appreciation: Int] = [:]
        for r in reponses {
            let a: Appreciation
            if r.tempsEcoule { a = .tempsEcoule }
            else if !r.correct { a = .erreur }
            else if r.secondes < Regles.seuilEclair { a = .brillante }
            else if r.secondes < Regles.seuilRapide { a = .excellente }
            else { a = .bonne }
            compte[a, default: 0] += 1
        }
        return Appreciation.allCases.map { ($0, compte[$0, default: 0]) }
    }

    var tempsMoyen: Double {
        let r = reponses.filter { !$0.tempsEcoule }
        guard !r.isEmpty else { return 0 }
        return r.map(\.secondes).reduce(0, +) / Double(r.count)
    }

    /// Victoires, nuls et défaites par niveau de l'IA.
    var resultatsParNiveau: [(niveau: String, resultat: String, nombre: Int)] {
        IAAdverse.Niveau.allCases.flatMap { n -> [(String, String, Int)] in
            let ps = parties.filter { $0.niveauIA == n.rawValue }
            return [(n.rawValue, "Victoires", ps.filter(\.estVictoire).count),
                    (n.rawValue, "Nuls", ps.filter(\.estNul).count),
                    (n.rawValue, "Défaites", ps.filter(\.estDefaite).count)]
        }
    }

    /// Arbre domaine → famille → spécialité, trié par nombre de questions.
    var domaines: [LigneScore] {
        var arbre: [String: [String: [String: Score]]] = [:]
        for r in reponses {
            arbre[r.domaine, default: [:]][r.famille, default: [:]][r.specialite, default: Score()].ajouter(r.correct)
        }
        return arbre.map { domaine, familles -> LigneScore in
            let enfants = familles.map { famille, specialites -> LigneScore in
                let feuilles = specialites.map { nom, score in
                    LigneScore(nom: nom, picto: "", score: score, chemin: "\(domaine)/\(famille)/\(nom)")
                }.sorted { $0.score.total > $1.score.total }
                return LigneScore(nom: famille, picto: Pictos.famille(famille, domaine: domaine),
                                  score: Self.somme(feuilles), enfants: feuilles, chemin: "\(domaine)/\(famille)")
            }.sorted { $0.score.total > $1.score.total }
            return LigneScore(nom: domaine, picto: Pictos.domaine(domaine), score: Self.somme(enfants),
                              enfants: enfants, chemin: domaine)
        }.sorted { $0.score.total > $1.score.total }
    }

    /// Spécialités avec au moins 3 réponses, de la plus faible à la plus forte.
    var specialitesClassees: [(ligne: LigneScore, chemin: String)] {
        domaines.flatMap { d in
            d.enfants.flatMap { f in
                f.enfants.map { ($0, "\(d.picto) \(d.nom) › \(f.picto) \(f.nom)") }
            }
        }
        .filter { $0.0.score.total >= 3 }
        .sorted { $0.0.score.precision < $1.0.score.precision }
    }

    static func somme(_ lignes: [LigneScore]) -> Score {
        lignes.reduce(Score()) { Score(bonnes: $0.bonnes + $1.score.bonnes, total: $0.total + $1.score.total) }
    }

    /// Conseils tirés des chiffres, comme les « points d'amélioration » de Chess.com.
    var conseils: [String] {
        var liste: [String] = []
        let total = reponses.count
        guard total > 0 else { return liste }
        let ecoules = reponses.filter(\.tempsEcoule).count
        if Double(ecoules) / Double(total) > 0.1 {
            liste.append("Tu laisses filer le chrono sur \(Int(Double(ecoules) / Double(total) * 100)) % des questions : réponds plus vite, quitte à tenter ta chance.")
        }
        if let pire = specialitesClassees.first, pire.ligne.score.precision < 60 {
            liste.append("Révise « \(pire.ligne.nom) » : \(Int(pire.ligne.score.precision)) % de bonnes réponses sur \(pire.ligne.score.total) questions.")
        }
        let parDiff = precisionParDifficulte
        if let dure = parDiff.first(where: { $0.difficulte >= 3 && $0.score.total >= 3 && $0.score.precision < 50 }) {
            liste.append("Les questions de difficulté \(dure.difficulte) te résistent (\(Int(dure.score.precision)) %) : entraîne-toi avec la revue de partie.")
        }
        let rang = precisionParRang
        if let debut = rang.first?.precision, let finale = rang.last?.precision, rang.count >= 6, finale < debut - 15 {
            liste.append("Ta précision baisse en fin de combat (\(Int(debut)) % → \(Int(finale)) %) : garde ta concentration jusqu'au bout.")
        }
        if liste.isEmpty {
            liste.append("Belle régularité : continue à varier les domaines pour progresser partout.")
        }
        return liste
    }
}

// MARK: - Vue principale

struct StatistiquesView: View {
    let parties: [PartieJouee]

    private var analyse: AnalyseStats { AnalyseStats(parties: parties) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if parties.isEmpty {
                CarteFiche(titre: "Statistiques", icone: "chart.xyaxis.line", accent: Charte.or) {
                    VStack(spacing: 10) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(Charte.or)
                            .symbolEffect(.pulse)
                        Text("Joue ton premier combat pour voir tes statistiques ici.")
                            .font(.nom(15, relativeTo: .subheadline))
                            .foregroundStyle(Charte.ivoire)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                let a = analyse
                CarteApercu(analyse: a)
                CartePrecision(analyse: a)
                CarteAmelioration(analyse: a)
                CarteDomaines(domaines: a.domaines)
                CarteRapidite(analyse: a)
                CarteDifficulte(analyse: a)
                CarteNiveauxIA(analyse: a)
            }
        }
    }
}

/// Grand nombre en Cinzel qui défile de 0 à sa valeur.
struct GrandNombre: View {
    let valeur: Double
    var decimales = 0
    var suffixe = ""
    var icone: String? = nil

    @State private var affiche: Double = 0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let icone {
                Image(systemName: icone)
                    .font(.system(size: 34))
                    .foregroundStyle(Charte.or)
            }
            Text(String(format: "%.\(decimales)f", affiche) + suffixe)
                .font(.titre(52, relativeTo: .largeTitle))
                .foregroundStyle(Charte.ivoire)
                .contentTransition(.numericText(value: affiche))
                .monospacedDigit()
        }
        .onAppear {
            withAnimation(.spring(duration: 1.4, bounce: 0.1).delay(0.2)) { affiche = valeur }
        }
    }
}

/// Barre victoires · nuls · défaites qui se déploie.
struct BarreResultats: View {
    let victoires: Int
    let nuls: Int
    let defaites: Int

    @State private var deploye = false

    static let vert = Color(red: 0.51, green: 0.71, blue: 0.32)
    static let gris = Color(red: 0.62, green: 0.62, blue: 0.62)
    static let rouge = Color(red: 0.82, green: 0.26, blue: 0.22)

    var body: some View {
        let total = max(1, victoires + nuls + defaites)
        GeometryReader { geo in
            let w = geo.size.width
            HStack(spacing: 2) {
                Capsule().fill(Self.vert).frame(width: deploye ? w * CGFloat(victoires) / CGFloat(total) : 0)
                Rectangle().fill(Self.gris).frame(width: deploye ? w * CGFloat(nuls) / CGFloat(total) : 0)
                Capsule().fill(Self.rouge).frame(width: deploye ? w * CGFloat(defaites) / CGFloat(total) : 0)
            }
        }
        .frame(height: 12)
        .onAppear { withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.3)) { deploye = true } }
    }
}

struct ChiffreResultat: View {
    let symbole: String
    let couleur: Color
    let pourcentage: Double
    let libelle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: symbole)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(couleur, in: RoundedRectangle(cornerRadius: 6))
                Text(String(format: "%.1f %%", pourcentage))
                    .font(.titre(18))
                    .foregroundStyle(Charte.ivoire)
            }
            Text(libelle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Aperçu

struct CarteApercu: View {
    let analyse: AnalyseStats
    @State private var apparu = false

    var body: some View {
        let total = Double(max(1, analyse.parties.count))
        CarteFiche(titre: "Aperçu", icone: "magnifyingglass.circle.fill", accent: Charte.or) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Parties jouées")
                    .font(.nom(15, relativeTo: .headline))
                    .foregroundStyle(.secondary)
                GrandNombre(valeur: Double(analyse.parties.count), icone: "flag.checkered")
                HStack {
                    ChiffreResultat(symbole: "plus", couleur: BarreResultats.vert,
                                    pourcentage: Double(analyse.victoires) / total * 100,
                                    libelle: "\(analyse.victoires) victoires")
                    ChiffreResultat(symbole: "equal", couleur: BarreResultats.gris,
                                    pourcentage: Double(analyse.nuls) / total * 100,
                                    libelle: "\(analyse.nuls) nuls")
                    ChiffreResultat(symbole: "minus", couleur: BarreResultats.rouge,
                                    pourcentage: Double(analyse.defaites) / total * 100,
                                    libelle: "\(analyse.defaites) défaites")
                }
                BarreResultats(victoires: analyse.victoires, nuls: analyse.nuls, defaites: analyse.defaites)
                Chart(analyse.partiesParJour, id: \.jour) { point in
                    BarMark(x: .value("Jour", point.jour, unit: .day),
                            y: .value("Parties", apparu ? point.nombre : 0))
                        .foregroundStyle(Color(red: 0.42, green: 0.42, blue: 0.62).gradient)
                        .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 4)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 140)
                Text("Parties des 14 derniers jours")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear { withAnimation(.spring(duration: 1.0).delay(0.4)) { apparu = true } }
    }
}

// MARK: - Précision

struct CartePrecision: View {
    let analyse: AnalyseStats
    @State private var apparu = false

    private static let bleu = Color(red: 0.36, green: 0.66, blue: 0.85)

    var body: some View {
        CarteFiche(titre: "Précision moyenne", icone: "scope", accent: Self.bleu) {
            VStack(alignment: .leading, spacing: 14) {
                GrandNombre(valeur: analyse.precision, decimales: 1, suffixe: " %", icone: "scope")
                HStack(alignment: .top) {
                    sousPrecision("Quand tu gagnes", "plus", BarreResultats.vert, analyse.precision(\.estVictoire))
                    sousPrecision("Quand tu fais nul", "equal", BarreResultats.gris, analyse.precision(\.estNul))
                    sousPrecision("Quand tu perds", "minus", BarreResultats.rouge, analyse.precision(\.estDefaite))
                }
                if analyse.precisionParPartie.count >= 2 {
                    Text("Au fil des parties")
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(Charte.or)
                    courbe(analyse.precisionParPartie.map { (Double($0.numero), $0.precision) }, axe: "Partie")
                }
                if analyse.precisionParRang.count >= 2 {
                    Text("Selon le rang de la question dans le combat")
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(Charte.or)
                    courbe(analyse.precisionParRang.map { (Double($0.rang), $0.precision) }, axe: "Question")
                }
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.2).delay(0.3)) { apparu = true } }
    }

    private func sousPrecision(_ titre: String, _ symbole: String, _ couleur: Color, _ valeur: Double?) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(titre)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
            HStack(spacing: 4) {
                Image(systemName: symbole)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(couleur, in: RoundedRectangle(cornerRadius: 5))
                Text(valeur.map { String(format: "%.1f", $0) } ?? "—")
                    .font(.titre(18))
                    .foregroundStyle(Charte.ivoire)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func courbe(_ points: [(Double, Double)], axe: String) -> some View {
        Chart(Array(points.enumerated()), id: \.offset) { _, p in
            AreaMark(x: .value(axe, p.0), y: .value("Précision", apparu ? p.1 : 0))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(LinearGradient(colors: [Self.bleu.opacity(0.55), Self.bleu.opacity(0.05)],
                                                startPoint: .top, endPoint: .bottom))
            LineMark(x: .value(axe, p.0), y: .value("Précision", apparu ? p.1 : 0))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Self.bleu)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
        }
        .chartYScale(domain: 0...100)
        .frame(height: 160)
    }
}

// MARK: - Points d'amélioration

struct CarteAmelioration: View {
    let analyse: AnalyseStats

    var body: some View {
        let classees = analyse.specialitesClassees
        CarteFiche(titre: "Points d'amélioration", icone: "lightbulb.max.fill", accent: Charte.or) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(analyse.conseils.enumerated()), id: \.offset) { i, conseil in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkle")
                            .foregroundStyle(Charte.or)
                            .symbolEffect(.pulse, options: .repeating.speed(0.5))
                        Text(conseil)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Charte.ivoire)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .transition(.opacity)
                }
                if !classees.isEmpty {
                    Text("À travailler")
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(BarreResultats.rouge)
                    ForEach(Array(classees.prefix(3).enumerated()), id: \.offset) { _, e in
                        LigneTrouveManque(nom: e.ligne.nom, sousTitre: e.chemin, score: e.ligne.score)
                    }
                    if classees.count > 3 {
                        Text("Points forts")
                            .font(.nom(14, relativeTo: .subheadline))
                            .foregroundStyle(BarreResultats.vert)
                        ForEach(Array(classees.suffix(3).reversed().enumerated()), id: \.offset) { _, e in
                            LigneTrouveManque(nom: e.ligne.nom, sousTitre: e.chemin, score: e.ligne.score)
                        }
                    }
                } else {
                    Text("Réponds à au moins 3 questions d'une spécialité pour qu'elle apparaisse ici.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Ligne « trouvé / manqué » des exercices tactiques de Chess.com, appliquée à une spécialité.
struct LigneTrouveManque: View {
    let nom: String
    var picto: String = ""
    var sousTitre: String? = nil
    let score: Score

    @State private var deploye = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(picto.isEmpty ? nom : "\(picto) \(nom)")
                    .font(.nom(15, relativeTo: .subheadline))
                    .foregroundStyle(Charte.ivoire)
                Text("\(score.total)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if let sousTitre {
                Text(sousTitre).font(.caption2).foregroundStyle(.secondary)
            }
            HStack {
                Label(String(format: "%.1f %%", score.precision), systemImage: "checkmark.square.fill")
                    .foregroundStyle(BarreResultats.vert)
                Spacer()
                Label(String(format: "%.1f %%", 100 - score.precision), systemImage: "xmark.square.fill")
                    .labelStyle(InverseLabelStyle())
                    .foregroundStyle(BarreResultats.rouge)
            }
            .font(.titre(15).monospacedDigit())
            GeometryReader { geo in
                let part = CGFloat(score.total > 0 ? Double(score.bonnes) / Double(score.total) : 0)
                ZStack(alignment: .leading) {
                    Capsule().fill(BarreResultats.rouge)
                    Capsule().fill(BarreResultats.vert).frame(width: deploye ? geo.size.width * part : 0)
                }
            }
            .frame(height: 6)
            HStack {
                Text("\(score.bonnes)")
                Spacer()
                Text("\(score.manquees)")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .onAppear { withAnimation(.spring(duration: 0.9).delay(0.2)) { deploye = true } }
    }
}

struct InverseLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
    }
}

// MARK: - Domaines → familles → spécialités

struct CarteDomaines: View {
    let domaines: [LigneScore]
    @State private var ouverts: Set<String> = []
    @State private var apparu = false

    var body: some View {
        CarteFiche(titre: "Par domaine", icone: "square.grid.3x3.fill", accent: Charte.or) {
            VStack(alignment: .leading, spacing: 14) {
                Chart(domaines) { d in
                    BarMark(x: .value("Précision", apparu ? d.score.precision : 0),
                            y: .value("Domaine", "\(d.picto) \(d.nom)"))
                        .foregroundStyle(couleur(d.nom).gradient)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            Text(String(format: "%.0f %%", d.score.precision))
                                .font(.caption2.bold())
                                .foregroundStyle(Charte.ivoire)
                        }
                }
                .chartXScale(domain: 0...110)
                .chartXAxis(.hidden)
                .frame(height: CGFloat(max(1, domaines.count)) * 36 + 10)
                Text("Touche un domaine pour voir ses familles et ses spécialités")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ForEach(domaines) { d in
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation(.snappy) { basculer(d.id) }
                        } label: {
                            HStack {
                                LigneTrouveManque(nom: d.nom, picto: d.picto, score: d.score)
                                Image(systemName: "chevron.down")
                                    .rotationEffect(.degrees(ouverts.contains(d.id) ? 180 : 0))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        if ouverts.contains(d.id) {
                            ForEach(d.enfants) { f in
                                VStack(alignment: .leading, spacing: 4) {
                                    Button {
                                        withAnimation(.snappy) { basculer(f.id) }
                                    } label: {
                                        HStack {
                                            LigneTrouveManque(nom: f.nom, picto: f.picto, score: f.score)
                                            Image(systemName: "chevron.down")
                                                .rotationEffect(.degrees(ouverts.contains(f.id) ? 180 : 0))
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    if ouverts.contains(f.id) {
                                        ForEach(f.enfants) { s in
                                            LigneTrouveManque(nom: s.nom, score: s.score)
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .padding(.leading, 14)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        Divider().overlay(Color.white.opacity(0.1))
                    }
                }
            }
        }
        .onAppear { withAnimation(.spring(duration: 1.0).delay(0.3)) { apparu = true } }
    }

    private func basculer(_ id: String) {
        if ouverts.contains(id) { ouverts.remove(id) } else { ouverts.insert(id) }
    }

    private func couleur(_ domaine: String) -> Color {
        Specialite(id: "", nom: "", famille: "", domaine: domaine).couleur
    }
}

// MARK: - Rapidité

struct CarteRapidite: View {
    let analyse: AnalyseStats
    @State private var revele = false

    var body: some View {
        let parts = analyse.repartitionRapidite.filter { $0.nombre > 0 }
        let total = max(1, parts.reduce(0) { $0 + $1.nombre })
        CarteFiche(titre: "Formes de tes réponses", icone: "bolt.circle.fill", accent: Appreciation.brillante.couleur) {
            VStack(alignment: .leading, spacing: 12) {
                Chart(parts, id: \.appreciation) { p in
                    SectorMark(angle: .value("Réponses", revele ? Double(p.nombre) : 0.0001),
                               innerRadius: .ratio(0.58), angularInset: 2)
                        .cornerRadius(5)
                        .foregroundStyle(p.appreciation.couleur)
                }
                .chartBackground { _ in
                    VStack(spacing: 0) {
                        Text(String(format: "%.1f s", analyse.tempsMoyen))
                            .font(.titre(22))
                            .foregroundStyle(Charte.ivoire)
                        Text("temps moyen")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
                ForEach(parts, id: \.appreciation) { p in
                    HStack(spacing: 8) {
                        PastilleAppreciation(appreciation: p.appreciation, taille: 22)
                        Text(p.appreciation.nom).font(.subheadline).foregroundStyle(Charte.ivoire)
                        Spacer()
                        Text(String(format: "%.1f %%", Double(p.nombre) / Double(total) * 100))
                            .font(.subheadline.monospacedDigit().bold())
                            .foregroundStyle(p.appreciation.couleur)
                    }
                }
            }
        }
        .onAppear { withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.3)) { revele = true } }
    }
}

// MARK: - Difficulté et niveau de l'IA

struct CarteDifficulte: View {
    let analyse: AnalyseStats
    @State private var apparu = false

    var body: some View {
        CarteFiche(titre: "Précision par difficulté", icone: "chart.bar.fill", accent: Charte.or) {
            Chart(analyse.precisionParDifficulte, id: \.difficulte) { d in
                BarMark(x: .value("Difficulté", "\(d.difficulte)"),
                        y: .value("Précision", apparu ? d.score.precision : 0))
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.36, green: 0.66, blue: 0.85),
                                                             Color(red: 0.16, green: 0.34, blue: 0.48)],
                                                    startPoint: .top, endPoint: .bottom))
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", d.score.precision))
                            .font(.caption2.bold())
                            .foregroundStyle(Charte.ivoire)
                    }
            }
            .chartYScale(domain: 0...110)
            .chartXAxisLabel("Difficulté de la question")
            .frame(height: 180)
        }
        .onAppear { withAnimation(.spring(duration: 1.0).delay(0.3)) { apparu = true } }
    }
}

struct CarteNiveauxIA: View {
    let analyse: AnalyseStats
    @State private var apparu = false

    var body: some View {
        CarteFiche(titre: "Résultats selon le niveau de l'IA", icone: "cpu.fill", accent: Charte.or) {
            Chart(Array(analyse.resultatsParNiveau.enumerated()), id: \.offset) { _, r in
                BarMark(x: .value("Niveau", r.niveau),
                        y: .value("Parties", apparu ? r.nombre : 0),
                        stacking: .normalized)
                    .foregroundStyle(by: .value("Résultat", r.resultat))
            }
            .chartForegroundStyleScale(["Victoires": BarreResultats.vert,
                                        "Nuls": BarreResultats.gris,
                                        "Défaites": BarreResultats.rouge])
            .chartYAxis {
                AxisMarks(values: [0, 0.25, 0.5, 0.75, 1]) { v in
                    AxisGridLine()
                    AxisValueLabel { Text("\(Int((v.as(Double.self) ?? 0) * 100)) %") }
                }
            }
            .frame(height: 200)
        }
        .onAppear { withAnimation(.spring(duration: 1.0).delay(0.3)) { apparu = true } }
    }
}
