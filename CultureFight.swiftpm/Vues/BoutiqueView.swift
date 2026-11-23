import SwiftUI
import SwiftData
import Combine

/// Ordre du catalogue des Communs. Le choix est mémorisé.
enum TriBoutique: String, CaseIterable, Identifiable {
    case catalogue, prixCroissant, prixDecroissant, nom

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .catalogue: "Par domaine"
        case .prixCroissant: "Prix croissant"
        case .prixDecroissant: "Prix décroissant"
        case .nom: "Nom (A → Z)"
        }
    }

    var icone: String {
        switch self {
        case .catalogue: "square.grid.2x2"
        case .prixCroissant: "arrow.up"
        case .prixDecroissant: "arrow.down"
        case .nom: "textformat"
        }
    }
}

/// La boutique : l'offre du jour (4 articles, à partir du niveau 3), le catalogue des Communs et l'inventaire.
/// Le catalogue se cherche comme la collection (même recherche sans accents), se filtre par domaine,
/// se trie et peut masquer les combattants déjà possédés.
struct BoutiqueView: View {
    let joueur: Joueur
    let retour: () -> Void

    @Environment(\.modelContext) private var contexte
    @State private var aConfirmer: (article: Boutique.Article, offre: Bool)?
    @State private var dernierAchat: Boutique.ResultatAchat?
    @State private var fete = 0
    @State private var maintenant = Date()
    @State private var fiche: ModeleCombattant?
    /// Domaine filtré dans le catalogue des Communs ; nil = tous.
    @State private var filtreDomaine: String?
    @State private var recherche = ""
    @AppStorage("boutique.tri") private var tri: TriBoutique = .catalogue
    @AppStorage("boutique.masquerPossedes") private var masquerPossedes = false

    /// Communs retenus par la recherche, le domaine et le filtre « possédés », dans l'ordre choisi.
    private var communsAffiches: [ModeleCombattant] {
        let texte = recherche.trimmingCharacters(in: .whitespaces)
        let retenus = Boutique.communs.filter { modele in
            (filtreDomaine == nil || modele.specialite.domaine == filtreDomaine)
                && (texte.isEmpty || modele.correspond(a: texte))
                && !(masquerPossedes && joueur.possede(modele.id))
        }
        let prix = { (m: ModeleCombattant) in Boutique.prix(m) }
        switch tri {
        case .catalogue: return retenus
        case .prixCroissant: return retenus.sorted { prix($0) < prix($1) }
        case .prixDecroissant: return retenus.sorted { prix($0) > prix($1) }
        case .nom: return retenus.sorted { $0.nom.localizedStandardCompare($1.nom) == .orderedAscending }
        }
    }

    private let colonnes = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private let horloge = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var offre: [Boutique.Article] { Boutique.offreDuJour(maintenant) }
    private var offreOuverte: Bool { joueur.niveauCompte >= Boutique.niveauOffreDuJour }

