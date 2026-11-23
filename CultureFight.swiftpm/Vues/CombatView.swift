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
    /// Animation d'attaque en cours, dans le style de l'attaquant.
    @State private var attaque: AttaqueJouee?
    @State private var attaquesJouees = 0
    /// Compteur par camp : le combattant actif prend son élan quand il pose sa question.
    @State private var elans = [0, 0]
    /// Gestes des illustrations par camp : coup donné, esquive, coup encaissé.
    @State private var coups = [0, 0]
    @State private var esquives = [0, 0]
    @State private var touches = [0, 0]
    @Environment(\.accessibilityReduceMotion) private var mouvementReduit
    /// Présentation des deux équipes avec le « VS », puis pile ou face, avant la première question.
    @State private var presentation = true
    @State private var pileOuFace = false

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
                      variation: controleur.variations[1],
                      elan: elans[1],
                      delaiImpact: delaiImpact(camp: 1),
                      role: role(camp: 1), enBas: false,
                      coups: coups[1], esquives: esquives[1], touches: touches[1],
                      reduit: mouvementReduit)
                .zIndex(role(camp: 1) == .attaque ? 1 : 0)
                .anchorPreference(key: CadresCamps.self, value: .bounds) { [1: $0] }
            // Question et résultat toujours lisibles sans défiler : la zone se réduit si elle déborde.
            AjusteSansDefilement {
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
            BarreObjets(controleur: controleur)
            CarteCamp(camp: controleur.combat.camps[0],
                      impacts: controleur.impacts[0],
                      variation: controleur.variations[0],
                      elan: elans[0],
                      delaiImpact: delaiImpact(camp: 0),
                      role: role(camp: 0), enBas: true,
                      coups: coups[0], esquives: esquives[0], touches: touches[0],
                      reduit: mouvementReduit)
                .zIndex(role(camp: 0) == .attaque ? 1 : 0)
                .anchorPreference(key: CadresCamps.self, value: .bounds) { [0: $0] }
        }
        .padding()
        .overlayPreferenceValue(CadresCamps.self) { cadres in
            GeometryReader { geo in
                if let attaque, let depuis = cadres[attaque.depuis], let vers = cadres[attaque.vers] {
                    CoucheAttaque(attaque: attaque,
                                  depart: Self.avatar(geo[depuis]),
                                  arrivee: Self.avatar(geo[vers]))
                }
            }
        }
        .modifier(SecousseAttaque(declencheur: attaquesJouees, force: attaque?.famille.secousse ?? 0))
        .onChange(of: clePhase) { _, _ in reagirALaPhase() }
        .task(id: attaque?.id) {
            guard let id = attaque?.id else { return }
            try? await Task.sleep(for: .seconds(TempsAttaque.duree))
            if attaque?.id == id { attaque = nil }
        }
        .overlay {
            if controleur.estFini && controleur.estVictoire {
                Confettis().ignoresSafeArea()
            }
        }
        .overlay {
            if pileOuFace {
                PileOuFaceView(joueurCommence: controleur.joueurCommence, reduit: mouvementReduit)
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
            }
        }
        .overlay {
            if presentation {
                PresentationEquipesView(joueur: controleur.combat.camps[0], adversaire: controleur.combat.camps[1],
                                        reduit: mouvementReduit)
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.easeOut(duration: 0.3)) { presentation = false } }
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .task {
            // Présentation des équipes (un toucher la passe), puis pile ou face, puis la première question.
            let fin = Date().addingTimeInterval(PresentationEquipesView.duree(reduit: mouvementReduit))
            while presentation && Date() < fin {
                try? await Task.sleep(for: .seconds(0.1))
            }
            withAnimation(.easeOut(duration: 0.35)) {
                presentation = false
                pileOuFace = true
            }
            try? await Task.sleep(for: .seconds(mouvementReduit ? 1.6 : 2.8))
            withAnimation(.easeOut(duration: 0.35)) { pileOuFace = false }
            controleur.demarrer()
        }
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
            Text("Un abandon compte comme une défaite : aucune Pièce, et tu perds du Savoir.")
        }
    }

    /// Centre de l'illustration d'une carte de camp (à gauche, `PortraitCombat.taille`, 12 de marge).
    private static func avatar(_ cadre: CGRect) -> CGPoint {
        CGPoint(x: cadre.minX + 12 + PortraitCombat.taille.width / 2, y: cadre.minY + 12 + PortraitCombat.taille.height / 2)
    }

    /// Le camp que vise l'attaque du résultat affiché : il tremble à l'arrivée du coup, pas avant.
    private func campVise(_ resultat: ResultatTour) -> Int? {
        let defenseur = resultat.defenseurEstJoueur ? 0 : 1
        if resultat.correct { return resultat.degatsContre > 0 ? 1 - defenseur : nil }
        return resultat.degatsDefenseur > 0 || resultat.degatsAbsorbes > 0 ? defenseur : nil
    }

    private func delaiImpact(camp: Int) -> Double {
        guard !mouvementReduit, case .resultat(let resultat) = controleur.phase,
              campVise(resultat) == camp else { return 0 }
        return TempsAttaque.arrivee
    }

    /// Élan à la question ; au résultat, l'attaque sur une mauvaise réponse (une bonne réponse est une esquive).
    /// Rôle d'un camp pendant le tour : attaque pour celui qui pose la question, défense pour l'autre.
    private func role(camp: Int) -> RoleCombat? {
        switch controleur.phase {
        case .question:
            return camp == controleur.combat.attaquant ? .attaque : .defense
        case .resultat(let resultat):
            let defenseur = resultat.defenseurEstJoueur ? 0 : 1
            return camp == defenseur ? .defense : .attaque
        default:
            return nil
        }
    }

    /// Gestes des illustrations au résultat : l'attaquant s'élance ; le défenseur esquive (bonne réponse)
    /// ou encaisse (mauvaise réponse) ; s'il riposte aussitôt, il s'élance à son tour.
    private func animerLesIllustrations(_ resultat: ResultatTour) {
        let defenseur = resultat.defenseurEstJoueur ? 0 : 1
        let attaquant = 1 - defenseur
        coups[attaquant] += 1
        if resultat.correct {
            esquives[defenseur] += 1
            if resultat.degatsContre > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { coups[defenseur] += 1 }
            }
        } else if resultat.degatsDefenseur > 0 || resultat.degatsAbsorbes > 0 {
            touches[defenseur] += 1
        }
    }

    private func reagirALaPhase() {
        switch controleur.phase {
        case .question:
            elans[controleur.combat.attaquant] += 1
        case .resultat(let resultat):
            animerLesIllustrations(resultat)
            guard let vise = campVise(resultat) else { return }
            let tireur = 1 - vise
            let famille = controleur.combat.camps[tireur].actif.modele.familleStyle
            guard !mouvementReduit else {
                ServiceSons.partage.jouer(.impact)
                return
            }
            ServiceSons.partage.jouer(.attaque(famille))
            attaquesJouees += 1
            attaque = AttaqueJouee(id: attaquesJouees,
                                   famille: famille,
                                   depuis: tireur, vers: vise, debut: .now)
        default:
            break
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
                            joueurAttaque: controleur.joueurAttaque,
                            reponseAttaque: controleur.reponseAttaque,
                            attaqueFinie: controleur.attaqueFinie,
                            repondre: { controleur.repondre($0) },
                            repondreAttaque: { controleur.repondreAttaque($0) },
                            passer: { controleur.passerAttaque() })
            }
        case .resultat(let resultat):
            VueResultat(resultat: resultat,
                        campChangeable: controleur.campQuiPeutChanger.map { controleur.combat.camps[$0] },
                        changer: { controleur.changerCombattant($0) },
                        continuer: { controleur.continuer() })
        case .fin:
            VueFin(titre: controleur.titreFin,
                   victoire: controleur.estVictoire,
                   bilan: controleur.bilan,
                   niveauxGagnes: controleur.niveauxGagnes,
                   niveauxCompteGagnes: controleur.niveauxCompteGagnes,
                   savoirAvant: controleur.savoirAvant,
                   savoirApres: controleur.savoirApres,
                   evolutions: controleur.evolutions,
                   historique: controleur.historique,
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
    /// Augmente quand le combattant actif pose sa question.
    var elan: Int = 0
    /// Attente avant de trembler, le temps que l'attaque arrive.
    var delaiImpact: Double = 0
    /// Rôle du camp pendant le tour, et gestes de son illustration.
    var role: RoleCombat? = nil
    var enBas = false
    var coups = 0
    var esquives = 0
    var touches = 0
    var reduit = false

    var body: some View {
        let actif = camp.actif
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                HStack(spacing: 12) {
                    PortraitCombat(modele: actif.modele, estKO: actif.estKO, role: role, enBas: enBas,
                                   coups: coups, esquives: esquives, touches: touches, reduit: reduit)
                        .overlay {
                            if actif.estKO {
                                Text("K.O.")
                                    .font(.titre(18, relativeTo: .headline))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red, in: RoundedRectangle(cornerRadius: 4))
                                    .rotationEffect(.degrees(-14))
                                    .transition(.scale(scale: 2.2).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(duration: 0.35, bounce: 0.5).delay(0.4), value: actif.estKO)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(actif.nom).font(.nom(18)).lineLimit(1).minimumScaleFactor(0.7)
                            Spacer()
                            Text("\(actif.pv)/\(actif.pvMax) PV")
                                .font(.subheadline.monospacedDigit())
                                .contentTransition(.numericText(value: Double(actif.pv)))
                                .animation(.snappy(duration: 0.5), value: actif.pv)
                        }
                        BarrePV(pv: actif.pv, pvMax: actif.pvMax)
                        HStack(spacing: 6) {
                            Text(actif.modele.sousTitre)
                                .font(.nom(12, relativeTo: .caption))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if actif.riposte > 1 {
                                Label("+\(Int(((actif.riposte - 1) * 100).rounded())) %", systemImage: "arrow.uturn.forward.circle.fill")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.orange)
                                    .symbolEffect(.pulse)
                                    .accessibilityLabel("Riposte prête : prochaine attaque renforcée")
                                    .transition(.scale.combined(with: .opacity))
                            }
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
        .modifier(EffetImpact(declencheur: impacts, variation: variation, delai: delaiImpact))
        .overlay(alignment: .topLeading) {
            ElanAttaque(declencheur: elan, picto: actif.modele.familleStyle.picto)
                .padding(.leading, 12 + PortraitCombat.taille.width / 2 - 17)
                .padding(.top, 12 + PortraitCombat.taille.height / 2 - 30)
        }
        .overlay(alignment: .topTrailing) {
            ChiffreEnvole(declencheur: impacts, variation: variation, delai: delaiImpact)
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
    /// Le joueur attaque : il peut répondre en secret à sa propre question, ou passer.
    var joueurAttaque = false
    var reponseAttaque: Int? = nil
    var attaqueFinie = false
    let repondre: (Int) -> Void
    var repondreAttaque: (Int) -> Void = { _ in }
    var passer: () -> Void = {}

    @State private var apparu = false

    private var urgence: Bool { tempsRestant < 5 }

    private var bonusTexte: String { "\(Int(Regles.bonusQuestionneur * 100)) %" }
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
                Text("Chrono réduit de \(Int(malusTemps)) s (Pression ou Créature)")
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
            if joueurAttaque && !attaqueFinie {
                Label("Réponds aussi, en secret : juste, +\(bonusTexte) de dégâts si l'adversaire se trompe ; faux, −\(bonusTexte). Passe si tu n'es pas sûr.",
                      systemImage: "person.fill.questionmark")
                    .font(.caption)
                    .foregroundStyle(Charte.or)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(question.choix.indices, id: \.self) { i in
                // En attaque, le joueur voit les 4 choix : les choix retirés ne concernent que le défenseur.
                let retire = !joueurAttaque && retires.contains(i)
                let choisi = joueurAttaque && reponseAttaque == i
                Button {
                    if joueurAttaque { repondreAttaque(i) } else { repondre(i) }
                } label: {
                    HStack {
                        Text(question.choix[i])
                            .font(.body.weight(.semibold))
                        if choisi { Image(systemName: "lock.fill").font(.caption) }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(choisi ? Charte.or : nil)
                .disabled(joueurAttaque ? attaqueFinie : (!joueurRepond || retire))
                .opacity(apparu ? (retire ? 0.25 : (joueurAttaque && attaqueFinie && !choisi ? 0.5 : 1)) : 0)
                .offset(y: apparu ? 0 : 24)
                .animation(.spring(duration: 0.45, bounce: 0.35).delay(0.08 + Double(i) * 0.07), value: apparu)
            }
            if joueurAttaque && !attaqueFinie {
                Button(action: passer) {
                    Label("Passer", systemImage: "forward.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            if joueurAttaque && attaqueFinie {
                Text(reponseAttaque == nil ? "Tu as passé : dégâts normaux." : "Réponse enregistrée, révélée avec celle de l'adversaire.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !joueurRepond {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .symbolEffect(.pulse)
                    Text("L'adversaire réfléchit")
                    PointsDeSuspension()
                }
                .font(.headline)
                .foregroundStyle(Charte.ivoire)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("L'adversaire réfléchit")
            }
        }
        .onAppear { apparu = true }
    }
}

// MARK: - Ajustement sans défilement

/// Hauteur naturelle du contenu de `AjusteSansDefilement`.
private struct HauteurContenu: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Affiche son contenu en entier dans la place disponible, sans défilement :
/// s'il est trop haut, il est réduit (jusqu'à 60 %), aligné en haut.
struct AjusteSansDefilement<Contenu: View>: View {
    @ViewBuilder let contenu: Contenu
    @State private var hauteur: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let dispo = geo.size.height
            let echelle = hauteur > dispo && hauteur > 0 ? max(0.6, dispo / hauteur) : 1
            contenu
                .fixedSize(horizontal: false, vertical: true)
                .background(GeometryReader { g in
                    Color.clear.preference(key: HauteurContenu.self, value: g.size.height)
                })
                .frame(width: geo.size.width, alignment: .top)
                .scaleEffect(echelle, anchor: .top)
                .frame(width: geo.size.width, height: dispo, alignment: .top)
        }
        .onPreferenceChange(HauteurContenu.self) { hauteur = $0 }
    }
}

// MARK: - Résultat

struct VueResultat: View {
    let resultat: ResultatTour
    /// Le camp du joueur s'il peut changer de combattant avant son tour (nil sinon).
    var campChangeable: Camp? = nil
    var changer: (Int) -> Void = { _ in }
    let continuer: () -> Void

    @State private var apparu = false

    private var joueurDefend: Bool { resultat.defenseurEstJoueur }

    /// Bon pour le joueur : il a esquivé, ou l'adversaire a été touché.
    private var bonPourJoueur: Bool { resultat.correct == joueurDefend }

    private var titre: String {
        if resultat.correct && resultat.degatsContre > 0 {
            return joueurDefend ? "Esquive et Contre !" : "L'adversaire esquive et contre !"
        }
        if resultat.correct { return joueurDefend ? "Esquive !" : "L'adversaire a trouvé : esquive" }
        if resultat.reponse == nil { return joueurDefend ? "Temps écoulé : touché !" : "Temps écoulé : touché !" }
        return joueurDefend ? "Touché !" : "L'adversaire s'est trompé : touché !"
    }

    private var icone: String {
        if resultat.correct { return "figure.run" }
        if resultat.reponse == nil { return "timer" }
        return "burst.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icone)
                    .font(.title)
                    .symbolEffect(.bounce, value: apparu)
                Text(titre)
                    .font(.titre(22, relativeTo: .title2))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(bonPourJoueur ? Color.green : Color.red)
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
                    if choisie {
                        etiquette(joueurDefend ? "Toi" : "Adversaire", couleur: bonne ? .green : .red)
                    }
                    if resultat.questionneurARepondu && i == resultat.reponseQuestionneur {
                        etiquette(joueurDefend ? "Adversaire" : "Toi", couleur: Charte.or)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(bonne ? Color.green.opacity(0.22) : (choisie ? Color.red.opacity(0.22) : Color.white.opacity(0.05))))
                .scaleEffect(bonne && apparu ? 1.02 : 1)
                .animation(.spring(duration: 0.5, bounce: 0.5).delay(0.15), value: apparu)
            }

            LeSavaisTu(texte: resultat.question.explication)
                .opacity(apparu ? 1 : 0)
                .offset(y: apparu ? 0 : 8)
                .animation(.easeOut(duration: 0.35).delay(0.2), value: apparu)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                if resultat.correct {
                    ligne(resultat.degatsContre > 0
                          ? "\(resultat.defenseurNom) esquive et contre \(resultat.attaquantNom)"
                          : "\(resultat.defenseurNom) esquive : personne ne perd de PV", "figure.run")
                    if let effet = resultat.effetVitesse {
                        ligne(effet, "bolt.horizontal.fill")
                    } else if let r = resultat.riposteGagnee {
                        ligne("Riposte : la prochaine attaque de \(resultat.defenseurNom) fera +\(Int(((r - 1) * 100).rounded())) %", "arrow.uturn.forward")
                    }
                    if resultat.jaugeRemplie {
                        ligne("Inspiration pleine : \(resultat.defenseurNom) fera double dégâts à sa prochaine attaque", "bolt.fill")
                    }
                } else {
                    ligne("\(resultat.defenseurNom) perd \(resultat.degatsDefenseur) PV", "burst.fill")
                    if resultat.riposteUtilisee {
                        ligne("Riposte : \(resultat.attaquantNom) frappe plus fort", "arrow.uturn.forward")
                    }
                    if resultat.degatsAbsorbes > 0 {
                        ligne("Bouclier : \(resultat.degatsAbsorbes) PV absorbés", "shield.fill")
                    }
                    if resultat.capaciteUtilisee {
                        ligne("Coup de maître : dégâts doublés", "bolt.fill")
                    }
                }
                if let ligneQ = ligneQuestionneur {
                    ligne(ligneQ.texte, ligneQ.icone)
                        .foregroundStyle(ligneQ.bonne ? Color.green : Color.orange)
                }
                if resultat.koDefenseur {
                    ligne("\(resultat.defenseurNom) est K.O. !", "xmark.octagon.fill")
                }
            }
            .opacity(apparu ? 1 : 0)
            .offset(y: apparu ? 0 : 12)
            .animation(.easeOut(duration: 0.4).delay(0.25), value: apparu)

            if let camp = campChangeable {
                choixCombattant(camp)
            }

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
        .sensoryFeedback(bonPourJoueur ? .success : .error, trigger: apparu)
        .onAppear { apparu = true }
    }

    /// Qui pose la prochaine question : le combattant actif reste par défaut ; toucher un autre
    /// combattant debout le fait entrer (pour sauver un combattant presque K.O., par exemple).
    private func choixCombattant(_ camp: Camp) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Ton prochain combattant", systemImage: "arrow.left.arrow.right")
                .font(.footnote.bold())
                .foregroundStyle(Charte.or)
            HStack(spacing: 6) {
                ForEach(camp.combattants.indices, id: \.self) { i in
                    let c = camp.combattants[i]
                    let actif = i == camp.indexActif
                    Button { changer(i) } label: {
                        VStack(spacing: 2) {
                            Text(c.nom)
                                .font(.caption.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(c.estKO ? "K.O." : "\(max(0, c.pv))/\(c.pvMax) PV")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(c.estKO ? Color.secondary
                                                 : (Double(c.pv) < Double(c.pvMax) * 0.3 ? Color.red : Charte.ivoire))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(actif ? Charte.or.opacity(0.3) : Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(actif ? Charte.or : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(c.estKO || actif)
                    .accessibilityLabel("\(c.nom), \(c.estKO ? "K.O." : "\(max(0, c.pv)) PV sur \(c.pvMax)")\(actif ? ", en jeu" : "")")
                }
            }
        }
        .animation(.snappy, value: camp.indexActif)
    }

    private func etiquette(_ texte: String, couleur: Color) -> some View {
        Text(texte)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(couleur.opacity(0.25), in: Capsule())
            .foregroundStyle(couleur)
    }

    /// Ce qu'a changé la réponse du questionneur à sa propre question, chiffré.
    private var ligneQuestionneur: (texte: String, icone: String, bonne: Bool)? {
        guard let juste = resultat.questionneurCorrect else {
            return joueurDefend ? nil : ("Tu as passé ta question : dégâts normaux", "forward.fill", true)
        }
        let qui = joueurDefend
            ? "\(resultat.attaquantNom) \(juste ? "a bien répondu" : "s'est trompé") à sa propre question"
            : "Tu \(juste ? "as bien répondu" : "t'es trompé") à ta propre question"
        let effet: String
        if resultat.correct {
            effet = "sans effet, l'adversaire a esquivé"
        } else {
            let p = Int(Regles.bonusQuestionneur * 100)
            effet = "\(juste ? "+" : "−")\(p) % (\(resultat.degatsDefenseur + resultat.degatsAbsorbes) PV au lieu de \(resultat.degatsSansQuestionneur))"
        }
        let xp = !joueurDefend && juste ? " · +\(Gains.xpCombattantBonneReponseAttaque) Savoir" : ""
        let bonnePourJoueur = joueurDefend ? !juste : juste
        return ("\(qui) : \(effet)\(xp)", juste ? "person.fill.checkmark" : "person.fill.xmark", bonnePourJoueur)
    }

    private func ligne(_ texte: String, _ icone: String) -> some View {
        Label(texte, systemImage: icone)
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Fin

struct VueFin: View {
    /// Jingle du résultat, Pièces qui défilent, puis montée de niveau s'il y en a une.
    private func jouerSonsDeFin() {
        let sons = ServiceSons.partage
        if ServiceSons.effetsActifs { ServiceAudio.partage.attenuer(pendant: 3.8) }
        if victoire { sons.jouer(.victoire) }
        else if titre == "Match nul" { sons.jouer(.nul) }
        else { sons.jouer(.defaite) }
        if bilan.pieces > 0 { sons.jouer(.pieces, apres: 0.5) }
        if niveauxCompteGagnes > 0 || niveauxGagnes.values.contains(where: { $0 > 0 }) {
            sons.jouer(.niveau, apres: 1.8)
        }
    }

    let titre: String
    let victoire: Bool
    let bilan: BilanCombat
    let niveauxGagnes: [String: Int]
    let niveauxCompteGagnes: Int
    /// Savoir total avant et après le combat (nil tant que la sauvegarde ne l'a pas versé).
    var savoirAvant: Int? = nil
    var savoirApres: Int? = nil
    var evolutions: [EvolutionCombattant] = []
    let historique: [ResultatTour]
    let rejouer: () -> Void
    let accueil: () -> Void

    @State private var apparu = false
    @State private var piecesAffichees = 0
    @State private var revue = false
    @State private var evolutionMontree = 0

    private var aRefaire: Int { Revue.aRefaire(historique).count }

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
                boutonRevue
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
            jouerSonsDeFin()
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                piecesAffichees = bilan.pieces
            }
        }
        .overlay {
            if evolutionMontree < evolutions.count {
                SequenceEvolution(evolution: evolutions[evolutionMontree]) {
                    withAnimation(.easeOut(duration: 0.3)) { evolutionMontree += 1 }
                }
                .id(evolutionMontree)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $revue) {
            RevuePartieView(historique: historique)
        }
    }

    private var boutonRevue: some View {
        Button {
            revue = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .symbolEffect(.bounce, value: apparu)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Revue de la partie")
                        .font(.titre(17, relativeTo: .headline))
                    Text(aRefaire == 0
                         ? "Précision \(Revue.precision(historique, joueur: true)) % · aucune question à refaire"
                         : "Précision \(Revue.precision(historique, joueur: true)) % · \(aRefaire) question\(aRefaire > 1 ? "s" : "") à refaire")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Charte.marine.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyan.opacity(0.6), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Charte.ivoire)
        .opacity(apparu ? 1 : 0)
        .animation(.easeOut(duration: 0.5).delay(0.8), value: apparu)
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
                Label("\(bilan.xpCompte >= 0 ? "+" : "−")\(abs(bilan.xpCompte)) Savoir",
                      systemImage: bilan.xpCompte >= 0 ? "star.circle.fill" : "arrow.down.circle.fill")
                    .font(.nom(15, relativeTo: .headline))
                    .foregroundStyle(bilan.xpCompte >= 0 ? Charte.ivoire : Color.red)
                Spacer()
                if let avant = savoirAvant, let apres = savoirApres {
                    CompteurSavoir(avant: avant, apres: apres)
                }
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
                    Text("+\(gain.xp) Savoir")
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

/// Pièce lancée en l'air au début du combat : elle tourne, retombe et annonce qui commence.
struct PileOuFaceView: View {
    let joueurCommence: Bool
    var reduit = false
    @State private var lancee = false
    @State private var resultat = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("Pile ou face")
                    .font(.titre(18, relativeTo: .headline))
                    .lettrageLogo()
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Charte.or, Color(red: 0.72, green: 0.52, blue: 0.16)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay(Circle().stroke(Charte.ivoire.opacity(0.8), lineWidth: 3).padding(6))
                        .shadow(color: Charte.or.opacity(0.6), radius: resultat ? 24 : 8)
                    Image(systemName: joueurCommence ? "person.fill" : "cpu")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Charte.marine)
                        .opacity(resultat ? 1 : 0)
                }
                .frame(width: 120, height: 120)
                .rotation3DEffect(.degrees(lancee ? 1800 : 0), axis: (x: 1, y: 0, z: 0))
                .offset(y: lancee && !resultat ? -120 : 0)
                .scaleEffect(resultat ? 1.15 : 1)
                Text(joueurCommence ? "Tu commences !" : "L'adversaire commence")
                    .font(.titre(24, relativeTo: .title))
                    .foregroundStyle(Charte.ivoire)
                    .opacity(resultat ? 1 : 0)
                    .scaleEffect(resultat ? 1 : 0.6)
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: resultat)
        .task {
            if reduit {
                resultat = true
                return
            }
            withAnimation(.easeOut(duration: 0.6)) { lancee = true }
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.spring(duration: 0.7, bounce: 0.45)) { resultat = true }
        }
    }
}

/// Encadré « Le savais-tu ? » sous les choix : l'explication de la question, mise à part (retour bêta n° 5).
struct LeSavaisTu: View {
    let texte: String

    var body: some View {
        if !texte.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Label("Le savais-tu ?", systemImage: "lightbulb.fill")
                    .font(.titre(15, relativeTo: .headline))
                    .foregroundStyle(Charte.or)
                Text(texte)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Charte.ivoire)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Charte.or.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Charte.or.opacity(0.45), lineWidth: 1))
        }
    }
}

