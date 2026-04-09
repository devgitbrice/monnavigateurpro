import SwiftUI
import SwiftData

struct SidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.dateAdded, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \HistoryEntry.visitDate, order: .reverse) private var history: [HistoryEntry]

    var body: some View {
        VStack(spacing: 0) {
            // Section picker
            Picker("", selection: $viewModel.sidebarSection) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            // Content
            switch viewModel.sidebarSection {
            case .bookmarks:
                BookmarkListView(
                    bookmarks: bookmarks,
                    viewModel: viewModel,
                    modelContext: modelContext
                )
            case .history:
                HistoryListView(
                    history: history,
                    viewModel: viewModel,
                    modelContext: modelContext
                )
            }
        }
        .frame(width: 280)
        .background(.bar)
    }
}

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    let viewModel: BrowserViewModel
    let modelContext: ModelContext

    var body: some View {
        if bookmarks.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "star.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text("Aucun favori")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Cliquez sur l'étoile pour ajouter un favori")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            List {
                ForEach(bookmarks) { bookmark in
                    Button(action: { viewModel.openBookmark(bookmark) }) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(bookmark.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                Text(bookmark.url)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .contextMenu {
                        Button("Ouvrir") { viewModel.openBookmark(bookmark) }
                        Button("Ouvrir dans un nouvel onglet") {
                            if let url = URL(string: bookmark.url) {
                                viewModel.createNewTab(url: url)
                            }
                        }
                        Divider()
                        Button("Supprimer", role: .destructive) {
                            viewModel.deleteBookmark(bookmark, modelContext: modelContext)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct HistoryListView: View {
    let history: [HistoryEntry]
    let viewModel: BrowserViewModel
    let modelContext: ModelContext

    var body: some View {
        VStack(spacing: 0) {
            if !history.isEmpty {
                HStack {
                    Spacer()
                    Button("Effacer l'historique") {
                        viewModel.clearHistory(modelContext: modelContext)
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }

            if history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Aucun historique")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(history) { entry in
                        Button(action: { viewModel.openHistoryEntry(entry) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    HStack {
                                        Text(entry.url)
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(entry.visitDate, style: .time)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                        .contextMenu {
                            Button("Ouvrir") { viewModel.openHistoryEntry(entry) }
                            Button("Ouvrir dans un nouvel onglet") {
                                if let url = URL(string: entry.url) {
                                    viewModel.createNewTab(url: url)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
}
