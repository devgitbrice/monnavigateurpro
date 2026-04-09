import Foundation
import SwiftData
import WebKit
import Combine

@Observable
class BrowserViewModel {
    var tabs: [Tab] = []
    var activeTabID: UUID?
    var addressBarText: String = ""
    var isShowingSidebar: Bool = false
    var isShowingSettings: Bool = false
    var isShowingDownloads: Bool = false
    var isShowingFindInPage: Bool = false
    var isShowingTodoList: Bool = false
    var isShowingTodoFullScreen: Bool = false
    var todoFullScreenIndex: Int = 0
    var findText: String = ""
    var isPrivateMode: Bool = false
    var sidebarSection: SidebarSection = .bookmarks

    // Settings
    var homepage: String = "https://www.google.com"
    var searchEngine: SearchEngine = .google

    // Download manager
    var downloads: [DownloadItem] = []

    var activeTab: Tab? {
        tabs.first { $0.id == activeTabID }
    }

    init() {
        createNewTab()
    }

    // MARK: - Tab Management

    func createNewTab(url: URL? = nil) {
        let tab = Tab(url: url ?? URL(string: homepage), isPrivate: isPrivateMode)
        tabs.append(tab)
        activeTabID = tab.id
        updateAddressBar()
    }

    func closeTab(_ tab: Tab) {
        guard tabs.count > 1 else { return }
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.remove(at: index)
            if activeTabID == tab.id {
                let newIndex = min(index, tabs.count - 1)
                activeTabID = tabs[newIndex].id
                updateAddressBar()
            }
        }
    }

    func selectTab(_ tab: Tab) {
        activeTabID = tab.id
        updateAddressBar()
    }

    // MARK: - Navigation

    func navigateToAddress(modelContext: ModelContext) {
        guard let tab = activeTab else { return }
        let text = addressBarText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        if looksLikeURL(text) {
            let urlString = text.hasPrefix("http://") || text.hasPrefix("https://") ? text : "https://\(text)"
            if let url = URL(string: urlString) {
                tab.loadURL(url)
                addToHistory(title: text, url: urlString, modelContext: modelContext)
            }
        } else {
            tab.loadSearch(text, engine: searchEngine)
            addToHistory(title: "Recherche: \(text)", url: searchEngine.searchURL(for: text).absoluteString, modelContext: modelContext)
        }
    }

    func goBack() { activeTab?.goBack() }
    func goForward() { activeTab?.goForward() }
    func reload() { activeTab?.reload() }
    func stopLoading() { activeTab?.stopLoading() }

    func goHome(modelContext: ModelContext) {
        if let url = URL(string: homepage) {
            activeTab?.loadURL(url)
            addToHistory(title: "Accueil", url: homepage, modelContext: modelContext)
        }
    }

    func updateAddressBar() {
        addressBarText = activeTab?.url?.absoluteString ?? ""
    }

    // MARK: - Bookmarks

    func addBookmark(modelContext: ModelContext) {
        guard let tab = activeTab, let url = tab.url else { return }
        let bookmark = Bookmark(title: tab.title, url: url.absoluteString)
        modelContext.insert(bookmark)
    }

    func deleteBookmark(_ bookmark: Bookmark, modelContext: ModelContext) {
        modelContext.delete(bookmark)
    }

    func openBookmark(_ bookmark: Bookmark) {
        if let url = URL(string: bookmark.url) {
            activeTab?.loadURL(url)
            addressBarText = bookmark.url
        }
    }

    // MARK: - History

    func addToHistory(title: String, url: String, modelContext: ModelContext) {
        guard !isPrivateMode else { return }
        let entry = HistoryEntry(title: title, url: url)
        modelContext.insert(entry)
    }

    func clearHistory(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: HistoryEntry.self)
        } catch {
            print("Erreur lors de la suppression de l'historique: \(error)")
        }
    }

    func openHistoryEntry(_ entry: HistoryEntry) {
        if let url = URL(string: entry.url) {
            activeTab?.loadURL(url)
            addressBarText = entry.url
        }
    }

    // MARK: - Find in Page

    func findInPage() {
        guard let tab = activeTab, !findText.isEmpty else { return }
        tab.webView.find(findText, configuration: .init(), completionHandler: { _ in })
    }

    func findNext() {
        guard let tab = activeTab, !findText.isEmpty else { return }
        tab.webView.find(findText, configuration: .init(), completionHandler: { _ in })
    }

    func dismissFind() {
        isShowingFindInPage = false
        findText = ""
    }

    // MARK: - Private Mode

    func togglePrivateMode() {
        isPrivateMode.toggle()
        createNewTab()
    }

    // MARK: - Helpers

    private func looksLikeURL(_ text: String) -> Bool {
        if text.contains(".") && !text.contains(" ") { return true }
        if text.hasPrefix("http://") || text.hasPrefix("https://") { return true }
        if text.hasPrefix("localhost") { return true }
        return false
    }
}

enum SidebarSection: String, CaseIterable {
    case bookmarks = "Favoris"
    case history = "Historique"
}
