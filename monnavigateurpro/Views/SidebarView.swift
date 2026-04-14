import SwiftUI
import SwiftData

struct SidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.dateAdded, order: .reverse) private var bookmarks: [Bookmark]
    @Query(sort: \HistoryEntry.visitDate, order: .reverse) private var history: [HistoryEntry]

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $viewModel.sidebarSection) {
                ForEach(SidebarSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

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

// MARK: - BookmarkListView

struct BookmarkListView: View {
    let bookmarks: [Bookmark]
    let viewModel: BrowserViewModel
    let modelContext: ModelContext
    @Environment(\.colorScheme) private var colorScheme
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
            addSectionButton
            if bookmarks.isEmpty && sections.isEmpty {
                emptyState
            } else {
                bookmarkList
            }
        }
    }

    private var addSectionButton: some View {
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
    }

    private var emptyState: some View {
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
    }

    private var bookmarkList: some View {
        List {
            ForEach(sections) { section in
                sectionBlock(section)
            }

            if !unsectionedBookmarks.isEmpty {
                unsectionedBlock
            }
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func sectionBlock(_ section: BookmarkSection) -> some View {
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
            BookmarkRowView(
                bookmark: bookmark,
                viewModel: viewModel,
                modelContext: modelContext,
                sections: sections,
                editingBookmarkID: $editingBookmarkID,
                editTitle: $editTitle
            )
        }
    }

    @ViewBuilder
    private var unsectionedBlock: some View {
        if !sections.isEmpty {
            let color: Color = colorScheme == .dark ? Color.white.opacity(0.4) : Color.secondary
            Text("Sans section")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
                .textCase(.uppercase)
        }
        ForEach(unsectionedBookmarks) { bookmark in
            BookmarkRowView(
                bookmark: bookmark,
                viewModel: viewModel,
                modelContext: modelContext,
                sections: sections,
                editingBookmarkID: $editingBookmarkID,
                editTitle: $editTitle
            )
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

// MARK: - BookmarkRowView (extracted)

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let viewModel: BrowserViewModel
    let modelContext: ModelContext
    let sections: [BookmarkSection]
    @Binding var editingBookmarkID: UUID?
    @Binding var editTitle: String
    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color {
        colorScheme == .dark ? .white : Color.primary
    }

    private var urlColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.secondary
    }

    var body: some View {
        if editingBookmarkID == bookmark.id {
            editingRow
        } else {
            displayRow
        }
    }

    private var editingRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)

            TextField("Titre", text: $editTitle)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, weight: .medium))
                .onSubmit { commitEdit() }
                #if os(macOS)
                .onExitCommand { editingBookmarkID = nil }
                #endif

            Button(action: { commitEdit() }) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
            .buttonStyle(.borderless)
        }
    }

    private var displayRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(titleColor)
                    .lineLimit(1)
                Text(bookmark.url)
                    .font(.system(size: 10))
                    .foregroundColor(urlColor)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.openBookmark(bookmark) }
        .contextMenu { rowContextMenu }
    }

    @ViewBuilder
    private var rowContextMenu: some View {
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

    private func commitEdit() {
        let trimmed = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { bookmark.title = trimmed }
        editingBookmarkID = nil
    }
}

// MARK: - SectionHeaderView

struct SectionHeaderView: View {
    let section: BookmarkSection
    let isEditing: Bool
    @Binding var editName: String
    let onStartEdit: () -> Void
    let onEndEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    private var nameColor: Color {
        colorScheme == .dark ? .white : Color.primary
    }

    var body: some View {
        if isEditing {
            editingHeader
        } else {
            displayHeader
        }
    }

    private var editingHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)

            TextField("Nom", text: $editName)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, weight: .semibold))
                .onSubmit { onEndEdit() }
                #if os(macOS)
                .onExitCommand { onEndEdit() }
                #endif

            Button(action: onEndEdit) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
            }
            .buttonStyle(.borderless)
        }
    }

    private var displayHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 8))
                .foregroundStyle(.quaternary)

            Image(systemName: "folder.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)

            Text(section.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(nameColor)
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

// MARK: - HistoryListView

struct HistoryListView: View {
    let history: [HistoryEntry]
    let viewModel: BrowserViewModel
    let modelContext: ModelContext
    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color { colorScheme == .dark ? .white : Color.primary }
    private var urlColor: Color { colorScheme == .dark ? Color.white.opacity(0.6) : Color.secondary }
    private var iconColor: Color { colorScheme == .dark ? Color.white.opacity(0.4) : Color.secondary }
    private var timeColor: Color { colorScheme == .dark ? Color.white.opacity(0.3) : Color.gray }

    var body: some View {
        VStack(spacing: 0) {
            if !history.isEmpty {
                clearButton
            }

            if history.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
    }

    private var clearButton: some View {
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

    private var emptyState: some View {
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
    }

    private var historyList: some View {
        List {
            ForEach(history) { entry in
                HistoryRowView(
                    entry: entry,
                    viewModel: viewModel,
                    titleColor: titleColor,
                    urlColor: urlColor,
                    iconColor: iconColor,
                    timeColor: timeColor
                )
            }
        }
        .listStyle(.sidebar)
    }
}

// MARK: - HistoryRowView (extracted)

struct HistoryRowView: View {
    let entry: HistoryEntry
    let viewModel: BrowserViewModel
    let titleColor: Color
    let urlColor: Color
    let iconColor: Color
    let timeColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 11))
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(titleColor)
                    .lineLimit(1)
                HStack {
                    Text(entry.url)
                        .font(.system(size: 10))
                        .foregroundColor(urlColor)
                        .lineLimit(1)
                    Spacer()
                    Text(entry.visitDate, style: .time)
                        .font(.system(size: 9))
                        .foregroundColor(timeColor)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.openHistoryEntry(entry) }
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
