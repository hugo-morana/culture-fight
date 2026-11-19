import SwiftUI

struct SelectionEquipeView: View {
    let retour: () -> Void
    let lancer: ([ModeleCombattant], IAAdverse.Niveau) -> Void

    @State private var choisis: [String] = []
    @State private var niveau: IAAdverse.Niveau = .moyen
    /// Un exemple de question par combattant, tiré une seule fois à l'ouverture.
    @State private var exemples: [String: String] = [:]

    private var equipe: [ModeleCombattant] {
        choisis.compactMap { id in Catalogue.prototype.first { $0.id == id } }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Catalogue.prototype) { modele in
                        Button {
                            basculer(modele.id)
                        } label: {
                            LigneCombattant(modele: modele,
                                            exemple: exemples[modele.id],
                                            choisi: choisis.contains(modele.id))
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Choisis \(Regles.tailleEquipe) combattants (\(choisis.count)/\(Regles.tailleEquipe))")
                }

                Section {
                    Picker("Niveau de l'IA", selection: $niveau) {
                        ForEach(IAAdverse.Niveau.allCases) { n in
                            Text(n.rawValue).tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Adversaire")
                }
            }
            .navigationTitle("Ton équipe")
            .onAppear {
                guard exemples.isEmpty else { return }
                for modele in Catalogue.prototype {
                    exemples[modele.id] = modele.exempleDeQuestion()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Retour", action: retour)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    lancer(equipe, niveau)
                } label: {
                    Text("Lancer le combat")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                .disabled(choisis.count != Regles.tailleEquipe)
                .padding()
                .background(.bar)
            }
        }
    }

    private func basculer(_ id: String) {
        if let i = choisis.firstIndex(of: id) {
            choisis.remove(at: i)
        } else if choisis.count < Regles.tailleEquipe {
            choisis.append(id)
        }
    }
}

struct LigneCombattant: View {
    let modele: ModeleCombattant
    let exemple: String?
    let choisi: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Avatar(modele: modele, taille: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(modele.nom).font(.headline)
                Text("\(modele.style) · \(modele.specialite.nom)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(modele.rarete.rawValue) · PV \(modele.pvMax) · Att \(modele.attaque) · Déf \(modele.defense)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(modele.apparence)
                    .font(.caption)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                Text("Questions : \(modele.questions)")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Bonus de vitesse (\(modele.familleStyle.effetVitesse.nom)) : \(modele.familleStyle.effetVitesse.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let exemple {
                    Text("Exemple : « \(exemple) »")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(modele.specialite.couleur)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            Image(systemName: choisi ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(choisi ? Color.orange : Color.secondary)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }
}
