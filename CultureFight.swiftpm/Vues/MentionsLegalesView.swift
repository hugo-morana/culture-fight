import SwiftUI

/// Mentions légales et crédits (tâche 63) : droits d'auteur, police sous licence, sources des données.
/// Ouvert depuis le profil.
struct MentionsLegalesView: View {
    /// Année de première publication, puis l'année en cours si elle est différente (« 2026–2027 »).
    static var annees: String {
        let debut = 2026
        let maintenant = Calendar.current.component(.year, from: Date())
        return maintenant > debut ? "\(debut)–\(maintenant)" : "\(debut)"
    }

    static var version: String {
        let infos = Bundle.main.infoDictionary
        let version = infos?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infos?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    /// Toutes les sources des jeux de données, sans doublon, triées par titre.
    private var sources: [SourceDonnees] {
        var vues = Set<SourceDonnees>()
        for liste in Univers.sources.values { vues.formUnion(liste) }
        return vues.sorted { $0.titre.localizedCaseInsensitiveCompare($1.titre) == .orderedAscending }
    }

    /// Texte complet de la licence de la police (obligatoire avec la police, licence OFL).
    private var licenceCinzel: String {
        let url = Bundle.module.url(forResource: "OFL-Cinzel", withExtension: "txt")
            ?? Bundle.module.url(forResource: "OFL-Cinzel", withExtension: "txt", subdirectory: "Polices")
        guard let url, let texte = try? String(contentsOf: url, encoding: .utf8) else {
            return "SIL Open Font License, version 1.1 : https://openfontlicense.org"
        }
        return texte
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CarteFiche(titre: "Culture Fight", icone: "c.circle.fill", accent: Charte.or) {
                    VStack(alignment: .leading, spacing: 6) {
                        TexteFiche(texte: "© \(Self.annees) Hugo Morana. Tous droits réservés.")
                        TexteFiche(texte: "Le jeu, son code, ses règles, son monde de Culturia, les noms, "
                                   + "histoires et illustrations des combattants, les questions et leurs "
                                   + "explications, ainsi que la base de questions, appartiennent à Hugo Morana.")
                        TexteFiche(texte: "Toute reproduction, extraction ou réutilisation, même partielle, "
                                   + "est interdite sans autorisation écrite préalable.")
                        Text(Self.version)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                CarteFiche(titre: "Éditeur", icone: "person.crop.circle", accent: Charte.or) {
                    VStack(alignment: .leading, spacing: 6) {
                        TexteFiche(texte: "Application éditée par Hugo Morana.")
                        TexteFiche(texte: "Distribution : App Store d'Apple, selon les conditions "
                                   + "d'utilisation standard d'Apple (EULA).")
                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                            Link(destination: url) {
                                Label("Contrat de licence d'Apple", systemImage: "link")
                                    .font(.subheadline)
                            }
                            .tint(Charte.or)
                        }
                    }
                }

                CarteFiche(titre: "Données personnelles", icone: "lock.shield.fill", accent: .green) {
                    TexteFiche(texte: "Aucune donnée n'est collectée ni envoyée : la progression "
                               + "(Pièces, collection, historique des parties) reste sur l'appareil.")
                }

                CarteFiche(titre: "Police de caractères", icone: "textformat", accent: .cyan) {
                    VStack(alignment: .leading, spacing: 6) {
                        TexteFiche(texte: "Cinzel, © 2020 The Cinzel Project Authors, "
                                   + "sous licence SIL Open Font License 1.1.")
                        DisclosureGroup("Texte de la licence") {
                            Text(licenceCinzel)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.subheadline)
                        .tint(.cyan)
                    }
                }

                CarteFiche(titre: "Icônes", icone: "star.circle.fill", accent: .yellow) {
                    TexteFiche(texte: "Pictogrammes SF Symbols d'Apple, utilisés selon les conditions d'Apple.")
                }

                CarteFiche(titre: "Sources des questions", icone: "books.vertical.fill", accent: .purple) {
                    VStack(alignment: .leading, spacing: 6) {
                        TexteFiche(texte: "Les faits sont vérifiés dans les sources ci-dessous ; les questions "
                                   + "et les explications sont rédigées pour le jeu. Les sources ne "
                                   + "parrainent ni n'approuvent Culture Fight.")
                        DisclosureGroup("\(sources.count) sources") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(sources, id: \.self) { source in
                                    if let url = URL(string: source.url) {
                                        Link(destination: url) {
                                            Label(source.titre, systemImage: "link")
                                                .font(.caption)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .tint(.purple)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .font(.subheadline)
                        .tint(.purple)
                    }
                }

                CarteFiche(titre: "Marques", icone: "seal.fill", accent: .gray) {
                    TexteFiche(texte: "Apple, iPhone, iPad et App Store sont des marques d'Apple Inc. "
                               + "Les noms de lieux, de personnes et d'œuvres réels sont cités à titre "
                               + "culturel et informatif.")
                }
            }
            .padding()
        }
        .background { FondFiche(accent: Charte.or) }
        .navigationTitle("Mentions légales")
        .navigationBarTitleDisplayMode(.inline)
    }
}
