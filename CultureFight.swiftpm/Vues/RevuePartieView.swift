import SwiftUI

// Revue de partie, à la manière de l'analyse d'une partie d'échecs sur Chess.com :
// chaque question du combat reçoit une appréciation, la précision du joueur est calculée,
// et les questions ratées peuvent être refaites dans un entraînement sans chrono ni dégâts.

/// Appréciation d'une réponse, comme les annotations d'un coup aux échecs.
enum Appreciation: CaseIterable, Sendable {
    case brillante, excellente, bonne, erreur, tempsEcoule

    init(_ tour: ResultatTour) {
        if tour.reponse == nil { self = .tempsEcoule }
        else if !tour.correct { self = .erreur }
        else {
            switch tour.vitesse {
            case .eclair: self = .brillante
            case .rapide: self = .excellente
            case .normale: self = .bonne
            }
        }
    }

    var nom: String {
        switch self {
        case .brillante: return "Éclair"
        case .excellente: return "Rapide"
        case .bonne: return "Bonne"
        case .erreur: return "Erreur"
        case .tempsEcoule: return "Temps écoulé"
        }
    }

    /// Annotation à la manière des échecs.
    var symbole: String {
        switch self {
        case .brillante: return "!!"
        case .excellente: return "!"
        case .bonne: return "✓"
        case .erreur: return "?"
        case .tempsEcoule: return "??"
        }
    }

    var couleur: Color {
        switch self {
        case .brillante: return Color(red: 0.15, green: 0.80, blue: 0.85)
        case .excellente: return Color(red: 0.45, green: 0.80, blue: 0.30)
        case .bonne: return Color(red: 0.55, green: 0.70, blue: 0.45)
        case .erreur: return Color(red: 0.95, green: 0.55, blue: 0.20)
        case .tempsEcoule: return Color(red: 0.90, green: 0.25, blue: 0.25)
        }
    }

    var estRatee: Bool { self == .erreur || self == .tempsEcoule }
}

enum Revue {
    /// Les questions auxquelles le joueur a mal répondu ou n'a pas répondu à temps.
    static func aRefaire(_ historique: [ResultatTour]) -> [ResultatTour] {
        historique.filter { $0.defenseurEstJoueur && Appreciation($0).estRatee }
    }

    /// Pourcentage de bonnes réponses du joueur (ou de l'IA).
    static func precision(_ historique: [ResultatTour], joueur: Bool) -> Int {
        let tours = historique.filter { $0.defenseurEstJoueur == joueur }
        guard !tours.isEmpty else { return 0 }
        return Int((Double(tours.filter(\.correct).count) / Double(tours.count) * 100).rounded())
    }

    static func compte(_ historique: [ResultatTour], joueur: Bool) -> [Appreciation: Int] {
        var compte: [Appreciation: Int] = [:]
        for tour in historique where tour.defenseurEstJoueur == joueur {
            compte[Appreciation(tour), default: 0] += 1
        }
        return compte
    }
}

struct RevuePartieView: View {
    let historique: [ResultatTour]

    @Environment(\.dismiss) private var fermer
    @State private var filtre = Filtre.aRefaire
    @State private var entrainement = false

    enum Filtre: Hashable { case aRefaire, miennes, toutes }

    private var aRefaire: [ResultatTour] { Revue.aRefaire(historique) }

