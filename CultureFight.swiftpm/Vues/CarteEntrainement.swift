import SwiftUI
import SwiftData

/// Carte « Entraînement » de la fiche : jauge de Maîtrise, séances récompensées du jour, bouton « S'entraîner ».
struct CarteEntrainement: View {
    let modele: ModeleCombattant
    @Query private var joueurs: [Joueur]
    @Environment(\.modelContext) private var contexte
    @State private var seance: [Question]?
    @State private var version = 0

    private var possede: CombattantPossede? { joueurs.first?.reserve.first { $0.modeleID == modele.id } }

    var body: some View {
        if let possede {
            let _ = version
            let maitrise = Entrainement.maitrise(possede, modele)
            let etat = Entrainement.etat(possede)
            let restantes = Entrainement.seancesRecompenseesRestantes(possede)
            CarteFiche(titre: "Entraînement", icone: "figure.mind.and.body", accent: modele.specialite.couleur) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Maîtrise")
                            .font(.nom(14, relativeTo: .subheadline))
                            .foregroundStyle(Charte.ivoire)
                        Spacer()
                        if maitrise >= 1 {
                            Label("Maître", systemImage: "rosette")
                                .font(.nom(13, relativeTo: .caption))
                                .foregroundStyle(Charte.marine)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Charte.or, in: Capsule())
                                .symbolEffect(.bounce, value: maitrise >= 1)
                        }
                        Text("\(Int((maitrise * 100).rounded(.down))) %")
                            .font(.nom(15, relativeTo: .subheadline).monospacedDigit())
                            .foregroundStyle(Charte.or)
                    }
                    ProgressView(value: maitrise)
                        .tint(Charte.or)
                    Text("\(etat.sues.count) question\(etat.sues.count > 1 ? "s" : "") sue\(etat.sues.count > 1 ? "s" : "") sur \(Entrainement.objectif(modele)) · \(etat.aRevoir.count) à revoir")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(restantes > 0
                         ? "Encore \(restantes) séance\(restantes > 1 ? "s" : "") avec Savoir aujourd'hui (+\(Entrainement.savoirParBonneReponse) par bonne réponse)."
                         : "Les 3 séances avec Savoir du jour sont faites : tu peux t'entraîner sans gain.")
                        .font(.caption)
                        .foregroundStyle(Charte.ivoire.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        seance = Entrainement.seance(possede, modele)
                    } label: {
                        Label("S'entraîner (10 questions)", systemImage: "play.fill")
                            .font(.titre(16, relativeTo: .headline))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
            }
            .sheet(isPresented: Binding(get: { seance != nil }, set: { if !$0 { seance = nil; version += 1 } })) {
                if let seance {
                    EntrainementView(questions: seance, titre: "Entraînement · \(modele.nom)",
                                     surReponse: { question, juste in
                                         Entrainement.repondre(question, juste: juste, possede: possede)
                                     },
                                     surFin: { reussies, _ in
                                         Entrainement.terminer(reussies: reussies, possede: possede, dans: contexte)
                                     })
                }
            }
        }
    }
}

/// Depuis l'accueil : choix du combattant à entraîner, avec sa Maîtrise, puis la séance.
struct ChoixEntrainementView: View {
    let modeles: [ModeleCombattant]
    @Query private var joueurs: [Joueur]
    @Environment(\.modelContext) private var contexte
    @Environment(\.dismiss) private var fermer
    @State private var recherche = ""
    @State private var seance: (modele: ModeleCombattant, questions: [Question])?
    @State private var version = 0

    private func possede(_ m: ModeleCombattant) -> CombattantPossede? {
        joueurs.first?.reserve.first { $0.modeleID == m.id }
    }

    private var visibles: [ModeleCombattant] {
        let q = recherche.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return modeles }
        return modeles.filter { $0.correspond(a: q) }
    }

    var body: some View {
        NavigationStack {
            List(visibles) { modele in
                if let possede = possede(modele) {
                    let _ = version
                    let maitrise = Entrainement.maitrise(possede, modele)
                    Button {
                        seance = (modele, Entrainement.seance(possede, modele))
                    } label: {
                        HStack(spacing: 12) {
                            Avatar(modele: modele, taille: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(modele.nom)
                                    .font(.nom(15, relativeTo: .subheadline))
                                    .foregroundStyle(Charte.ivoire)
                                Text(modele.specialite.nom)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: maitrise).tint(Charte.or)
                            }
                            Text("\(Int((maitrise * 100).rounded(.down))) %")
                                .font(.nom(13, relativeTo: .caption).monospacedDigit())
                                .foregroundStyle(Charte.or)
                        }
                    }
                    .listRowBackground(Charte.marine.opacity(0.6))
                }
            }
            .scrollContentBackground(.hidden)
            .background(FondFiche(accent: Charte.or))
            .searchable(text: $recherche, prompt: "Nom, spécialité, style…")
            .navigationTitle("Entraînement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fermer") { fermer() } }
            }
            .safeAreaInset(edge: .top) {
                Text("Choisis un combattant : 10 questions de sa spécialité. Les 3 premières séances du jour de chaque combattant rapportent du Savoir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sheet(isPresented: Binding(get: { seance != nil }, set: { if !$0 { seance = nil; version += 1 } })) {
                if let seance, let possede = possede(seance.modele) {
                    EntrainementView(questions: seance.questions, titre: "Entraînement · \(seance.modele.nom)",
                                     surReponse: { question, juste in
                                         Entrainement.repondre(question, juste: juste, possede: possede)
                                     },
                                     surFin: { reussies, _ in
                                         Entrainement.terminer(reussies: reussies, possede: possede, dans: contexte)
                                     })
                }
            }
        }
    }
}
