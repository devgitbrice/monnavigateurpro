import SwiftUI
import SwiftData

@main
struct monnavigateurproApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bookmark.self,
            HistoryEntry.self,
            TodoItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Impossible de créer le ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nouvel onglet") {
                    NotificationCenter.default.post(name: .newTab, object: nil)
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Nouvelle fenêtre privée") {
                    NotificationCenter.default.post(name: .newPrivateWindow, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }
    }
}

extension Notification.Name {
    static let newTab = Notification.Name("newTab")
    static let newPrivateWindow = Notification.Name("newPrivateWindow")
}