    private func dejaAchete(_ article: Boutique.Article) -> Bool {
        joueur.jourAchats == Boutique.cleJour(maintenant) && joueur.achatsDuJour.contains(article.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    soldePieces
                    // Pendant une recherche, seul le catalogue reste, pour voir les résultats tout de suite.
                    if recherche.isEmpty { sectionOffre }
                    sectionCommuns
                    if recherche.isEmpty { sectionInventaire }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.immediately)
            .background { FondFiche(accent: .yellow) }
            .overlay {
                if fete > 0 {
                    Confettis().ignoresSafeArea().allowsHitTesting(false).id(fete)
                }
            }
            .navigationTitle("Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $recherche, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Chercher un combattant à acheter")
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Trier", selection: $tri) {
                            ForEach(TriBoutique.allCases) { choix in
                                Label(choix.titre, systemImage: choix.icone).tag(choix)
                            }
                        }
                        Toggle(isOn: $masquerPossedes) {
                            Label("Masquer les possédés", systemImage: "eye.slash")
                        }
                    } label: {
                        Label("Trier et filtrer", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .sensoryFeedback(.selection, trigger: tri)
                }
            }
            .onReceive(horloge) { maintenant = $0 }
            .sheet(item: $fiche) { modele in FicheCombattantView(modele: modele) }
            .sensoryFeedback(.success, trigger: fete)
            .confirmationDialog(titreConfirmation, isPresented: Binding(
                get: { aConfirmer != nil }, set: { if !$0 { aConfirmer = nil } }), titleVisibility: .visible) {
                if let choix = aConfirmer {
                    Button("Acheter pour \(Boutique.prixPaye(choix.article, offreDuJour: choix.offre, date: maintenant)) Pièces") { acheter(choix.article, offre: choix.offre) }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                if let choix = aConfirmer {
                    Text(Boutique.libelleAchat(choix.article, offreDuJour: choix.offre, pour: joueur))
                }
            }
            .alert(titreResultat, isPresented: Binding(
                get: { dernierAchat != nil }, set: { if !$0 { dernierAchat = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(messageResultat)
            }
        }
    }

    // MARK: Sections

    private var soldePieces: some View {
        HStack {
            Label("\(joueur.pieces) Pièces", systemImage: "dollarsign.circle.fill")
                .font(.titre(22, relativeTo: .title2).monospacedDigit())
                .foregroundStyle(.yellow)
                .contentTransition(.numericText(value: Double(joueur.pieces)))
                .animation(.snappy, value: joueur.pieces)
            Spacer()
            Text("\(joueur.reserve.count) combattants")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var sectionOffre: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                titreSection("Offre du jour", icone: "sparkles")
                Spacer()
                Label(tempsRestant, systemImage: "clock")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if offreOuverte {
                LazyVGrid(columns: colonnes, spacing: 12) {
                    ForEach(offre) { article in
                        CarteArticle(article: article,
                                     etat: etat(article, offre: true),
                                     possede: article.modele.map { joueur.possede($0.id) } ?? false,
                                     remise: Boutique.remise(article, jour: Boutique.cleJour(maintenant)),
                                     voirFiche: { fiche = article.modele }) {
                            aConfirmer = (article, true)
                        }
                    }
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill").font(.title2).foregroundStyle(Charte.or)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("S'ouvre au niveau \(Boutique.niveauOffreDuJour)")
                            .font(.nom(15, relativeTo: .headline))
                            .foregroundStyle(Charte.ivoire)
                        Text("Chaque jour, 2 combattants (Rares compris) et 2 objets tirés au sort.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var sectionCommuns: some View {
        VStack(alignment: .leading, spacing: 12) {
            titreSection("Combattants Communs", icone: "person.crop.rectangle.stack.fill")
            Text("Toujours en vente, de \(Boutique.fourchette(.commun).lowerBound) à \(Boutique.fourchette(.commun).upperBound) Pièces selon la puissance du combattant.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    PastilleDomaine(domaine: nil, actif: filtreDomaine == nil) {
                        withAnimation(.spring(duration: 0.35)) { filtreDomaine = nil }
                    }
                    ForEach(domainesCommuns, id: \.self) { d in
                        PastilleDomaine(domaine: d, actif: filtreDomaine == d) {
                            withAnimation(.spring(duration: 0.35)) { filtreDomaine = d }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            LazyVGrid(columns: colonnes, spacing: 12) {
                ForEach(communsAffiches) { modele in
                    let article = Boutique.Article.combattant(modele.id)
                    CarteArticle(article: article,
                                 etat: etat(article, offre: false),
                                 possede: joueur.possede(modele.id),
                                 voirFiche: { fiche = modele }) {
                        aConfirmer = (article, false)
                    }
                }
            }
            .animation(.snappy, value: communsAffiches.map(\.id))
            if communsAffiches.isEmpty {
                ContentUnavailableView(recherche.isEmpty ? "Aucun combattant" : "Aucun résultat",
                                       systemImage: recherche.isEmpty ? "checkmark.seal" : "magnifyingglass",
                                       description: Text(recherche.isEmpty
                                                         ? "Tu possèdes déjà tous les Communs de ce choix."
                                                         : "Aucun Commun en vente ne correspond à « \(recherche) »."))
            } else if !recherche.isEmpty || filtreDomaine != nil || masquerPossedes {
                Text("\(communsAffiches.count) combattant\(communsAffiches.count > 1 ? "s" : "") sur \(Boutique.communs.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Domaines des Communs en vente, dans l'ordre du catalogue.
    private var domainesCommuns: [String] {
        var vus: [String] = []
        for modele in Boutique.communs where !vus.contains(modele.specialite.domaine) {
            vus.append(modele.specialite.domaine)
        }
        return vus
    }

    private var sectionInventaire: some View {
        let possedes = Boutique.objets.filter { (joueur.inventaire[$0.id] ?? 0) > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            titreSection("Inventaire", icone: "bag.fill")
            if possedes.isEmpty {
                Text("Aucun objet pour l'instant : les équipements et les consommables apparaissent dans l'offre du jour.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(possedes) { objet in
                    HStack(spacing: 12) {
                        Image(systemName: objet.symbole)
                            .font(.title3)
                            .foregroundStyle(Charte.or)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(objet.nom).font(.nom(14, relativeTo: .subheadline)).foregroundStyle(Charte.ivoire)
                            Text("\(objet.genre.rawValue) · \(objet.effet)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("× \(joueur.inventaire[objet.id] ?? 0)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(Charte.ivoire)
                    }
                }
                Text("Les équipements se portent depuis la fiche d'un combattant ; les consommables s'utilisent en combat (2 par combat).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func titreSection(_ titre: String, icone: String) -> some View {
        Label(titre, systemImage: icone)
            .font(.titre(20, relativeTo: .title3))
            .foregroundStyle(Charte.or)
    }

    // MARK: État et achat

    private func etat(_ article: Boutique.Article, offre: Bool) -> CarteArticle.Etat {
        if offre && dejaAchete(article) { return .achete }
        if !offre, let modele = article.modele, joueur.possede(modele.id) { return .possede }
        return joueur.pieces >= Boutique.prixPaye(article, offreDuJour: offre, date: maintenant) ? .disponible : .tropCher
    }

    private var tempsRestant: String {
        let secondes = max(0, Int(Boutique.prochainRenouvellement(apres: maintenant).timeIntervalSince(maintenant)))
        return String(format: "%02d:%02d:%02d", secondes / 3600, secondes % 3600 / 60, secondes % 60)
    }

    private var titreConfirmation: String {
        aConfirmer.map { "Acheter \($0.article.nom) ?" } ?? ""
    }

    private func acheter(_ article: Boutique.Article, offre: Bool) {
        let resultat = Boutique.acheter(article, offreDuJour: offre, joueur: joueur, dans: contexte)
        dernierAchat = resultat
        switch resultat {
        case .refuse:
            ServiceSons.partage.jouer(.erreur)
            return
        case .nouveauCombattant:
            ServiceSons.partage.jouer(.achat)
            ServiceSons.partage.jouer(.nouveauCombattant, apres: 0.3)
        default:
            ServiceSons.partage.jouer(.achat)
        }
        fete += 1
    }

    private var titreResultat: String {
        switch dernierAchat {
        case .nouveauCombattant?: return "Nouveau combattant !"
        case .doublon?: return "Doublon converti en Savoir"
        case .objet?: return "Objet acheté"
        case .refuse?: return "Achat impossible"
        case nil: return ""
        }
    }

    private var messageResultat: String {
        switch dernierAchat {
        case .nouveauCombattant(let id)?:
            let nom = Catalogue.prototype.first { $0.id == id }?.nom ?? id
            return "\(nom) rejoint ta réserve. Tu peux l'aligner dès le prochain combat."
        case .doublon(let id, let xp, let niveaux)?:
            let nom = Catalogue.prototype.first { $0.id == id }?.nom ?? id
            return "Tu avais déjà \(nom) : il gagne \(xp) Savoir" + (niveaux > 0 ? " et monte de \(niveaux) niveau\(niveaux > 1 ? "x" : "")." : ".")
        case .objet(let id, let quantite)?:
            let nom = Boutique.objet(id)?.nom ?? id
            return "\(nom) × \(quantite) ajouté à ton inventaire."
        case .refuse(let raison)?:
            return raison
        case nil:
            return ""
        }
    }
}

// MARK: - Carte d'un article

struct CarteArticle: View {
    enum Etat { case disponible, tropCher, possede, achete }

    let article: Boutique.Article
    let etat: Etat
    let possede: Bool
    /// Réduction de l'offre du jour en %, nil au catalogue.
    var remise: Int? = nil
    /// Ouvre la fiche du combattant (nil pour un objet).
    var voirFiche: (() -> Void)? = nil
    let acheter: () -> Void

    private var accent: Color {
        article.modele?.rarete.couleur ?? Charte.or
    }

    var body: some View {
        VStack(spacing: 8) {
            visuel
                .overlay(alignment: .bottomTrailing) {
                    if article.modele != nil, voirFiche != nil {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Charte.ivoire, Charte.marine)
                            .offset(x: 10, y: 4)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { if article.modele != nil { voirFiche?() } }
                .accessibilityAddTraits(article.modele != nil ? .isButton : [])
                .accessibilityHint(article.modele != nil ? "Ouvre la fiche du combattant" : "")
            Text(article.nom)
                .font(.nom(14, relativeTo: .subheadline))
                .foregroundStyle(Charte.ivoire)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let accroche = article.modele?.accroche {
                Text(accroche)
                    .font(.system(.caption2, design: .serif).italic())
                    .foregroundStyle(Charte.or.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.85)
            }
            Text(sousTitre)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
            Button(action: acheter) {
                Group {
                    switch etat {
                    case .possede: Label("Possédé", systemImage: "checkmark")
                    case .achete: Label("Acheté", systemImage: "checkmark")
                    default:
                        if let remise {
                            HStack(spacing: 4) {
                                Text("\(article.prix)").strikethrough().foregroundStyle(.white.opacity(0.6)).font(.caption)
                                Label("\(Boutique.prixReduit(article.prix, remise: remise))",
                                      systemImage: "dollarsign.circle.fill")
                            }
                        } else {
                            Label("\(article.prix)", systemImage: "dollarsign.circle.fill")
                        }
                    }
                }
                .font(.subheadline.monospacedDigit().bold())
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(etat == .disponible ? .orange : .gray)
            .disabled(etat != .disponible)
        }
        .padding(12)
        .background(Charte.marine.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.6), lineWidth: 1.5))
        .opacity(etat == .possede || etat == .achete ? 0.6 : 1)
        .overlay(alignment: .topLeading) {
            if let remise, etat != .achete {
                Text("−\(remise) %")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.red.gradient, in: Capsule())
                    .rotationEffect(.degrees(-8))
                    .offset(x: -4, y: -6)
            }
        }
    }

    private var sousTitre: String {
        switch article {
        case .combattant:
            guard let modele = article.modele else { return "" }
            let base = "\(modele.rarete.rawValue) · \(modele.specialite.nom)"
            return possede && etat != .possede ? "\(base) · doublon → \(Boutique.xpDoublon(modele.rarete)) Savoir" : base
        case .objet(let objet):
            return "\(objet.genre.rawValue) · \(objet.effet)"
        }
    }

    @ViewBuilder
    private var visuel: some View {
        if let modele = article.modele {
            Avatar(modele: modele, taille: 84)
                .overlay(alignment: .topTrailing) {
                    Text(modele.rarete.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(modele.rarete.couleur, in: Capsule())
                        .offset(x: 8, y: -6)
                }
                .overlay(alignment: .bottomLeading) {
                    VignetteDomaine(domaine: modele.specialite.domaine, taille: 30)
                        .offset(x: -10, y: 6)
                        .accessibilityLabel(modele.specialite.domaine)
                }
        } else if case .objet(let objet) = article {
            Image(systemName: objet.symbole)
                .font(.system(size: 38))
                .foregroundStyle(Charte.or.gradient)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Charte.or.opacity(0.12)))
        }
    }
}
