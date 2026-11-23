import SwiftUI

// MARK: - Présentation d'une partie

extension PartieJouee {
    var libelleResultat: String {
        switch resultat {
        case 0: return "Victoire"
        case 1: return "Défaite"
        case 2: return "Match nul"
        default: return "Abandon"
        }
    }

    /// Lettre de la pastille : V, D, N ou A.
    var lettreResultat: String {
        switch resultat {
        case 0: return "V"
        case 1: return "D"
        case 2: return "N"
        default: return "A"
        }
    }

    var couleurResultat: Color {
        switch resultat {
        case 0: return BarreResultats.vert
        case 2: return BarreResultats.gris
        default: return BarreResultats.rouge
        }
    }

    var modelesEquipe: [ModeleCombattant] { PartieJouee.modeles(equipe) }
    var modelesIA: [ModeleCombattant] { PartieJouee.modeles(equipeIA) }

    var bonnesReponses: Int { reponses.filter(\.correct).count }

    static func modeles(_ ids: [String]) -> [ModeleCombattant] {
        ids.compactMap { id in Catalogue.modele(id) }
    }
}

/// Signe typographique d'un gain : +30, −20, 0.
private func signe(_ n: Int) -> String {
    n > 0 ? "+\(n)" : (n < 0 ? "−\(-n)" : "0")
}

// MARK: - Carte du profil

/// Les 5 dernières parties dans le profil, avec un lien vers l'historique complet.
struct CarteHistorique: View {
    let parties: [PartieJouee]

