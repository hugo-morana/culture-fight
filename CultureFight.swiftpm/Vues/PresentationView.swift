import SwiftUI

/// Carte « En deux mots » de la fiche : l'accroche du combattant et ses blagues, qui défilent au toucher.
struct CartePresentation: View {
    let modele: ModeleCombattant
    let accent: Color
    @State private var indexBlague = 0

    var body: some View {
        if let accroche = modele.accroche {
            CarteFiche(titre: "En deux mots", icone: "quote.opening", accent: accent) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(accroche)
                        .font(.titre(17, relativeTo: .headline))
                        .foregroundStyle(Charte.or)
                        .fixedSize(horizontal: false, vertical: true)
                    let blagues = modele.blagues
                    if !blagues.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Text("😄").font(.title3)
                            Text(blagues[indexBlague % blagues.count])
                                .font(.system(.callout, design: .serif).italic())
                                .foregroundStyle(Charte.ivoire.opacity(0.92))
                                .fixedSize(horizontal: false, vertical: true)
                                .id(indexBlague)
                                .transition(.push(from: .trailing).combined(with: .opacity))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Charte.marine.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard blagues.count > 1 else { return }
                            withAnimation(.spring(duration: 0.4)) { indexBlague += 1 }
                        }
                        if blagues.count > 1 {
                            Text("Touche pour la blague suivante")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

/// Carte « Exemples de questions » : 2 ou 3 questions aux énoncés différents, bonne réponse en or.
struct CarteExemples: View {
    let modele: ModeleCombattant
    let accent: Color
    @State private var exemples: [Question] = []

    var body: some View {
        CarteFiche(titre: "Exemples de questions", icone: "questionmark.bubble.fill", accent: accent) {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(Array(exemples.enumerated()), id: \.offset) { _, question in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(question.enonce)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Charte.ivoire)
                            .fixedSize(horizontal: false, vertical: true)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)],
                                  spacing: 6) {
                            ForEach(Array(question.choix.enumerated()), id: \.offset) { i, choix in
                                let bonne = i == question.bonneReponse
                                Text(choix)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .frame(maxWidth: .infinity, minHeight: 30)
                                    .padding(.horizontal, 6)
                                    .foregroundStyle(bonne ? Charte.marine : Charte.ivoire.opacity(0.8))
                                    .background(bonne ? Charte.or : Charte.marine.opacity(0.6),
                                                in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                Button {
                    withAnimation(.spring(duration: 0.45)) { exemples = modele.exemplesDeQuestions() }
                } label: {
                    Label("Autres exemples", systemImage: "dice.fill")
                        .font(.nom(13, relativeTo: .subheadline))
                }
                .buttonStyle(.bordered)
                .tint(accent)
            }
        }
        .onAppear { if exemples.isEmpty { exemples = modele.exemplesDeQuestions() } }
    }
}
