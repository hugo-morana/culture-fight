import SwiftUI

/// Ouverture du paquet de départ au premier lancement : le paquet scellé tremble, se déchire au toucher,
/// puis les 6 combattants s'envolent en éventail et se retournent un à un.
struct PaquetDepartView: View {
    let modeles: [ModeleCombattant]
    let terminer: () -> Void

    enum Etape { case scelle, ouvert, revele }

    @State private var etape: Etape = .scelle
    @State private var retournes = 0
    @State private var eclat = false
    @Environment(\.accessibilityReduceMotion) private var mouvementReduit

    private let colonnes = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ZStack {
            FondAnime().ignoresSafeArea()
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(etape == .scelle ? "Ton paquet de départ" : "Bienvenue à Culturia !")
                    .font(.titre(26, relativeTo: .title))
                    .lettrageLogo()
                    .multilineTextAlignment(.center)
                Text(etape == .scelle
                     ? "6 combattants de 6 domaines différents t'attendent. Touche le paquet pour l'ouvrir."
                     : "Ils rejoignent ta réserve. Deux d'entre eux partagent une famille de styles : réunis-en un troisième pour la synergie !")
                    .font(.subheadline)
                    .foregroundStyle(Charte.ivoire.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                if etape == .scelle {
                    paquet
                        .transition(.scale(scale: 1.4).combined(with: .opacity))
                } else {
                    LazyVGrid(columns: colonnes, spacing: 10) {
                        ForEach(Array(modeles.enumerated()), id: \.element.id) { i, modele in
                            carte(modele, index: i)
                        }
                    }
                    .padding(.horizontal)
                }
                if etape == .revele {
                    Button(action: terminer) {
                        Text("C'est parti !")
                            .font(.titre(20, relativeTo: .headline))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.orange)
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.vertical)
            if eclat {
                Color.white.ignoresSafeArea().transition(.opacity).allowsHitTesting(false)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: etape)
        .sensoryFeedback(.selection, trigger: retournes)
    }

    private var paquet: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Charte.or, Color(red: 0.55, green: 0.38, blue: 0.1)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Charte.ivoire.opacity(0.7), lineWidth: 3).padding(8))
            VStack(spacing: 10) {
                if let logo = Illustrations.partage.ressource("logo", type: "png") {
                    Image(uiImage: logo).resizable().scaledToFit().frame(width: 130)
                }
                Text("6 combattants")
                    .font(.titre(18, relativeTo: .headline))
                    .foregroundStyle(Charte.marine)
            }
        }
        .frame(width: 200, height: 280)
        .shadow(color: Charte.or.opacity(0.7), radius: 24)
        .phaseAnimator([0.0, -3.0, 3.0, -2.0, 0.0]) { vue, angle in
            vue.rotationEffect(.degrees(mouvementReduit ? 0 : angle))
        } animation: { _ in .easeInOut(duration: 0.12) }
        .onTapGesture { ouvrir() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Ouvrir le paquet de départ")
    }

    private func carte(_ modele: ModeleCombattant, index: Int) -> some View {
        let visible = index < retournes
        return CarteRetournable(angle: visible ? 0 : 180,
                                recto: CarteCollection(modele: modele),
                                verso: dos)
            .frame(height: 170)
            .animation(.spring(duration: 0.6, bounce: 0.3), value: visible)
            .transition(.asymmetric(
                insertion: .offset(y: 300).combined(with: .scale(scale: 0.3)).combined(with: .opacity),
                removal: .opacity))
    }

    private var dos: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(colors: [Charte.marine, Color(red: 0.12, green: 0.18, blue: 0.4)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(Image(systemName: "questionmark").font(.largeTitle.bold()).foregroundStyle(Charte.or))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Charte.or.opacity(0.7), lineWidth: 2))
    }

    private func ouvrir() {
        guard etape == .scelle else { return }
        ServiceSons.partage.jouer(.objet)
        Task {
            withAnimation(.easeIn(duration: 0.12)) { eclat = true }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) { etape = .ouvert }
            withAnimation(.easeOut(duration: 0.5)) { eclat = false }
            try? await Task.sleep(for: .milliseconds(700))
            for i in 1...modeles.count {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) { retournes = i }
                ServiceSons.partage.jouer(.carte)
                try? await Task.sleep(for: .milliseconds(mouvementReduit ? 150 : 450))
            }
            withAnimation(.spring(duration: 0.5)) { etape = .revele }
        }
    }
}
