import SwiftUI

struct CombatView: View {
    let controleur: CombatController
    let rejouer: () -> Void
    let accueil: () -> Void
    /// Appelé une fois le combat terminé, pour verser les gains.
    var termine: () -> Void = {}
    /// Appelé quand le joueur abandonne, avant le retour à l'accueil.
    var abandonne: () -> Void = {}

    @State private var confirmerAbandon = false

    /// Identité de ce qui est affiché au centre : change à chaque question, résultat ou fin.
    private var clePhase: String {
        switch controleur.phase {
        case .attente: return "attente"
        case .question: return "question-\(controleur.combat.tour)"
        case .resultat: return "resultat-\(controleur.combat.tour)"
        case .fin: return "fin"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            entete
            CarteCamp(camp: controleur.combat.camps[1],
                      impacts: controleur.impacts[1],
                      variation: controleur.variations[1])
            ScrollView {
                ZStack {
                    zoneCentrale
                        .id(clePhase)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: 20)),
                            removal: .opacity.combined(with: .scale(scale: 1.05))))
                }
                .animation(.spring(duration: 0.45, bounce: 0.3), value: clePhase)
                .padding(.vertical, 4)
            }
            CarteCamp(camp: controleur.combat.camps[0],
                      impacts: controleur.impacts[0],
                      variation: controleur.variations[0])
        }
        .padding()
        .overlay {
            if controleur.estFini && controleur.estVictoire {
                Confettis().ignoresSafeArea()
            }
        }
        .task { controleur.demarrer() }
        .onChange(of: controleur.estFini) { _, fini in
            if fini { termine() }
        }
        .confirmationDialog("Abandonner le combat ?", isPresented: $confirmerAbandon, titleVisibility: .visible) {
            Button("Abandonner", role: .destructive) {
                controleur.abandonner()
                abandonne()
                accueil()
            }
        } message: {
            Text("Un abandon compte comme une défaite : aucune Pièce, et tu perds de l'XP de compte.")
        }
    }

    private var entete: some View {
        HStack {
            Text("Tour \(min(controleur.combat.tour + 1, Regles.toursMax))/\(Regles.toursMax)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .contentTransition(.numericText(value: Double(controleur.combat.tour)))
                .animation(.snappy, value: controleur.combat.tour)
            Spacer()
            if !controleur.estFini {
                Button("Abandonner") { confirmerAbandon = true }
                    .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var zoneCentrale: some View {
        switch controleur.phase {
        case .attente:
            ProgressView()
        case .question:
            if let question = controleur.question {
                VueQuestion(question: question,
                            attaquant: controleur.combat.camps[controleur.combat.attaquant].actif.modele,
                            affinite: controleur.affinite,
                            retires: controleur.retires,
                            tempsRestant: controleur.tempsRestant,
                            tempsTotal: controleur.tempsTotal,
                            malusTemps: controleur.malusTemps,
                            joueurRepond: controleur.joueurRepond,
                            repondre: { controleur.repondre($0) })
            }
        case .resultat(let resultat):
            VueResultat(resultat: resultat, continuer: { controleur.continuer() })
        case .fin:
            VueFin(titre: controleur.titreFin,
                   victoire: controleur.estVictoire,
                   bilan: controleur.bilan,
                   niveauxGagnes: controleur.niveauxGagnes,
                   niveauxCompteGagnes: controleur.niveauxCompteGagnes,
                   rejouer: rejouer,
                   accueil: accueil)
        }
    }
}

// MARK: - Camps

struct CarteCamp: View {
    let camp: Camp
    /// Augmente à chaque fois que les PV du camp changent.
    let impacts: Int
    /// Dernière variation de PV (négative : dégâts, positive : soin).
    let variation: Int

    var body: some View {
        let actif = camp.actif
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                HStack(spacing: 12) {
                    Avatar(modele: actif.modele, taille: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(actif.modele.nom).font(.nom(18)).lineLimit(1).minimumScaleFactor(0.7)
                            Spacer()
                            Text("\(actif.pv)/\(actif.modele.pvMax) PV")
                                .font(.subheadline.monospacedDigit())
                                .contentTransition(.numericText(value: Double(actif.pv)))
                                .animation(.snappy(duration: 0.5), value: actif.pv)
                        }
                        BarrePV(pv: actif.pv, pvMax: actif.modele.pvMax)
                        HStack(spacing: 6) {
                            Text(actif.modele.sousTitre)
                                .font(.nom(12, relativeTo: .caption))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if actif.bouclier > 0 {
                                Image(systemName: "shield.fill")
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                                    .symbolEffect(.pulse)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            jauge(actif)
                        }
                    }
                }
                .id(actif.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            }
            .animation(.spring(duration: 0.5, bounce: 0.3), value: actif.id)
            .animation(.spring(duration: 0.4), value: actif.bouclier > 0)

            HStack(spacing: 6) {
                Text(camp.nom).font(.nom(13, relativeTo: .caption))
                ForEach(camp.combattants) { c in
                    Circle()
                        .fill(c.estKO ? Color.gray.opacity(0.4) : c.modele.specialite.couleur)
                        .frame(width: 10, height: 10)
                        .scaleEffect(c.id == actif.id ? 1.3 : 1)
                        .overlay(Circle().stroke(Color.white, lineWidth: c.id == actif.id ? 2 : 0))
                        .animation(.spring(duration: 0.4, bounce: 0.5), value: actif.id)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
        .modifier(EffetImpact(declencheur: impacts, variation: variation))
        .overlay(alignment: .topTrailing) {
            ChiffreEnvole(declencheur: impacts, variation: variation)
                .padding(.trailing, 28)
                .padding(.top, 4)
        }
    }

    /// Jauge de Savoir : 3 cases, ou un éclair qui pulse quand la capacité est prête.
    @ViewBuilder
    private func jauge(_ c: CombattantEnJeu) -> some View {
        if c.capacitePrete {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .symbolEffect(.pulse)
                Text("Prêt")
            }
            .font(.caption2.bold())
            .foregroundStyle(.yellow)
            .transition(.scale.combined(with: .opacity))
        } else {
            HStack(spacing: 3) {
                ForEach(0..<Regles.jaugeMax, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < c.jauge ? Color.yellow : Color.white.opacity(0.15))
                        .frame(width: 12, height: 6)
                        .scaleEffect(y: i < c.jauge ? 1.25 : 1)
                        .animation(.spring(duration: 0.35, bounce: 0.6), value: c.jauge)
                }
            }
        }
    }
}

// MARK: - Question

struct VueQuestion: View {
    let question: Question
    let attaquant: ModeleCombattant
    let affinite: Affinite
    let retires: Set<Int>
    let tempsRestant: Double
    let tempsTotal: Double
    let malusTemps: Double
    let joueurRepond: Bool
    let repondre: (Int) -> Void

    @State private var apparu = false

    private var urgence: Bool { tempsRestant < 5 }
    private var secondes: Int { Int(tempsRestant.rounded(.up)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(attaquant.nom) attaque · \(question.specialite.nom)")
                .font(.caption.bold())
                .foregroundStyle(question.specialite.couleur)
            if let libelle = affinite.libelle {
                Text(libelle)
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
            if malusTemps > 0 {
                Text("Pression : \(Int(malusTemps)) s de moins pour répondre")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .foregroundStyle(urgence ? Color.red : Color.orange)
                    .symbolEffect(.pulse, isActive: urgence)
                ProgressView(value: max(0, tempsRestant), total: tempsTotal)
                    .tint(urgence ? Color.red : Color.orange)
                Text("\(secondes)")
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(urgence ? Color.red : Color.primary)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy, value: secondes)
                    .frame(width: 26, alignment: .trailing)
            }
            Text(question.enonce)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
                .scaleEffect(apparu ? 1 : 0.92, anchor: .leading)
                .opacity(apparu ? 1 : 0)
                .animation(.spring(duration: 0.4, bounce: 0.3), value: apparu)
            ForEach(question.choix.indices, id: \.self) { i in
                Button {
                    repondre(i)
                } label: {
                    Text(question.choix[i])
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .disabled(!joueurRepond || retires.contains(i))
                .opacity(apparu ? (retires.contains(i) ? 0.25 : 1) : 0)
                .offset(y: apparu ? 0 : 24)
                .animation(.spring(duration: 0.45, bounce: 0.35).delay(0.08 + Double(i) * 0.07), value: apparu)
            }
            if !joueurRepond {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .symbolEffect(.pulse)
                    Text("L'adversaire réfléchit…")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .onAppear { apparu = true }
    }
}

// MARK: - Résultat

struct VueResultat: View {
    let resultat: ResultatTour
    let continuer: () -> Void

    @State private var apparu = false

    private var titre: String {
        if resultat.reponse == nil { return "Temps écoulé !" }
        return resultat.correct ? "Bonne réponse !" : "Mauvaise réponse"
    }

    private var icone: String {
        if resultat.reponse == nil { return "timer" }
        return resultat.correct ? "checkmark.seal.fill" : "xmark.octagon.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icone)
                    .font(.title)
                    .symbolEffect(.bounce, value: apparu)
                Text(titre)
                    .font(.titre(24, relativeTo: .title2))
            }
            .foregroundStyle(resultat.correct ? Color.green : Color.red)
            .overlay {
                if resultat.vitesse == .eclair {
                    Etincelles(couleur: .yellow)
                        .frame(width: 320, height: 220)
                }
            }

            Text(resultat.question.enonce)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(resultat.question.choix.indices, id: \.self) { i in
                let bonne = i == resultat.question.bonneReponse
                let choisie = i == resultat.reponse
                HStack(spacing: 8) {
                    Image(systemName: bonne ? "checkmark.circle.fill" : (choisie ? "xmark.circle.fill" : "circle"))
                        .foregroundStyle(bonne ? Color.green : (choisie ? Color.red : Color.secondary))
                    Text(resultat.question.choix[i])
                        .font(.subheadline.weight(bonne ? .bold : .regular))
                    Spacer()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(bonne ? Color.green.opacity(0.22) : (choisie ? Color.red.opacity(0.22) : Color.white.opacity(0.05))))
                .scaleEffect(bonne && apparu ? 1.02 : 1)
                .animation(.spring(duration: 0.5, bounce: 0.5).delay(0.15), value: apparu)
            }

            Text(resultat.question.explication)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                if resultat.correct {
                    if let effet = resultat.effetVitesse {
                        ligne(effet, "bolt.horizontal.fill")
                    }
                    ligne("Contre-attaque : \(resultat.attaquantNom) perd \(resultat.degatsContre) PV", "arrow.uturn.backward")
                    if resultat.jaugeRemplie {
                        ligne("Jauge de Savoir pleine : \(resultat.defenseurNom) fera double dégâts à sa prochaine attaque", "bolt.fill")
                    }
                } else {
                    ligne("\(resultat.defenseurNom) perd \(resultat.degatsDefenseur) PV", "burst.fill")
                    if resultat.degatsAbsorbes > 0 {
                        ligne("Bouclier : \(resultat.degatsAbsorbes) PV absorbés", "shield.fill")
                    }
                    if resultat.capaciteUtilisee {
                        ligne("Capacité spéciale : dégâts doublés", "bolt.fill")
                    }
                }
                if resultat.koDefenseur {
                    ligne("\(resultat.defenseurNom) est K.O. !", "xmark.octagon.fill")
                }
                if resultat.koAttaquant {
                    ligne("\(resultat.attaquantNom) est K.O. !", "xmark.octagon.fill")
                }
            }
            .opacity(apparu ? 1 : 0)
            .offset(y: apparu ? 0 : 12)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: apparu)

            Button(action: continuer) {
                Text("Suivant")
                    .font(.titre(19, relativeTo: .headline))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .padding(.top, 6)
        }
        .sensoryFeedback(resultat.correct ? .success : .error, trigger: apparu)
        .onAppear { apparu = true }
    }

    private func ligne(_ texte: String, _ icone: String) -> some View {
        Label(texte, systemImage: icone)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Fin

struct VueFin: View {
    let titre: String
    let victoire: Bool
    let bilan: BilanCombat
    let niveauxGagnes: [String: Int]
    let niveauxCompteGagnes: Int
    let rejouer: () -> Void
    let accueil: () -> Void

    @State private var apparu = false
    @State private var piecesAffichees = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: victoire ? "trophy.fill" : "flag.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(victoire ? Color.yellow : Color.secondary)
                    .symbolEffect(.bounce, value: apparu)
                Text(titre)
                    .font(.titre(38, relativeTo: .largeTitle))
                    .lettrageLogo()
                    .scaleEffect(apparu ? 1 : 0.3)
                    .opacity(apparu ? 1 : 0)
                    .animation(.spring(duration: 0.6, bounce: 0.5), value: apparu)
                Label("+\(piecesAffichees) Pièces", systemImage: "dollarsign.circle.fill")
                    .font(.titre(26, relativeTo: .title2).monospacedDigit())
                    .foregroundStyle(.yellow)
                    .contentTransition(.numericText(value: Double(piecesAffichees)))
                detailPieces
                experience
                Button(action: rejouer) {
                    Text("Rejouer").font(.titre(19, relativeTo: .headline)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.orange)
                Button("Accueil", action: accueil)
                    .font(.nom(16, relativeTo: .body))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .sensoryFeedback(victoire ? .success : .warning, trigger: apparu)
        .onAppear {
            apparu = true
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                piecesAffichees = bilan.pieces
            }
        }
    }

    private var detailPieces: some View {
        VStack(spacing: 6) {
            ForEach(Array(bilan.lignes.enumerated()), id: \.element.id) { index, ligne in
                HStack {
                    Text(ligne.libelle)
                        .font(.nom(14, relativeTo: .subheadline))
                        .foregroundStyle(Charte.ivoire.opacity(0.85))
                    Spacer()
                    Text("+\(ligne.pieces)")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(.yellow)
                }
                .opacity(apparu ? 1 : 0)
                .offset(x: apparu ? 0 : -20)
                .animation(.spring(duration: 0.5).delay(0.5 + 0.12 * Double(index)), value: apparu)
            }
        }
        .padding(12)
        .background(Charte.marine.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Charte.or.opacity(0.35), lineWidth: 1))
    }

    private var experience: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(bilan.xpCompte >= 0 ? "+" : "−")\(abs(bilan.xpCompte)) XP de compte",
                      systemImage: bilan.xpCompte >= 0 ? "star.circle.fill" : "arrow.down.circle.fill")
                    .font(.nom(15, relativeTo: .headline))
                    .foregroundStyle(bilan.xpCompte >= 0 ? Charte.ivoire : Color.red)
                Spacer()
                if niveauxCompteGagnes > 0 {
                    BadgeNiveau(texte: "Niveau +\(niveauxCompteGagnes)")
                } else if niveauxCompteGagnes < 0 {
                    BadgeNiveau(texte: "Niveau −\(-niveauxCompteGagnes)", baisse: true)
                }
            }
            ForEach(Array(bilan.combattants.enumerated()), id: \.element.id) { index, gain in
                HStack(spacing: 10) {
                    Avatar(modele: gain.modele, taille: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gain.modele.nom)
                            .font(.nom(14, relativeTo: .subheadline))
                            .foregroundStyle(Charte.ivoire)
                        Text(gain.bonnesReponses > 0
                             ? "\(gain.bonnesReponses) bonne\(gain.bonnesReponses > 1 ? "s" : "") réponse\(gain.bonnesReponses > 1 ? "s" : "") en défense"
                             : "Aucune bonne réponse en défense")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let n = niveauxGagnes[gain.modele.id] {
                        BadgeNiveau(texte: n > 1 ? "+\(n) niveaux" : "Niveau +1")
                    }
                    Text("+\(gain.xp) XP")
                        .font(.subheadline.monospacedDigit().bold())
                        .foregroundStyle(gain.modele.specialite.couleur)
                }
                .opacity(apparu ? 1 : 0)
                .offset(y: apparu ? 0 : 12)
                .animation(.spring(duration: 0.5).delay(1.0 + 0.15 * Double(index)), value: apparu)
            }
        }
        .padding(12)
        .background(Charte.marine.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Charte.or.opacity(0.35), lineWidth: 1))
    }
}

/// Pastille dorée « Niveau +1 », qui pulse.
struct BadgeNiveau: View {
    let texte: String
    /// Vrai pour un niveau perdu : badge rouge, flèche vers le bas.
    var baisse = false

    private var couleur: Color { baisse ? .red : Charte.or }

    var body: some View {
        Label(texte, systemImage: baisse ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
            .font(.nom(11, relativeTo: .caption2))
            .foregroundStyle(baisse ? Color.white : Charte.marine)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(couleur, in: Capsule())
            .phaseAnimator([false, true]) { vue, fort in
                vue.scaleEffect(fort ? 1.08 : 1).shadow(color: couleur.opacity(fort ? 0.8 : 0.2), radius: fort ? 8 : 2)
            } animation: { _ in .easeInOut(duration: 0.8) }
    }
}
