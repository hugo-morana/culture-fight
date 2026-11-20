import SwiftUI
import SwiftData

extension Joueur {
    /// Équipement porté par chaque combattant de la réserve.
    var equipements: [String: String] {
        var dico: [String: String] = [:]
        for c in reserve { if let e = c.equipementID { dico[c.modeleID] = e } }
        return dico
    }

    /// Exemplaires d'un équipement encore libres (achetés moins portés par d'autres combattants).
    func equipementsLibres(_ id: String, sauf modeleID: String) -> Int {
        let portes = reserve.filter { $0.equipementID == id && $0.modeleID != modeleID }.count
        return (inventaire[id] ?? 0) - portes
    }
}

/// Carte « Équipement » de la fiche : choisir l'objet permanent porté par ce combattant.
struct CarteEquipement: View {
    let modele: ModeleCombattant
    @Query private var joueurs: [Joueur]
    @Environment(\.modelContext) private var contexte

    private var joueur: Joueur? { joueurs.first }
    private var possede: CombattantPossede? { joueur?.reserve.first { $0.modeleID == modele.id } }

    var body: some View {
        if let joueur, let possede {
            let permanents = Boutique.objets.filter { $0.genre == .permanent }
            let disponibles = permanents.filter {
                possede.equipementID == $0.id || joueur.equipementsLibres($0.id, sauf: modele.id) > 0
            }
            CarteFiche(titre: "Équipement", icone: "shield.checkered", accent: modele.specialite.couleur) {
                VStack(alignment: .leading, spacing: 10) {
                    if disponibles.isEmpty {
                        TexteFiche(texte: "Aucun équipement libre. Achète-en à la boutique : chaque exemplaire équipe un combattant.")
                    } else {
                        ForEach(disponibles) { objet in
                            ligne(objet, actif: possede.equipementID == objet.id) {
                                withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                                    possede.equipementID = possede.equipementID == objet.id ? nil : objet.id
                                }
                                Sauvegarde.enregistrer(contexte)
                            }
                        }
                    }
                }
                .sensoryFeedback(.selection, trigger: possede.equipementID)
            }
        }
    }

    private func ligne(_ objet: Objet, actif: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: objet.symbole)
                    .font(.title3)
                    .foregroundStyle(actif ? Charte.marine : Charte.or)
                    .frame(width: 36, height: 36)
                    .background(actif ? Charte.or : Charte.marine, in: Circle())
                    .symbolEffect(.bounce, value: actif)
                VStack(alignment: .leading, spacing: 2) {
                    Text(objet.nom)
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(Charte.ivoire)
                    Text(objet.effet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text(actif ? "Porté" : "Équiper")
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(actif ? Charte.or : Charte.ivoire.opacity(0.7))
            }
            .padding(8)
            .background(Charte.marine.opacity(actif ? 0.9 : 0.5), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(actif ? Charte.or : Color.white.opacity(0.1),
                                                                lineWidth: actif ? 2 : 1))
        }
        .buttonStyle(.plain)
    }
}

/// Barre des objets utilisables pendant le combat.
struct BarreObjets: View {
    let controleur: CombatController

    var body: some View {
        let objets = controleur.objetsDisponibles
        VStack(spacing: 6) {
            if !objets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(objets) { objet in
                            Button {
                                withAnimation(.spring(duration: 0.35)) { controleur.utiliser(objet.id) }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: objet.symbole)
                                        .symbolEffect(.pulse, isActive: objet.id == "coup-de-maitre")
                                    Text(objet.nom)
                                        .font(.nom(12, relativeTo: .caption))
                                    if let n = objet.quantite {
                                        Text("×\(n)").font(.caption2.monospacedDigit())
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(objet.id == "coup-de-maitre" ? Charte.or : Charte.marine.opacity(0.85),
                                            in: Capsule())
                                .foregroundStyle(objet.id == "coup-de-maitre" ? Charte.marine : Charte.ivoire)
                                .overlay(Capsule().stroke(Charte.or.opacity(0.5), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .transition(.scale.combined(with: .opacity))
                        }
                        if controleur.consommablesRestants < CombatController.consommablesParCombat {
                            Text("\(controleur.consommablesRestants) objet\(controleur.consommablesRestants > 1 ? "s" : "") restant\(controleur.consommablesRestants > 1 ? "s" : "")")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let message = controleur.messageObjet {
                Label(message, systemImage: "sparkles")
                    .font(.nom(12, relativeTo: .caption))
                    .foregroundStyle(Charte.or)
                    .id(controleur.compteurObjets)
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: controleur.compteurObjets)
        .sensoryFeedback(.impact(weight: .medium), trigger: controleur.compteurObjets)
    }
}
