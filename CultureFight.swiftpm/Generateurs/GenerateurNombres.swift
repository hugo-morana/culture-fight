import Foundation

/// Questions de nombres générées à l'infini, sans données : additions (Sommuraï), pourcentages
/// (Pourcentinelle), nombres premiers (Premier Dan), chiffres romains (Spartacalcul) et équations
/// du premier degré (Ninjalgèbre). Au moins 60 questions différentes à chaque difficulté.
struct GenerateurNombres: GenerateurQuestions {
    enum Sujet: Sendable {
        case addition, pourcentage, premiers, romains, algebre
    }

    let specialite: Specialite
    let sujet: Sujet

    func generer(difficulte: Int, exclues: Set<String>) -> Question {
        tirerNouvelle(exclues: exclues) {
            let niveau = min(max(difficulte, 1), 3)
            switch sujet {
            case .addition: return addition(niveau, difficulte)
            case .pourcentage: return pourcentage(niveau, difficulte)
            case .premiers: return premiers(niveau, difficulte)
            case .romains: return romains(niveau, difficulte)
            case .algebre: return algebre(niveau, difficulte)
            }
        }
    }

    /// Trois mauvaises réponses entières, différentes de la bonne et strictement positives si demandé.
    private func faux(_ bonne: Int, _ candidats: [Int], positifs: Bool = true) -> [String] {
        var liste: [Int] = []
        for c in candidats.shuffled() + [bonne + 1, bonne + 2, bonne + 3, bonne + 4]
        where c != bonne && !liste.contains(c) && (!positifs || c > 0) {
            liste.append(c)
        }
        return liste.map { String($0) }
    }

    // MARK: - Additions

    private func addition(_ niveau: Int, _ difficulte: Int) -> Question {
        let operandes: (Int, Int)
        switch niveau {
        case 1: operandes = (Int.random(in: 2...20), Int.random(in: 2...20))      // 361
        case 2: operandes = (Int.random(in: 15...60), Int.random(in: 12...45))    // 1 564
        default: operandes = (Int.random(in: 50...150), Int.random(in: 30...99))  // 7 070
        }
        let (a, b) = operandes
        let s = a + b
        return .qcm(id: "add-\(a)+\(b)", specialite: specialite,
                    enonce: "\(a) + \(b) = ?",
                    bonne: String(s),
                    distracteurs: faux(s, [s + 1, s - 1, s + 10, s - 10, s + 2, s - 2, s + 11, s - 9]),
                    difficulte: difficulte,
                    explication: "\(a) + \(b) = \(s).")
    }

    // MARK: - Pourcentages

    private func pourcentage(_ niveau: Int, _ difficulte: Int) -> Question {
        let p: Int
        let n: Int
        switch niveau {
        case 1:   // 5 × 20 = 100
            p = [10, 20, 25, 50, 75].randomElement()!
            n = 20 * Int.random(in: 1...20)
        case 2:   // 6 × 25 = 150
            p = [5, 15, 30, 40, 60, 80].randomElement()!
            n = 20 * Int.random(in: 1...25)
        default:  // 7 × 20 = 140
            p = [12, 35, 45, 65, 85, 120, 150].randomElement()!
            n = 100 * Int.random(in: 1...20)
        }
        let r = p * n / 100
        let dixPourcent = n / 10
        return .qcm(id: "pct-\(p)-\(n)", specialite: specialite,
                    enonce: "Combien font \(p) % de \(n) ?",
                    bonne: String(r),
                    distracteurs: faux(r, [r + dixPourcent, r - dixPourcent, r * 2, r / 2, r + p, n - r,
                                           r + dixPourcent / 2, r - dixPourcent / 2]),
                    difficulte: difficulte,
                    explication: "\(p) % de \(n) = \(n) × \(p) ÷ 100 = \(r).")
    }

    // MARK: - Nombres premiers

    static func estPremier(_ n: Int) -> Bool {
        if n < 2 { return false }
        if n < 4 { return true }
        if n % 2 == 0 { return false }
        var d = 3
        while d * d <= n {
            if n % d == 0 { return false }
            d += 2
        }
        return true
    }

