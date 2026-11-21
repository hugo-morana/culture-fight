import Foundation

/// Tenues alternatives (game design, Album) : compléter un style (tous les ninjas…) débloque une tenue
/// alternative pour les combattants de ce style qui en ont une.
/// Une tenue est une ancienne illustration gardée quand le combattant a été redessiné :
/// `Resources/tenue-<id>.jpg`. Le choix porté est mémorisé sur l'appareil.
enum Tenues {
    private static let cle = "tenuesPortees"

    /// Le combattant a-t-il une tenue alternative ?
    static func existe(pour id: String) -> Bool {
        Illustrations.partage.ressource("tenue-\(id)", type: "jpg") != nil
    }

    /// Combattants jouables du même style que `modele`.
    static func membresDuStyle(de modele: ModeleCombattant) -> [ModeleCombattant] {
        Catalogue.prototype.filter { $0.style == modele.style }
    }

    /// Nombre de combattants du style possédés, et nombre total.
    static func progression(de modele: ModeleCombattant, possedes: Set<String>) -> (possedes: Int, total: Int) {
        let membres = membresDuStyle(de: modele)
        return (membres.filter { possedes.contains($0.id) }.count, membres.count)
    }

    /// La tenue est débloquée quand le style est complet, ou si elle a déjà été portée
    /// (un nouveau combattant du même style ajouté plus tard ne la reprend pas).
    static func debloquee(_ modele: ModeleCombattant, possedes: Set<String>) -> Bool {
        if portee(modele.id) { return true }
        let p = progression(de: modele, possedes: possedes)
        return p.total > 0 && p.possedes == p.total
    }

    static func portee(_ id: String) -> Bool {
        (UserDefaults.standard.stringArray(forKey: cle) ?? []).contains(id)
    }

    static func porter(_ id: String, _ oui: Bool) {
        var ids = Set(UserDefaults.standard.stringArray(forKey: cle) ?? [])
        if oui { ids.insert(id) } else { ids.remove(id) }
        UserDefaults.standard.set(Array(ids).sorted(), forKey: cle)
        // Compteur observé par les vues (@AppStorage) pour redessiner les illustrations.
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "tenuesVersion") + 1, forKey: "tenuesVersion")
    }
}
