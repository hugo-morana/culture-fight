import SwiftUI
import SwiftData

/// Profil du compte : niveau et ligue, Pièces, bilan, puis les statistiques détaillées.
struct ProfilView: View {
    let joueur: Joueur
    let retour: () -> Void

    @Query(sort: \PartieJouee.date) private var parties: [PartieJouee]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    entete
                    Text("Statistiques")
                        .font(.titre(24, relativeTo: .title2))
                        .lettrageLogo()
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

    private var entete: some View {
        VStack(spacing: 14) {
            JaugeNiveau(niveau: joueur.niveauCompte, xp: joueur.xpCompte, seuil: joueur.seuilNiveauSuivant)
            HStack(spacing: 8) {
                TuileFiche(icone: "dollarsign.circle.fill", titre: "Pièces", valeur: "\(joueur.pieces)",
                           accent: .yellow, index: 0)
                TuileFiche(icone: "flag.checkered", titre: "Combats", valeur: "\(joueur.combatsJoues)",
                           accent: Charte.or, index: 1)
                TuileFiche(icone: "person.3.fill", titre: "Réserve", valeur: "\(joueur.reserve.count)",
                           accent: Charte.or, index: 2)
            }
        }
    }
}