    private var tours: [(numero: Int, tour: ResultatTour)] {
        let tous = Array(historique.enumerated()).map { (numero: $0.offset + 1, tour: $0.element) }
        switch filtre {
        case .aRefaire: return tous.filter { $0.tour.defenseurEstJoueur && Appreciation($0.tour).estRatee }
        case .miennes: return tous.filter { $0.tour.defenseurEstJoueur }
        case .toutes: return tous
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        JaugePrecision(titre: "Toi", valeur: Revue.precision(historique, joueur: true),
                                       couleur: Charte.or)
                        JaugePrecision(titre: "IA", valeur: Revue.precision(historique, joueur: false),
                                       couleur: Color.blue)
                    }
                    resume
                    if !aRefaire.isEmpty {
                        Button {
                            entrainement = true
                        } label: {
                            Label("Refaire les \(aRefaire.count) question\(aRefaire.count > 1 ? "s" : "") ratée\(aRefaire.count > 1 ? "s" : "")",
                                  systemImage: "arrow.counterclockwise.circle.fill")
                                .font(.titre(17, relativeTo: .headline))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.orange)
                    }
                    Picker("Questions", selection: $filtre) {
                        Text("À refaire (\(aRefaire.count))").tag(Filtre.aRefaire)
                        Text("Mes réponses").tag(Filtre.miennes)
                        Text("Toutes").tag(Filtre.toutes)
                    }
                    .pickerStyle(.segmented)
                    if tours.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(Appreciation.brillante.couleur)
                                .symbolEffect(.bounce, value: filtre)
                            Text("Aucune question à refaire : partie sans faute !")
                                .font(.nom(15, relativeTo: .subheadline))
                                .foregroundStyle(Charte.ivoire)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(tours, id: \.numero) { element in
                            CarteTourRevue(numero: element.numero, tour: element.tour)
                        }
                    }
                }
                .padding()
                .animation(.snappy, value: filtre)
            }
            .background { FondFiche(accent: .cyan) }
            .navigationTitle("Revue de la partie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { fermer() }
                }
            }
            .fullScreenCover(isPresented: $entrainement) {
                EntrainementView(tours: aRefaire)
            }
        }
    }

    /// Nombre de réponses du joueur par appréciation, comme le tableau d'une revue d'échecs.
    private var resume: some View {
        let compte = Revue.compte(historique, joueur: true)
        return HStack(spacing: 6) {
            ForEach(Appreciation.allCases, id: \.self) { a in
                VStack(spacing: 4) {
                    PastilleAppreciation(appreciation: a, taille: 30)
                    Text("\(compte[a, default: 0])")
                        .font(.titre(18))
                        .foregroundStyle(Charte.ivoire)
                    Text(a.nom)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(10)
        .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Charte.or.opacity(0.3), lineWidth: 1))
    }
}

/// Jauge circulaire de précision, qui se remplit à l'ouverture.
struct JaugePrecision: View {
    let titre: String
    let valeur: Int
    let couleur: Color

    @State private var rempli = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: rempli ? Double(valeur) / 100 : 0)
                    .stroke(couleur.gradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(rempli ? valeur : 0) %")
                    .font(.titre(22))
                    .foregroundStyle(Charte.ivoire)
                    .contentTransition(.numericText(value: Double(rempli ? valeur : 0)))
            }
            .frame(width: 96, height: 96)
            Text("Précision · \(titre)")
                .font(.nom(13, relativeTo: .caption))
                .foregroundStyle(couleur)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.2).delay(0.2)) { rempli = true }
        }
    }
}

struct PastilleAppreciation: View {
    let appreciation: Appreciation
    var taille: CGFloat = 26

    var body: some View {
        Text(appreciation.symbole)
            .font(.system(size: taille * 0.45, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: taille, height: taille)
            .background(appreciation.couleur, in: Circle())
    }
}

/// Une question du combat, avec la réponse donnée, la bonne réponse et l'explication.
struct CarteTourRevue: View {
    let numero: Int
    let tour: ResultatTour

    @State private var ouverte = false

    private var appreciation: Appreciation { Appreciation(tour) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { ouverte.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    PastilleAppreciation(appreciation: appreciation)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tour \(numero) · \(tour.defenseurEstJoueur ? "Ta réponse" : "Réponse de l'IA") · \(tour.defenseurNom)")
                            .font(.nom(11, relativeTo: .caption2))
                            .foregroundStyle(appreciation.couleur)
                        Text(tour.question.enonce)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Charte.ivoire)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(ouverte ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            if ouverte {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(tour.question.choix.enumerated()), id: \.offset) { index, choix in
                        let bonne = index == tour.question.bonneReponse
                        let choisie = index == tour.reponse
                        HStack(spacing: 8) {
                            Image(systemName: bonne ? "checkmark.circle.fill" : (choisie ? "xmark.circle.fill" : "circle"))
                                .foregroundStyle(bonne ? Color.green : (choisie ? Color.red : Color.secondary))
                            Text(choix)
                                .font(.subheadline.weight(bonne ? .bold : .regular))
                                .foregroundStyle(Charte.ivoire.opacity(bonne || choisie ? 1 : 0.7))
                        }
                    }
                    if tour.reponse == nil {
                        Text("Pas de réponse avant la fin du chrono.")
                            .font(.caption)
                            .foregroundStyle(Appreciation.tempsEcoule.couleur)
                    }
                    if !tour.question.explication.isEmpty {
                        Text(tour.question.explication)
                            .font(.system(.footnote, design: .serif))
                            .foregroundStyle(Charte.ivoire.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 4)
                    }
                }
                .padding(.leading, 36)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(appreciation.couleur.opacity(0.5), lineWidth: 1))
        .onAppear { if appreciation.estRatee { ouverte = true } }
    }
}

