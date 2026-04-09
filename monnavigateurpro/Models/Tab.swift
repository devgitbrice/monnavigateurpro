import Foundation
import WebKit

@Observable
class Tab: Identifiable {
    let id = UUID()
    var title: String = "Nouvel onglet"
    var url: URL?
    var isLoading: Bool = false
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var estimatedProgress: Double = 0.0
    var favicon: NSImage?
    let webView: WKWebView
    var isPrivate: Bool

    init(url: URL? = nil, isPrivate: Bool = false) {
        self.isPrivate = isPrivate
        let configuration = WKWebViewConfiguration()
        if isPrivate {
            configuration.websiteDataStore = .nonPersistent()
        }
        configuration.preferences.isElementFullscreenEnabled = true
        self.webView = WKWebView(frame: .zero, configuration: configuration)
        self.webView.allowsBackForwardNavigationGestures = true

        if let url = url {
            self.url = url
            self.webView.load(URLRequest(url: url))
        }
    }

    func loadURL(_ url: URL) {
        self.url = url
        webView.load(URLRequest(url: url))
    }

    func loadSearch(_ query: String, engine: SearchEngine) {
        let searchURL = engine.searchURL(for: query)
        loadURL(searchURL)
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }
    func stopLoading() { webView.stopLoading() }
}

enum SearchEngine: String, CaseIterable, Identifiable {
    case google = "Google"
    case bing = "Bing"
    case duckDuckGo = "DuckDuckGo"
    case yahoo = "Yahoo"
    case ecosia = "Ecosia"

    var id: String { rawValue }

    func searchURL(for query: String) -> URL {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch self {
        case .google:
            return URL(string: "https://www.google.com/search?q=\(encoded)")!
        case .bing:
            return URL(string: "https://www.bing.com/search?q=\(encoded)")!
        case .duckDuckGo:
            return URL(string: "https://duckduckgo.com/?q=\(encoded)")!
        case .yahoo:
            return URL(string: "https://search.yahoo.com/search?p=\(encoded)")!
        case .ecosia:
            return URL(string: "https://www.ecosia.org/search?q=\(encoded)")!
        }
    }
}
