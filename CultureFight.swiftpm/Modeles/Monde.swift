import Foundation

/// Le monde de Culture Fight (`Resources/monde.json`) et l'histoire de chaque combattant
/// (`Resources/histoires.json`). Vérifiés par `outils/verifier.py`.
struct Lieu: Decodable, Sendable, Hashable {
    let nom: String
    let description: String
    /// Position sur la carte de Culturia, de 0 à 1 (écrite par `outils/placer_carte.py`).
    let x: Double?
    let y: Double?
}

struct PaysDuMonde: Decodable, Sendable, Identifiable {
    let id: String
    let nom: String
    let domaine: String
    let capitale: String
    let description: String
    let lieux: [Lieu]
    /// Centre et rayon du pays sur la carte de Culturia, de 0 à 1.
    let x: Double?
    let y: Double?
    let rayon: Double?

    func lieu(_ nom: String) -> Lieu? { lieux.first { $0.nom == nom } }
}

struct Monde: Decodable, Sendable {
    let nom: String
    let description: String
    let agora: Lieu
    let pays: [PaysDuMonde]
}

struct HistoireCombattant: Decodable, Sendable {
    let id: String
    let pays: String
    let lieu: String
    let histoire: String
    let liens: [String]
}

/// Une source d'un jeu de données (`Resources/sources.json`, écrit par `outils/sources.py`).
struct SourceDonnees: Decodable, Sendable, Hashable {
    let titre: String
    let url: String
}

enum Univers {
    static let monde: Monde? = lire("monde")

    static let histoires: [String: HistoireCombattant] = {
        let liste: [HistoireCombattant] = lire("histoires") ?? []
        return Dictionary(liste.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }()

    static let sources: [String: [SourceDonnees]] = {
        struct Jeu: Decodable { let id: String; let sources: [SourceDonnees] }
        let liste: [Jeu] = lire("sources") ?? []
        return Dictionary(liste.map { ($0.id, $0.sources) }, uniquingKeysWith: { a, _ in a })
    }()

    /// Accroche et blagues de chaque combattant (`Resources/accroches.json`).
    static let accroches: [String: AccrocheCombattant] = {
        let liste: [AccrocheCombattant] = lire("accroches") ?? []
        return Dictionary(liste.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
    }()

    static func pays(_ id: String) -> PaysDuMonde? { monde?.pays.first { $0.id == id } }

    private static func lire<T: Decodable>(_ nom: String) -> T? {
        guard let url = Bundle.module.url(forResource: nom, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

/// Une ligne qui donne envie de jouer le combattant, et une ou deux blagues sur lui.
struct AccrocheCombattant: Decodable, Sendable {
    let id: String
    let accroche: String
    let blagues: [String]
}

extension ModeleCombattant {
    var histoire: HistoireCombattant? { Univers.histoires[id] }
    var accroche: String? { Univers.accroches[id]?.accroche }
    var blagues: [String] { Univers.accroches[id]?.blagues ?? [] }

    /// 2 ou 3 questions d'exemple aux énoncés différents (un par modèle d'énoncé), de difficulté croissante.
    func exemplesDeQuestions(_ nombre: Int = 3) -> [Question] {
        var retenues: [Question] = []
        var debuts: Set<String> = []
        for essai in 0..<30 where retenues.count < nombre {
            let d = min(7, max(1, difficulte + essai % 3 - 1))
            let q = generateur.generer(difficulte: d, exclues: Set(retenues.map(\.id)))
            let debut = q.enonce.split(separator: " ").prefix(3).joined(separator: " ")
            if debuts.insert(debut).inserted { retenues.append(q) }
        }
        if retenues.count < 2 {
            for _ in 0..<10 where retenues.count < 2 {
                let q = generateur.generer(difficulte: difficulte, exclues: Set(retenues.map(\.id)))
                if !retenues.contains(where: { $0.id == q.id }) { retenues.append(q) }
            }
        }
        return retenues
    }
    var paysDOrigine: PaysDuMonde? { histoire.flatMap { Univers.pays($0.pays) } }
}