// MARK: - Entraînement sur les questions ratées

struct EntrainementView: View {
    let tours: [ResultatTour]

    @Environment(\.dismiss) private var fermer
    @State private var file: [Question] = []
    @State private var index = 0
    @State private var ordre: [Int] = []
    @State private var choisie: Int?
    @State private var reussies = 0
    @State private var ratees: [Question] = []

    private var question: Question? { index < file.count ? file[index] : nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let question {
                    ProgressView(value: Double(index), total: Double(file.count))
                        .tint(Charte.or)
                    Text("Question \(index + 1) sur \(file.count)")
                        .font(.nom(13, relativeTo: .caption))
                        .foregroundStyle(.secondary)
                    Text(question.enonce)
                        .font(.title3.bold())
                        .foregroundStyle(Charte.ivoire)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .id(index)
                        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                    VStack(spacing: 10) {
                        ForEach(ordre, id: \.self) { i in
                            boutonChoix(question: question, index: i)
                        }
                    }
                    if choisie != nil {
                        Text(question.explication)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Charte.ivoire.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                        Button(index + 1 < file.count ? "Suivante" : "Voir le score") { suivante() }
                            .font(.titre(18, relativeTo: .headline))
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }
                    Spacer()
                } else {
                    fin
                }
            }
            .padding()
            .animation(.spring(duration: 0.4), value: index)
            .animation(.snappy, value: choisie)
            .background { FondFiche(accent: Charte.or) }
            .navigationTitle("Entraînement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { fermer() }
                }
            }
            .onAppear { demarrer(tours.map(\.question)) }
            .sensoryFeedback(trigger: choisie) { _, nouvelle in
                guard let nouvelle, let question else { return nil }
                return nouvelle == question.bonneReponse ? .success : .error
            }
        }
    }

    private func boutonChoix(question: Question, index i: Int) -> some View {
        let bonne = i == question.bonneReponse
        let estChoisie = i == choisie
        let fond: Color = choisie == nil ? Charte.marine.opacity(0.8)
            : (bonne ? Color.green.opacity(0.35) : (estChoisie ? Color.red.opacity(0.35) : Charte.marine.opacity(0.5)))
        return Button {
            guard choisie == nil else { return }
            choisie = i
            if bonne { reussies += 1 } else { ratees.append(question) }
        } label: {
            Text(question.choix[i])
                .font(.body.weight(.semibold))
                .foregroundStyle(Charte.ivoire)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(fond, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Charte.or.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(choisie != nil)
    }

    private var fin: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: ratees.isEmpty ? "star.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(ratees.isEmpty ? Charte.or : Color.orange)
                .symbolEffect(.bounce, value: reussies)
            Text("\(reussies) / \(file.count)")
                .font(.titre(40, relativeTo: .largeTitle))
                .lettrageLogo()
            Text(ratees.isEmpty ? "Toutes les questions sont acquises !" : "Encore \(ratees.count) à revoir.")
                .font(.nom(16, relativeTo: .body))
                .foregroundStyle(Charte.ivoire)
            if !ratees.isEmpty {
                Button("Refaire les ratées") { demarrer(ratees) }
                    .font(.titre(18, relativeTo: .headline))
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
            Button("Terminer") { fermer() }
                .font(.nom(16, relativeTo: .body))
            Spacer()
        }
    }

    private func demarrer(_ questions: [Question]) {
        var vues = Set<String>()
        file = questions.filter { vues.insert($0.id).inserted }.shuffled()
        index = 0
        reussies = 0
        ratees = []
        preparer()
    }

    private func suivante() {
        index += 1
        preparer()
    }

    /// Mélange l'ordre des choix pour ne pas retenir seulement la position de la bonne réponse.
    private func preparer() {
        choisie = nil
        if let question { ordre = Array(question.choix.indices).shuffled() }
    }
}