/// Trois points qui rebondissent l'un après l'autre, tant que la vue est affichée.
struct PointsDeSuspension: View {
    @Environment(\.accessibilityReduceMotion) private var mouvementReduit

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.15)) { contexte in
            let pas = Int(contexte.date.timeIntervalSinceReferenceDate / 0.15) % 8
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .frame(width: 6, height: 6)
                        .offset(y: !mouvementReduit && pas == i * 2 ? -5 : 0)
                        .opacity(mouvementReduit ? 1 : (pas >= i * 2 ? 1 : 0.35))
                        .animation(.spring(duration: 0.25, bounce: 0.5), value: pas)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Savoir total qui défile chiffre par chiffre de sa valeur d'avant le combat à la nouvelle.
struct CompteurSavoir: View {
    let avant: Int
    let apres: Int
    @State private var affiche: Int?
    @Environment(\.accessibilityReduceMotion) private var mouvementReduit

    var body: some View {
        let valeur = affiche ?? avant
        HStack(spacing: 4) {
            Image(systemName: "book.closed.fill")
            Text("\(valeur)")
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(valeur)))
        }
        .font(.nom(15, relativeTo: .headline))
        .foregroundStyle(apres >= avant ? Charte.or : Color.red)
        .accessibilityLabel("Savoir : \(apres)")
        .task(id: apres) {
            affiche = avant
            guard !mouvementReduit, avant != apres else { affiche = apres; return }
            try? await Task.sleep(for: .seconds(0.8))
            let ecart = apres - avant
            let pas = 24
            for i in 1...pas {
                try? await Task.sleep(for: .milliseconds(45))
                // Ralentit à l'approche de la valeur finale.
                let t = 1 - pow(1 - Double(i) / Double(pas), 2)
                withAnimation(.snappy(duration: 0.12)) { affiche = avant + Int((Double(ecart) * t).rounded()) }
            }
            withAnimation(.snappy) { affiche = apres }
        }
    }
}
