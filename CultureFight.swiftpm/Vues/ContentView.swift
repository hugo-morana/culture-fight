import SwiftUI
import SwiftData
import UIKit

@main
struct CultureFightApp: App {
    init() { Charte.installer() }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(Sauvegarde.conteneur)
    }
}

struct ContentView: View {
    enum Ecran {
        case accueil
        case selection
        case collection
        case profil
        case boutique
        case carte
        case combat(CombatController)
    }

    @State private var ecran: Ecran = .accueil
    @State private var joueur: Joueur?
    /// Légendaires qui viennent de rejoindre la réserve (domaine complet), à annoncer.
    @State private var nouveauxLegendaires: [ModeleCombattant] = []
    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let joueur {
                ecranCourant(joueur)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if joueur == nil { joueur = Sauvegarde.joueur(dans: contexte) }
            ServiceSons.partage.precharger()
            verifierLegendaires()
        }
        .onChange(of: joueur?.reserve.count ?? 0) { _, _ in verifierLegendaires() }
        .alert(titreLegendaire, isPresented: Binding(
            get: { !nouveauxLegendaires.isEmpty }, set: { if !$0 { nouveauxLegendaires = [] } })) {
            Button("Génial !") { nouveauxLegendaires = [] }
        } message: {
            Text(nouveauxLegendaires.map { "\($0.nom), Légendaire du domaine \($0.specialite.domaine), rejoint ta réserve. Il pose des questions de tout le domaine." }
                .joined(separator: "\n"))
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { Sauvegarde.enregistrer(contexte) }
            ServiceAudio.partage.premierPlan(phase == .active)
        }
        .onChange(of: enCombat, initial: true) { _, combat in
            ServiceAudio.partage.entrer(combat ? .combat : .menus)
        }
        .onChange(of: nomEcran) { _, nouveau in
            // Navigation : clic en avant, son de retour vers l'accueil ; le combat a ses propres sons.
            switch nouveau {
            case "accueil": ServiceSons.partage.jouer(.retour)
            case "combat": break
            default: ServiceSons.partage.jouer(.tap)
            }
        }
    }

    private var titreLegendaire: String {
        nouveauxLegendaires.count > 1 ? "Domaines complets !" : "Domaine complet !"
    }

    private func verifierLegendaires() {
        guard let joueur else { return }
        let arrives = joueur.attribuerLegendaires()
        if !arrives.isEmpty {
            Sauvegarde.enregistrer(contexte)
            nouveauxLegendaires = arrives
        }
    }

    private var nomEcran: String {
        switch ecran {
        case .accueil: return "accueil"
        case .selection: return "selection"
        case .collection: return "collection"
        case .profil: return "profil"
        case .boutique: return "boutique"
        case .carte: return "carte"
        case .combat: return "combat"
        }
    }

    /// Le thème de combat joue pendant le combat, le thème principal partout ailleurs.
    private var enCombat: Bool {
        if case .combat = ecran { return true }
        return false
    }

    @ViewBuilder
    private func ecranCourant(_ joueur: Joueur) -> some View {
        switch ecran {
        case .accueil:
            AccueilView(pieces: joueur.pieces,
                        niveau: joueur.niveauCompte,
                        xp: joueur.xpCompte,
                        seuil: joueur.seuilNiveauSuivant,
                        prochainCoffre: Gains.prochainCoffre(apres: joueur.dernierCoffre),
                        ouvrirCoffre: { Sauvegarde.ouvrirCoffre(joueur, dans: contexte) },
                        combattre: { ecran = .selection },
                        collection: { ecran = .collection },
                        boutique: { ecran = .boutique },
                        profil: { ecran = .profil },
                        carte: { ecran = .carte })
        case .collection:
            CollectionView(retour: { ecran = .accueil })
        case .profil:
            ProfilView(joueur: joueur, retour: { ecran = .accueil })
        case .carte:
            CarteCulturiaView(retour: { ecran = .accueil })
        case .boutique:
            BoutiqueView(joueur: joueur, retour: { ecran = .accueil })
        case .selection:
            SelectionEquipeView(reserve: joueur.modelesReserve, niveaux: joueur.niveaux, retour: { ecran = .accueil }) { equipe, niveau in
                let ia = IAAdverse(niveau: niveau)
                let adverse = ia.choisirEquipe(parmi: Catalogue.prototype)
                ecran = .combat(CombatController(equipeJoueur: equipe, equipeIA: adverse, ia: ia,
                                                 profils: joueur.profils, niveaux: joueur.niveaux,
                                                 equipements: joueur.equipements, consommables: joueur.inventaire,
                                                 bonusPV: joueur.bonusPV))
            }
        case .combat(let controleur):
            CombatView(controleur: controleur,
                       rejouer: { ecran = .selection },
                       accueil: { ecran = .accueil },
                       termine: { Sauvegarde.crediter(controleur, a: joueur, dans: contexte) },
                       abandonne: { Sauvegarde.abandon(controleur, de: joueur, dans: contexte) })
                .id(ObjectIdentifier(controleur))
        }
    }
}

