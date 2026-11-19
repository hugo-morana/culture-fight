import SwiftUI

struct CombatView: View {
    let controleur: CombatController
    let rejouer: () -> Void
    let accueil: () -> Void

    @State private var confirmerAbandon = false

    var body: some View {
        VStack(spacing: 12) {
            entete
            CarteCamp(camp: controleur.combat.camps[1], estEnHaut: true)
            ScrollView {
                zoneCentrale
                    .padding(.vertical, 4)
            }
            CarteCamp(camp: controleur.combat.camps[0], estEnHaut: false)
        }
        .padding()
        .task { controleur.demarrer() }
        .confirmationDialog("Abandonner le combat ?", isPresented: $confirmerAbandon, titleVisibility: .visible) {
            Button("Abandonner", role: .destructive) {
                controleur.abandonner()
                accueil()
            }
        } message: {
            Text("Un abandon compte comme une défaite, sans gain.")
        }
    }

    private var entete: some View {
        HStack {
            Text("Tour \(min(controleur.combat.tour + 1, Regles.toursMax))/\(Regles.toursMax)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
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
                   pieces: controleur.piecesGagnees,
                   rejouer: rejouer,
                   accueil: accueil)
        }
    }
}

// MARK: - Camps

struct CarteCamp: View {
    let camp: Camp
    let estEnHaut: Bool

    var body: some View {
        let actif = camp.actif
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Avatar(modele: actif.modele, taille: 64)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(actif.modele.nom).font(.headline)
                        Spacer()
                        Text("\(actif.pv)/\(actif.modele.pvMax) PV")
                            .font(.subheadline.monospacedDigit())
                    }
                    BarrePV(pv: actif.pv, pvMax: actif.modele.pvMax)
                    HStack(spacing: 6) {
                        Text("\(actif.modele.style) · \(actif.modele.specialite.nom)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if actif.bouclier > 0 {
                            Image(systemName: "shield.fill")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                        }
                        jauge(actif)
                    }
                }
            }
            HStack(spacing: 6) {
                Text(camp.nom).font(.caption.bold())
                ForEach(camp.combattants) { c in
                    Circle()
                        .fill(c.estKO ? Color.gray.opacity(0.4) : c.modele.specialite.couleur)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.white, lineWidth: c.id == actif.id ? 2 : 0))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06)))
    }

    /// Jauge de Savoir : 3 cases, ou un éclair quand la capacité est prête.
    @ViewBuilder
    private func jauge(_ c: CombattantEnJeu) -> some View {
        if c.capacitePrete {
            Label("Prêt", systemImage: "bolt.fill")
                .font(.caption2.bold())
                .foregroundStyle(.yellow)
        } else {
            HStack(spacing: 3) {
                ForEach(0..<Regles.jaugeMax, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < c.jauge ? Color.yellow : Color.white.opacity(0.15))
                        .frame(width: 12, height: 6)
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
            ProgressView(value: max(0, tempsRestant), total: tempsTotal)
                .tint(tempsRestant < 5 ? Color.red : Color.orange)
            Text(question.enonce)
                .font(.title3.bold())
                .fixedSize(horizontal: false, vertical: true)
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
                .opacity(retires.contains(i) ? 0.25 : 1)
            }
            if !joueurRepond {
                Label("L'adversaire réfléchit…", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Résultat

struct VueResultat: View {
    let resultat: ResultatTour
    let continuer: () -> Void

    private var titre: String {
        if resultat.reponse == nil { return "Temps écoulé !" }
        return resultat.correct ? "Bonne réponse !" : "Mauvaise réponse"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titre)
                .font(.title2.bold())
                .foregroundStyle(resultat.correct ? Color.green : Color.red)
            Text(resultat.question.enonce)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Réponse : \(resultat.question.texteBonneReponse)")
                .font(.headline)
            Text(resultat.question.explication)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

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

            Button(action: continuer) {
                Text("Suivant")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            .padding(.top, 6)
        }
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
    let pieces: Int
    let rejouer: () -> Void
    let accueil: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(titre)
                .font(.largeTitle.bold())
            Label("+\(pieces) Pièces", systemImage: "dollarsign.circle.fill")
                .font(.title3)
                .foregroundStyle(.yellow)
            Button(action: rejouer) {
                Text("Rejouer").font(.headline).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
            Button("Accueil", action: accueil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
