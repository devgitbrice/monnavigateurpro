import SwiftUI
import SwiftData
import WebKit

struct ContentView: View {
    @State private var viewModel = BrowserViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            TabBarView(viewModel: viewModel)

            Divider()

            // Navigation bar
            NavigationBar(viewModel: viewModel)

            Divider()

            // Find in page bar
            if viewModel.isShowingFindInPage {
                FindInPageBar(viewModel: viewModel)
                Divider()
            }

            // Main content area
            HStack(spacing: 0) {
                // Web content
                ZStack {
                    if let activeTab = viewModel.activeTab {
                        WebViewWrapper(tab: activeTab) { url, title in
                            viewModel.updateAddressBar()
                            if let url = url, let title = title {
                                viewModel.addToHistory(
                                    title: title,
                                    url: url.absoluteString,
                                    modelContext: modelContext
                                )
                            }
                        }
                    } else {
                        StartPageView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Sidebar (bookmarks/history)
                if viewModel.isShowingSidebar {
                    Divider()
                    SidebarView(viewModel: viewModel)
                }

                // Todo sidebar with resizable handle
                if viewModel.isShowingTodoList {
                    TodoResizableDivider(width: $viewModel.todoSidebarWidth)
                    TodoListView(viewModel: viewModel)
                        .frame(width: viewModel.todoSidebarWidth)
                        .background(.bar)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $viewModel.isShowingSettings) {
            SettingsView(viewModel: viewModel)
        }
        .popover(isPresented: $viewModel.isShowingDownloads, arrowEdge: .bottom) {
            DownloadsView(viewModel: viewModel)
        }
        .overlay {
            if viewModel.isShowingTodoFullScreen {
                TodoFullScreenView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden)
        .background {
            // Keyboard shortcut handlers
            Group {
                Button("") { viewModel.createNewTab() }
                    .keyboardShortcut("t", modifiers: .command)
                    .hidden()

                Button("") {
                    if let tab = viewModel.activeTab {
                        viewModel.closeTab(tab)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
                .hidden()

                Button("") { viewModel.reload() }
                    .keyboardShortcut("r", modifiers: .command)
                    .hidden()

                Button("") { viewModel.isShowingFindInPage.toggle() }
                    .keyboardShortcut("f", modifiers: .command)
                    .hidden()

                Button("") {
                    viewModel.addressBarText = ""
                }
                .keyboardShortcut("l", modifiers: .command)
                .hidden()

                Button("") { viewModel.goBack() }
                    .keyboardShortcut("[", modifiers: .command)
                    .hidden()

                Button("") { viewModel.goForward() }
                    .keyboardShortcut("]", modifiers: .command)
                    .hidden()

                Button("") { viewModel.addBookmark(modelContext: modelContext) }
                    .keyboardShortcut("d", modifiers: .command)
                    .hidden()

                Button("") { viewModel.isShowingSidebar.toggle() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .hidden()

                Button("") { viewModel.togglePrivateMode() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                    .hidden()
            }
        }
    }
}

struct StartPageView: View {
    let viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("MonNavigateurPro")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.secondary)

            Text("Saisissez une adresse ou effectuez une recherche")
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            // Quick links
            HStack(spacing: 16) {
                QuickLinkButton(title: "Google", icon: "magnifyingglass") {
                    viewModel.activeTab?.loadURL(URL(string: "https://www.google.com")!)
                }
                QuickLinkButton(title: "YouTube", icon: "play.rectangle.fill") {
                    viewModel.activeTab?.loadURL(URL(string: "https://www.youtube.com")!)
                }
                QuickLinkButton(title: "Wikipedia", icon: "book.fill") {
                    viewModel.activeTab?.loadURL(URL(string: "https://www.wikipedia.org")!)
                }
                QuickLinkButton(title: "GitHub", icon: "chevron.left.forwardslash.chevron.right") {
                    viewModel.activeTab?.loadURL(URL(string: "https://github.com")!)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

struct QuickLinkButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                    )

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Bookmark.self, HistoryEntry.self, TodoItem.self], inMemory: true)
}
