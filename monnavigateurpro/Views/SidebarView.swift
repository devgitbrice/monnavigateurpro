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
    @Query(sort: \BookmarkSection.sortOrder) private var sections: [BookmarkSection]
    @State private var editingBookmarkID: UUID? = nil
    @State private var editTitle: String = ""
    @State private var editingSectionID: UUID? = nil
    @State private var editSectionName: String = ""

    private func bookmarks(for section: BookmarkSection) -> [Bookmark] {
        bookmarks.filter { $0.sectionID == section.id }
    }

    private var unsectionedBookmarks: [Bookmark] {
        bookmarks.filter { $0.sectionID == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Add section button
            Button(action: addSection) {
                HStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 11))
                    Text("Ajouter une section")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)

            if bookmarks.isEmpty && sections.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Aucun favori")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    // Sections
                    ForEach(sections) { section in
                        SectionHeaderView(
                            section: section,
                            isEditing: editingSectionID == section.id,
                            editName: $editSectionName,
                            onStartEdit: {
                                editSectionName = section.name
                                editingSectionID = section.id
                            },
                            onEndEdit: {
                                let trimmed = editSectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmed.isEmpty { section.name = trimmed }
                                editingSectionID = nil
                            },
                            onDelete: { modelContext.delete(section) }
                        )
                        .draggable(section.id.uuidString) {
                            Text(section.name)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.platformControlBackground))
                                .opacity(0.8)
                        }
                        .dropDestination(for: String.self) { items, _ in
                            guard let droppedID = items.first.flatMap({ UUID(uuidString: $0) }),
                                  let fromIndex = sections.firstIndex(where: { $0.id == droppedID }),
                                  let toIndex = sections.firstIndex(where: { $0.id == section.id }),
                                  fromIndex != toIndex else { return false }
                            reorderSections(from: fromIndex, to: toIndex)
                            return true
                        }

                        ForEach(bookmarks(for: section)) { bookmark in
                            bookmarkRow(bookmark)
                        }
                    }

                    // Unsectioned bookmarks
                    if !unsectionedBookmarks.isEmpty {
                        if !sections.isEmpty {
                            Text("Sans section")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .textCase(.uppercase)
                        }
                        ForEach(unsectionedBookmarks) { bookmark in
                            bookmarkRow(bookmark)
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }

    @ViewBuilder
    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        if editingBookmarkID == bookmark.id {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow)

                TextField("Titre", text: $editTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .onSubmit {
                        let trimmed = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { bookmark.title = trimmed }
                        editingBookmarkID = nil
                    }
                    #if os(macOS)
                    .onExitCommand { editingBookmarkID = nil }
                    #endif

                Button(action: {
                    let trimmed = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { bookmark.title = trimmed }
                    editingBookmarkID = nil
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
            }
        } else {
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
                Button("Modifier") {
                    editTitle = bookmark.title
                    editingBookmarkID = bookmark.id
                }
                Divider()
                // Move to section
                if !sections.isEmpty {
                    Menu("Déplacer vers") {
                        Button("Sans section") { bookmark.sectionID = nil }
                        Divider()
                        ForEach(sections) { section in
                            Button(section.name) { bookmark.sectionID = section.id }
                        }
                    }
                    Divider()
                }
                Button("Supprimer", role: .destructive) {
                    viewModel.deleteBookmark(bookmark, modelContext: modelContext)
                }
            }
        }
    }

    private func addSection() {
        let section = BookmarkSection(name: "Nouvelle section", sortOrder: sections.count)
        modelContext.insert(section)
        editSectionName = section.name
        editingSectionID = section.id
    }

    private func reorderSections(from source: Int, to destination: Int) {
        var reordered = sections
        let item = reordered.remove(at: source)
        reordered.insert(item, at: destination)
        for (index, section) in reordered.enumerated() {
            section.sortOrder = index
        }
    }
}

struct SectionHeaderView: View {
    let section: BookmarkSection
    let isEditing: Bool
    @Binding var editName: String
    let onStartEdit: () -> Void
    let onEndEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        if isEditing {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)

                TextField("Nom", text: $editName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .onSubmit { onEndEdit() }
                    #if os(macOS)
                    .onExitCommand { onEndEdit() }
                    #endif

                Button(action: onEndEdit) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.green)
                }
                .buttonStyle(.borderless)
            }
        } else {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 8))
                    .foregroundStyle(.quaternary)

                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)

                Text(section.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { onStartEdit() }
            .contextMenu {
                Button("Renommer") { onStartEdit() }
                Divider()
                Button("Supprimer", role: .destructive) { onDelete() }
            }
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
