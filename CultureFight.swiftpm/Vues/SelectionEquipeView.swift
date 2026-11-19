import SwiftUI

struct SelectionEquipeView: View {
    let retour: () -> Void
    let lancer: ([ModeleCombattant], IAAdverse.Niveau) -> Void

    @State private var choisis: [String] = []
    @State private var niveau: IAAdverse.Niveau = .moyen

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
                            LigneCombattant(modele: modele, choisi: choisis.contains(modele.id))
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
    let choisi: Bool

    var body: some View {
        HStack(spacing: 12) {
            Avatar(modele: modele, taille: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(modele.nom).font(.headline)
                Text("\(modele.style) · \(modele.specialite.nom)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(modele.rarete.rawValue) · PV \(modele.pvMax) · Att \(modele.attaque) · Déf \(modele.defense)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