    var body: some View {
        CarteFiche(titre: "Historique", icone: "clock.arrow.circlepath", accent: Charte.or) {
            if parties.isEmpty {
                Text("Aucune partie jouée pour l'instant.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(parties.prefix(5)) { partie in
                        NavigationLink {
                            DetailPartieView(partie: partie)
                        } label: {
                            LignePartie(partie: partie)
                        }
                        .buttonStyle(.plain)
                    }
                    if parties.count > 5 {
                        NavigationLink {
                            HistoriqueView(parties: parties)
                        } label: {
                            Label("Voir les \(parties.count) parties", systemImage: "list.bullet")
                                .font(.nom(14, relativeTo: .subheadline))
                                .foregroundStyle(Charte.or)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Historique complet

struct HistoriqueView: View {
    let parties: [PartieJouee]

    /// Les parties regroupées par jour, du plus récent au plus ancien.
    private var jours: [(jour: Date, parties: [PartieJouee])] {
        let calendrier = Calendar.current
        let groupes = Dictionary(grouping: parties) { calendrier.startOfDay(for: $0.date) }
        return groupes.keys.sorted(by: >).map { ($0, groupes[$0]!.sorted { $0.date > $1.date }) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                BilanHistorique(parties: parties)
                ForEach(jours, id: \.jour) { groupe in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(groupe.jour.formatted(.dateTime.weekday(.wide).day().month(.wide).year()).capitalized)
                            .font(.nom(15, relativeTo: .subheadline))
                            .foregroundStyle(Charte.or)
                        ForEach(groupe.parties) { partie in
                            NavigationLink {
                                DetailPartieView(partie: partie)
                            } label: {
                                LignePartie(partie: partie)
                                    .padding(12)
                                    .background(Charte.marine.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(partie.couleurResultat.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background { FondFiche(accent: Charte.or) }
        .navigationTitle("Historique")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// En tête de l'historique : nombre de parties et série en cours.
struct BilanHistorique: View {
    let parties: [PartieJouee]

    /// Série en cours, à partir de la partie la plus récente (ex. 3 victoires d'affilée).
    private var serie: (nombre: Int, partie: PartieJouee)? {
        guard let derniere = parties.first else { return nil }
        let nombre = parties.prefix { $0.estVictoire == derniere.estVictoire && $0.estDefaite == derniere.estDefaite }.count
        return (nombre, derniere)
    }

    var body: some View {
        HStack(spacing: 8) {
            TuileFiche(icone: "flag.checkered", titre: "Parties", valeur: "\(parties.count)", accent: Charte.or, index: 0)
            TuileFiche(icone: "trophy.fill", titre: "Victoires",
                       valeur: "\(parties.filter(\.estVictoire).count)", accent: BarreResultats.vert, index: 1)
            if let serie {
                TuileFiche(icone: serie.partie.estVictoire ? "flame.fill" : "chart.line.downtrend.xyaxis",
                           titre: "Série",
                           valeur: "\(serie.nombre) \(serie.partie.lettreResultat)",
                           accent: serie.partie.couleurResultat, index: 2)
            }
        }
    }
}

// MARK: - Ligne

struct LignePartie: View {
    let partie: PartieJouee

    var body: some View {
        HStack(spacing: 10) {
            Text(partie.lettreResultat)
                .font(.titre(17))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(partie.couleurResultat.gradient, in: RoundedRectangle(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(partie.libelleResultat)
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(Charte.ivoire)
                    Text("· IA \(partie.niveauIA.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    Text(partie.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    ForEach(partie.modelesEquipe) { Avatar(modele: $0, taille: 22) }
                    Text("vs")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                    ForEach(partie.modelesIA) { Avatar(modele: $0, taille: 22) }
                    Spacer(minLength: 4)
                    if partie.pieces > 0 {
                        Label("+\(partie.pieces)", systemImage: "dollarsign.circle.fill")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.yellow)
                    }
                    Text("\(signe(partie.xpCompte)) Savoir")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(partie.xpCompte >= 0 ? Charte.ivoire : BarreResultats.rouge)
                }
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Détail d'une partie

struct DetailPartieView: View {
    let partie: PartieJouee

    /// Bonnes réponses / réponses par domaine, dans l'ordre où ils apparaissent.
    private var parDomaine: [(domaine: String, bonnes: Int, total: Int)] {
        var ordre: [String] = []
        var scores: [String: (Int, Int)] = [:]
        for r in partie.reponses {
            if scores[r.domaine] == nil { ordre.append(r.domaine) }
            let s = scores[r.domaine, default: (0, 0)]
            scores[r.domaine] = (s.0 + (r.correct ? 1 : 0), s.1 + 1)
        }
        return ordre.map { ($0, scores[$0]!.0, scores[$0]!.1) }
    }

    private var tempsMoyen: Double? {
        let bonnes = partie.reponses.filter { $0.correct }
        guard !bonnes.isEmpty else { return nil }
        return bonnes.map(\.secondes).reduce(0, +) / Double(bonnes.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 6) {
                    Text(partie.libelleResultat)
                        .font(.titre(34, relativeTo: .largeTitle))
                        .foregroundStyle(partie.couleurResultat)
                    Text("\(partie.date.formatted(date: .complete, time: .shortened)) · IA \(partie.niveauIA.lowercased())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    TuileFiche(icone: "dollarsign.circle.fill", titre: "Pièces", valeur: "+\(partie.pieces)",
                               accent: .yellow, index: 0)
                    TuileFiche(icone: "star.circle.fill", titre: "Savoir", valeur: signe(partie.xpCompte),
                               accent: partie.xpCompte >= 0 ? Charte.or : BarreResultats.rouge, index: 1)
                    TuileFiche(icone: "shield.fill", titre: "Niveau après", valeur: "\(partie.niveauCompteApres)",
                               accent: Ligue(niveau: partie.niveauCompteApres).couleurs.0, index: 2)
                }

                CarteFiche(titre: "Équipes", icone: "person.3.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        ligneEquipe("Toi", partie.modelesEquipe, pv: partie.pvRestants)
                        ligneEquipe("IA", partie.modelesIA, pv: partie.pvAdverses)
                        if partie.tours > 0 {
                            Text("\(partie.tours) tour\(partie.tours > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                CarteFiche(titre: "Tes réponses", icone: "checkmark.seal.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        if partie.reponses.isEmpty {
                            Text("Aucune réponse donnée.").font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            HStack {
                                Text("\(partie.bonnesReponses)/\(partie.reponses.count) bonnes réponses")
                                    .font(.nom(14, relativeTo: .subheadline))
                                    .foregroundStyle(Charte.ivoire)
                                Spacer()
                                if let p = partie.precision {
                                    Text("\(Int(p.rounded())) %").font(.headline.monospacedDigit()).foregroundStyle(Charte.or)
                                }
                            }
                            if let tempsMoyen {
                                Text("Temps moyen d'une bonne réponse : \(tempsMoyen.formatted(.number.precision(.fractionLength(1)))) s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(parDomaine, id: \.domaine) { ligne in
                                HStack {
                                    Text("\(Pictos.domaine(ligne.domaine)) \(ligne.domaine)")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(ligne.bonnes)/\(ligne.total)")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(ligne.bonnes == ligne.total ? BarreResultats.vert : Charte.ivoire)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background { FondFiche(accent: partie.couleurResultat) }
        .navigationTitle("Partie")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ligneEquipe(_ nom: String, _ modeles: [ModeleCombattant], pv: Int) -> some View {
        HStack(spacing: 8) {
            Text(nom)
                .font(.nom(13, relativeTo: .caption))
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .leading)
            ForEach(modeles) { modele in
                VStack(spacing: 2) {
                    Avatar(modele: modele, taille: 40)
                    Text(modele.nom)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 64)
                }
            }
            Spacer()
            Text("\(pv) PV")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