    private static func plusPetitDiviseur(_ n: Int) -> Int {
        var d = 2
        while d * d <= n {
            if n % d == 0 { return d }
            d += 1
        }
        return n
    }

    private func premiers(_ niveau: Int, _ difficulte: Int) -> Question {
        let maximum = [50, 150, 400][niveau - 1]
        let tousPremiers = (2...maximum).filter(Self.estPremier)
        // Composés « piégeux » : impairs dès la difficulté 2, ni multiples de 5 ni de 3 en difficulté 3.
        let composes = (4...maximum).filter { n in
            guard !Self.estPremier(n) else { return false }
            switch niveau {
            case 1: return true
            case 2: return n % 2 == 1
            default: return n % 2 == 1 && n % 5 != 0 && n % 3 != 0
            }
        }
        switch Int.random(in: 0..<3) {
        case 0:
            // Lequel est premier ? (des milliers de combinaisons)
            let p = tousPremiers.filter { niveau == 1 || $0 > 10 }.randomElement() ?? 7
            let trois = Array(composes.shuffled().prefix(3))
            let n = trois.max() ?? 0
            let d = Self.plusPetitDiviseur(n)
            return .qcm(id: "prem-\(p)-\(trois.sorted().map(String.init).joined(separator: "-"))",
                        specialite: specialite,
                        enonce: "Lequel de ces nombres est premier ?",
                        bonne: String(p),
                        distracteurs: trois.map { String($0) },
                        difficulte: difficulte,
                        explication: "\(p) n'est divisible que par 1 et par lui-même. Par exemple, \(n) = \(d) × \(n / d).")
        case 1:
            // Plus petit diviseur premier d'un nombre composé.
            let n = composes.randomElement() ?? 21
            let d = Self.plusPetitDiviseur(n)
            let candidats = [2, 3, 5, 7, 11, 13, 17, 19].filter { $0 != d }
            return .qcm(id: "prem-div-\(n)", specialite: specialite,
                        enonce: "Quel est le plus petit nombre premier qui divise \(n) ?",
                        bonne: String(d),
                        distracteurs: candidats.shuffled().map { String($0) },
                        difficulte: difficulte,
                        explication: "\(n) = \(d) × \(n / d), et aucun nombre premier plus petit que \(d) ne divise \(n).")
        default:
            // Nombre premier suivant.
            let n = Int.random(in: (niveau == 1 ? 1 : 20)...maximum)
            var suivant = n + 1
            while !Self.estPremier(suivant) { suivant += 1 }
            let pieges = [suivant - 2, suivant - 1, suivant + 1, suivant + 2, suivant + 4]
                .filter { $0 > n && $0 != suivant }
            var apres = suivant + 1
            while !Self.estPremier(apres) { apres += 1 }
            return .qcm(id: "prem-suiv-\(n)", specialite: specialite,
                        enonce: "Quel est le premier nombre premier plus grand que \(n) ?",
                        bonne: String(suivant),
                        distracteurs: ([apres] + pieges.shuffled()).map { String($0) },
                        difficulte: difficulte,
                        explication: "Après \(n), le premier nombre divisible seulement par 1 et par lui-même est \(suivant) ; le suivant est \(apres).")
        }
    }

    // MARK: - Chiffres romains

