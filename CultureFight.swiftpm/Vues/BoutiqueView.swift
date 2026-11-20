import SwiftUI
import SwiftData
import Combine

/// La boutique : l'offre du jour (4 articles, à partir du niveau 3), le catalogue des Communs et l'inventaire.
struct BoutiqueView: View {
    let joueur: Joueur
    let retour: () -> Void

    @Environment(\.modelContext) private var contexte
    @State private var aConfirmer: (article: Boutique.Article, offre: Bool)?
    @State private var dernierAchat: Boutique.ResultatAchat?
    @State private var fete = 0
    @State private var maintenant = Date()

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
                    sectionOffre
                    sectionCommuns
                    sectionInventaire
                }
                .padding()
            }
            .background { FondFiche(accent: .yellow) }
            .overlay {
                if fete > 0 {
                    Confettis().ignoresSafeArea().allowsHitTesting(false).id(fete)
                }
            }
            .navigationTitle("Boutique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
            }
            .onReceive(horloge) { maintenant = $0 }
            .sensoryFeedback(.success, trigger: fete)
            .confirmationDialog(titreConfirmation, isPresented: Binding(
                get: { aConfirmer != nil }, set: { if !$0 { aConfirmer = nil } }), titleVisibility: .visible) {
                if let choix = aConfirmer {
                    Button("Acheter pour \(choix.article.prix) Pièces") { acheter(choix.article, offre: choix.offre) }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                if let choix = aConfirmer {
                    Text(Boutique.libelleAchat(choix.article, pour: joueur))
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
                                     possede: article.modele.map { joueur.possede($0.id) } ?? false) {
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
            Text("Toujours en vente, \(Boutique.prix(.commun)) Pièces chacun.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: colonnes, spacing: 12) {
                ForEach(Boutique.communs) { modele in
                    let article = Boutique.Article.combattant(modele.id)
                    CarteArticle(article: article,
                                 etat: etat(article, offre: false),
                                 possede: joueur.possede(modele.id)) {
                        aConfirmer = (article, false)
                    }
                }
            }
        }
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
                Text("Les objets s'équipent et s'utilisent en combat avec la prochaine mise à jour (tâche 25).")
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
        return joueur.pieces >= article.prix ? .disponible : .tropCher
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
        case .doublon?: return "Doublon converti en XP"
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
            return "Tu avais déjà \(nom) : il gagne \(xp) XP" + (niveaux > 0 ? " et monte de \(niveaux) niveau\(niveaux > 1 ? "x" : "")." : ".")
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
    let acheter: () -> Void

    private var accent: Color {
        article.modele?.rarete.couleur ?? Charte.or
    }

    var body: some View {
        VStack(spacing: 8) {
            visuel
            Text(article.nom)
                .font(.nom(14, relativeTo: .subheadline))
                .foregroundStyle(Charte.ivoire)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
                    default: Label("\(article.prix)", systemImage: "dollarsign.circle.fill")
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
    }

    private var sousTitre: String {
        switch article {
        case .combattant:
            guard let modele = article.modele else { return "" }
            let base = "\(modele.rarete.rawValue) · \(modele.specialite.nom)"
            return possede && etat != .possede ? "\(base) · doublon → \(Boutique.xpDoublon(modele.rarete)) XP" : base
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
        } else if case .objet(let objet) = article {
            Image(systemName: objet.symbole)
                .font(.system(size: 38))
                .foregroundStyle(Charte.or.gradient)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Charte.or.opacity(0.12)))
        }
    }
}