struct AccueilView: View {
    let pieces: Int
    let niveau: Int
    let xp: Int
    let seuil: Int
    let prochainCoffre: Date
    let ouvrirCoffre: () -> Int?
    let combattre: () -> Void
    let collection: () -> Void
    let boutique: () -> Void
    let profil: () -> Void
    let carte: () -> Void

    @State private var apparu = false
    @State private var mentionsOuvertes = false

    var body: some View {
        ZStack {
            FondAnime()
            contenu
        }
        .onAppear { apparu = true }
        .sheet(isPresented: $mentionsOuvertes) {
            NavigationStack {
                MentionsLegalesView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") { mentionsOuvertes = false }
                        }
                    }
            }
        }
    }

    private var contenu: some View {
        VStack(spacing: 24) {
            HStack(alignment: .center) {
                Button(action: profil) {
                    JaugeNiveau(niveau: niveau, xp: xp, seuil: seuil)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Ouvre le profil et les statistiques")
                Spacer(minLength: 8)
                Label("\(pieces) Pièces", systemImage: "dollarsign.circle.fill")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityLabel("\(pieces) Pièces")
            }
            .opacity(apparu ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: apparu)
            Spacer()
            if let logo = Illustrations.partage.ressource("logo", type: "png") {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 360)
                    .phaseAnimator([false, true]) { vue, haut in
                        vue
                            .offset(y: haut ? -8 : 8)
                            .shadow(color: Color.blue.opacity(haut ? 0.9 : 0.35), radius: haut ? 28 : 10)
                    } animation: { _ in
                        .easeInOut(duration: 2.2)
                    }
                    .scaleEffect(apparu ? 1 : 0.6)
                    .opacity(apparu ? 1 : 0)
                    .animation(.spring(duration: 0.8, bounce: 0.4), value: apparu)
            } else {
                Text("Culture Fight")
                    .font(.titre(40, relativeTo: .largeTitle))
                    .lettrageLogo()
            }
            Text("Ton savoir est ton arme.")
                .font(.nom(19, relativeTo: .title3))
                .foregroundStyle(.secondary)
                .opacity(apparu ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: apparu)
            Spacer()
            Button(action: combattre) {
                Text("Combattre")
                    .font(.titre(22, relativeTo: .title3))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .offset(y: apparu ? 0 : 60)
            .opacity(apparu ? 1 : 0)
            .animation(.spring(duration: 0.6, bounce: 0.35).delay(0.5), value: apparu)
            HStack(spacing: 12) {
                Button(action: collection) {
                    Label("Collection", systemImage: "square.stack.3d.up.fill")
                        .font(.titre(17, relativeTo: .headline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Button(action: boutique) {
                    Label("Boutique", systemImage: "cart.fill")
                        .font(.titre(17, relativeTo: .headline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.yellow)
            }
            .offset(y: apparu ? 0 : 60)
            .opacity(apparu ? 1 : 0)
            .animation(.spring(duration: 0.6, bounce: 0.35).delay(0.62), value: apparu)
            HStack(spacing: 12) {
                Button(action: profil) {
                    Label("Profil", systemImage: "chart.xyaxis.line")
                        .font(.titre(17, relativeTo: .headline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(Charte.or)
                .accessibilityLabel("Profil et statistiques")
                Button(action: carte) {
                    Label("Carte", systemImage: "map.fill")
                        .font(.titre(17, relativeTo: .headline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.teal)
                .accessibilityLabel("Carte de Culturia")
            }
            .opacity(apparu ? 1 : 0)
            .animation(.spring(duration: 0.6, bounce: 0.35).delay(0.7), value: apparu)
            BoutonCoffre(prochain: prochainCoffre, ouvrir: ouvrirCoffre)
                .opacity(apparu ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.75), value: apparu)
            Text("Prototype · \(Catalogue.prototype.count) combattants · combat contre l'IA")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button { mentionsOuvertes = true } label: {
                Text("© \(MentionsLegalesView.annees) Hugo Morana · Tous droits réservés")
                    .font(.caption2)
                    .foregroundStyle(Charte.ivoire.opacity(0.6))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Ouvre les mentions légales et crédits")
            .opacity(apparu ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.8), value: apparu)
        }
        .padding(32)
    }
}

// MARK: - Éléments communs

extension Specialite {
    /// Une couleur par domaine.
    var couleur: Color {
        switch domaine {
        case "Matière": return .orange
        case "Univers": return .indigo
        case "Terre": return .brown
        case "Vivant": return .green
        case "Corps humain": return .pink
        case "Monde": return .teal
        case "Histoire": return .red
        case "Arts": return .purple
        case "Lettres et mythes": return .yellow
        default: return .blue
        }
    }
}

/// Illustrations des combattants (`Resources/combattant-<id>.jpg`), chargées une fois.
final class Illustrations: @unchecked Sendable {
    static let partage = Illustrations()
    private let cache = NSCache<NSString, UIImage>()

    /// Illustration du combattant, ou sa tenue alternative si le joueur la porte.
    func image(pour id: String) -> UIImage? {
        if Tenues.portee(id), let tenue = ressource("tenue-\(id)", type: "jpg") { return tenue }
        return ressource("combattant-\(id)", type: "jpg")
    }

    /// Une image des ressources de l'app (illustration, logo…), gardée en cache.
    func ressource(_ nom: String, type ext: String) -> UIImage? {
        let cle = "\(nom).\(ext)" as NSString
        if let image = cache.object(forKey: cle) { return image }
        let url = Bundle.module.url(forResource: nom, withExtension: ext)
            ?? Bundle.main.url(forResource: nom, withExtension: ext)
        guard let url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: cle)
        return image
    }
}

/// Portrait du combattant : son illustration, ou ses initiales s'il n'en a pas encore.
struct Avatar: View {
    let modele: ModeleCombattant
    var taille: CGFloat = 48

    var body: some View {
        if let image = Illustrations.partage.image(pour: modele.id) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: taille, height: taille, alignment: .top)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: taille * 0.22))
                .overlay(RoundedRectangle(cornerRadius: taille * 0.22)
                    .stroke(modele.specialite.couleur, lineWidth: 2))
        } else {
            ZStack {
                Circle().fill(modele.specialite.couleur.gradient)
                Text(modele.initiales)
                    .font(.titre(taille * 0.36))
                    .foregroundStyle(.white)
            }
            .frame(width: taille, height: taille)
        }
    }
}

struct BarrePV: View {
    let pv: Int
    let pvMax: Int

    private var ratio: Double { pvMax > 0 ? Double(max(0, pv)) / Double(pvMax) : 0 }
    private var couleur: Color { ratio > 0.5 ? .green : (ratio > 0.25 ? .yellow : .red) }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(couleur).frame(width: geo.size.width * ratio)
            }
        }
        .frame(height: 8)
        .animation(.easeOut(duration: 0.4), value: pv)
    }
}

/// Coffre gratuit de l'accueil : 20 à 60 Pièces toutes les 4 heures.
struct BoutonCoffre: View {
    let prochain: Date
    let ouvrir: () -> Int?

    @State private var gain: Int?
    @State private var envol = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { contexte in
            let pret = contexte.date >= prochain
            Button {
                guard let pieces = ouvrir() else { return }
                gain = pieces
                envol = false
                withAnimation(.easeOut(duration: 1.4)) { envol = true }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: pret ? "gift.fill" : "gift")
                        .symbolEffect(.pulse, isActive: pret)
                    Text(pret ? "Ouvrir le coffre gratuit" : "Coffre dans \(Self.attente(jusqua: prochain, depuis: contexte.date))")
                        .font(.nom(15, relativeTo: .subheadline))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(pret ? Charte.or : .gray)
            .disabled(!pret)
        }
        .overlay {
            if let gain {
                Text("+\(gain) Pièces")
                    .font(.titre(26))
                    .foregroundStyle(.yellow)
                    .shadow(color: .black.opacity(0.6), radius: 3)
                    .offset(y: envol ? -90 : 0)
                    .opacity(envol ? 0 : 1)
                    .scaleEffect(envol ? 1.4 : 0.8)
                    .allowsHitTesting(false)
            }
        }
        .sensoryFeedback(.success, trigger: gain)
        .onChange(of: gain) { _, nouveau in
            if nouveau != nil { ServiceSons.partage.jouer(.pieces) }
        }
    }

    /// « 3 h 05 min », « 12 min 40 s ».
    static func attente(jusqua fin: Date, depuis maintenant: Date) -> String {
        let reste = max(0, Int(fin.timeIntervalSince(maintenant)))
        let h = reste / 3600, m = (reste % 3600) / 60, s = reste % 60
        if h > 0 { return String(format: "%d h %02d min", h, m) }
        return String(format: "%d min %02d s", m, s)
    }
}
