import SwiftUI
import SafariServices

/// Une page à ouvrir dans le navigateur intégré.
struct PageAOuvrir: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// Navigateur intégré (Safari) pour lire la source d'une question ; on revient au jeu d'un geste.
struct PageWeb: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vue = SFSafariViewController(url: url)
        vue.preferredControlTintColor = UIColor(Charte.or)
        vue.dismissButtonStyle = .close
        return vue
    }

    func updateUIViewController(_ vue: SFSafariViewController, context: Context) {}
}