    private static let symboles: [(Int, String)] = [
        (1000, "M"), (900, "CM"), (500, "D"), (400, "CD"), (100, "C"), (90, "XC"),
        (50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]

    static func romain(_ n: Int) -> String {
        var reste = n
        var texte = ""
        for (valeur, symbole) in symboles {
            while reste >= valeur {
                texte += symbole
                reste -= valeur
            }
        }
        return texte
    }

    /// « MCMXC = M (1000) + CM (900) + XC (90) »
    private static func decomposition(_ n: Int) -> String {
        var parts: [String] = []
        var reste = n
        for puissance in [1000, 100, 10, 1] {
            let chiffre = reste / puissance * puissance
            if chiffre > 0 { parts.append("\(romain(chiffre)) (\(chiffre))") }
            reste -= chiffre
        }
        return parts.joined(separator: " + ")
    }

    private func romains(_ niveau: Int, _ difficulte: Int) -> Question {
        let n: Int
        switch niveau {
        case 1: n = Int.random(in: 1...39)        // × 2 sens = 78
        case 2: n = Int.random(in: 40...399)
        default: n = Int.random(in: 400...3999)
        }
        let voisins = [n + 1, n - 1, n + 10, n - 10, n + 5, n - 5, n + 50, n - 50, n + 100, n - 100]
            .filter { $0 > 0 && $0 < 4000 && $0 != n }
        let r = Self.romain(n)
        let explication = "\(r) = \(Self.decomposition(n)) = \(n)."
        if Bool.random() {
            return .qcm(id: "rom-vers-\(n)", specialite: specialite,
                        enonce: "Comment écrit-on \(n) en chiffres romains ?",
                        bonne: r,
                        distracteurs: voisins.shuffled().map(Self.romain),
                        difficulte: difficulte,
                        explication: explication)
        }
        return .qcm(id: "rom-de-\(n)", specialite: specialite,
                    enonce: "Quel nombre s'écrit \(r) en chiffres romains ?",
                    bonne: String(n),
                    distracteurs: voisins.shuffled().map { String($0) },
                    difficulte: difficulte,
                    explication: explication)
    }

    // MARK: - Algèbre

    /// « 3x », « x », « −x »
    private static func terme(_ a: Int) -> String {
        switch a {
        case 1: return "x"
        case -1: return "−x"
        default: return a < 0 ? "−\(-a)x" : "\(a)x"
        }
    }

    /// « + 4 », « − 7 », ou rien pour 0.
    private static func constante(_ b: Int) -> String {
        b == 0 ? "" : (b > 0 ? " + \(b)" : " − \(-b)")
    }

    private static func nombre(_ n: Int) -> String { n < 0 ? "−\(-n)" : String(n) }

    private func algebre(_ niveau: Int, _ difficulte: Int) -> Question {
        let x: Int
        let enonce: String
        let explication: String
        switch niveau {
        case 1:   // x + b = c : 20 × 20 = 400
            x = Int.random(in: 1...20)
            let b = Int.random(in: 1...20)
            enonce = "x + \(b) = \(x + b)"
            explication = "x = \(x + b) − \(b) = \(x)."
        case 2:   // ax + b = c : 8 × 12 × 20 = 1 920
            let a = Int.random(in: 2...9)
            x = Int.random(in: 1...12)
            let b = Int.random(in: 1...10) * (Bool.random() ? 1 : -1)
            let c = a * x + b
            enonce = "\(Self.terme(a))\(Self.constante(b)) = \(Self.nombre(c))"
            explication = "\(Self.terme(a)) = \(Self.nombre(c))\(Self.constante(-b)) = \(Self.nombre(c - b)), donc x = \(Self.nombre(c - b)) ÷ \(a) = \(Self.nombre(x))."
        default:  // ax + b = cx + d, solution entière, parfois négative
            let a = Int.random(in: 3...9)
            let c = Int.random(in: 1..<a)
            x = Int.random(in: -9...12)
            let b = Int.random(in: -12...12)
            let d = (a - c) * x + b
            enonce = "\(Self.terme(a))\(Self.constante(b)) = \(Self.terme(c))\(Self.constante(d))"
            explication = "\(Self.terme(a - c)) = \(Self.nombre(d))\(Self.constante(-b)) = \(Self.nombre(d - b)), donc x = \(Self.nombre(x))."
        }
        return .qcm(id: "alg-\(enonce)", specialite: specialite,
                    enonce: "Résous : \(enonce)",
                    bonne: "x = \(Self.nombre(x))",
                    distracteurs: faux(x, [x + 1, x - 1, x + 2, x - 2, -x, x * 2, x + 10], positifs: false)
                        .map { "x = \(Self.nombre(Int($0) ?? 0))" },
                    difficulte: difficulte,
                    explication: explication)
    }
}
