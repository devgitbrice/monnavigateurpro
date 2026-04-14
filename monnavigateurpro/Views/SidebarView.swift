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

    private func bookmarksFor(_ section: BookmarkSection) -> [Bookmark] {
        bookmarks.filter { $0.sectionID == section.id }
    }

    private var unsectionedBookmarks: [Bookmark] {
        bookmarks.filter { $0.sectionID == nil }
    }

    private var labelColor: Color {
        if colorScheme == .dark {
            return Color(white: 1, opacity: 0.4)
        }
        return Color.secondary
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
                BookmarkSectionBlock(
                    section: section,
                    sectionBookmarks: bookmarksFor(section),
                    viewModel: viewModel,
                    modelContext: modelContext,
                    allSections: sections,
                    editingSectionID: $editingSectionID,
                    editSectionName: $editSectionName,
                    editingBookmarkID: $editingBookmarkID,
                    editTitle: $editTitle
                )
            }

            if !unsectionedBookmarks.isEmpty {
                if !sections.isEmpty {
                    Text("Sans section")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(labelColor)
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
        }
        .listStyle(.sidebar)
    }

    private func addSection() {
        let section = BookmarkSection(name: "Nouvelle section", sortOrder: sections.count)
        modelContext.insert(section)
        editSectionName = section.name
        editingSectionID = section.id
    }
}

// MARK: - BookmarkSectionBlock

struct BookmarkSectionBlock: View {
    let section: BookmarkSection
    let sectionBookmarks: [Bookmark]
    let viewModel: BrowserViewModel
    let modelContext: ModelContext
    let allSections: [BookmarkSection]
    @Binding var editingSectionID: UUID?
    @Binding var editSectionName: String
    @Binding var editingBookmarkID: UUID?
    @Binding var editTitle: String

    var body: some View {
        sectionHeader

        ForEach(sectionBookmarks) { bookmark in
            BookmarkRowView(
                bookmark: bookmark,
                viewModel: viewModel,
                modelContext: modelContext,
                sections: allSections,
                editingBookmarkID: $editingBookmarkID,
                editTitle: $editTitle
            )
        }
    }

    private var sectionHeader: some View {
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
            handleDrop(items)
        }
    }

    private func handleDrop(_ items: [String]) -> Bool {
        guard let droppedID = items.first.flatMap({ UUID(uuidString: $0) }),
              let fromIndex = allSections.firstIndex(where: { $0.id == droppedID }),
              let toIndex = allSections.firstIndex(where: { $0.id == section.id }),
              fromIndex != toIndex else { return false }
        var reordered = allSections
        let item = reordered.remove(at: fromIndex)
        reordered.insert(item, at: toIndex)
        for (index, s) in reordered.enumerated() {
            s.sortOrder = index
        }
        return true
    }
}

// MARK: - BookmarkRowView

struct BookmarkRowView: View {
    let bookmark: Bookmark
    let viewModel: BrowserViewModel
    let modelContext: ModelContext
    let sections: [BookmarkSection]
    @Binding var editingBookmarkID: UUID?
    @Binding var editTitle: String
    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color {
        if colorScheme == .dark { return Color.white }
        return Color.primary
    }

    private var urlColor: Color {
        if colorScheme == .dark { return Color(white: 1, opacity: 0.6) }
        return Color.secondary
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
        .contextMenu { contextMenuContent }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Ouvrir") { viewModel.openBookmark(bookmark) }
        Button("Ouvrir dans un nouvel onglet") {
            openInNewTab()
        }
        Divider()
        Button("Modifier") {
            editTitle = bookmark.title
            editingBookmarkID = bookmark.id
        }
        Divider()
        moveMenu
        Button("Supprimer", role: .destructive) {
            viewModel.deleteBookmark(bookmark, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private var moveMenu: some View {
        if !sections.isEmpty {
            Menu("Déplacer vers") {
                Button("Sans section") { bookmark.sectionID = nil }
                ForEach(sections) { section in
                    Button(section.name) { bookmark.sectionID = section.id }
                }
            }
            Divider()
        }
    }

    private func openInNewTab() {
        if let url = URL(string: bookmark.url) {
            viewModel.createNewTab(url: url)
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
        if colorScheme == .dark { return Color.white }
        return Color.primary
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

    private var titleColor: Color {
        if colorScheme == .dark { return Color.white }
        return Color.primary
    }
    private var urlColor: Color {
        if colorScheme == .dark { return Color(white: 1, opacity: 0.6) }
        return Color.secondary
    }
    private var iconColor: Color {
        if colorScheme == .dark { return Color(white: 1, opacity: 0.4) }
        return Color.secondary
    }
    private var timeColor: Color {
        if colorScheme == .dark { return Color(white: 1, opacity: 0.3) }
        return Color.gray
    }

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

// MARK: - HistoryRowView

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
            entryDetails
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.openHistoryEntry(entry) }
        .contextMenu {
            Button("Ouvrir") { viewModel.openHistoryEntry(entry) }
            Button("Ouvrir dans un nouvel onglet") {
                openInNewTab()
            }
        }
    }

    private var entryDetails: some View {
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

    private func openInNewTab() {
        if let url = URL(string: entry.url) {
            viewModel.createNewTab(url: url)
        }
    }
}
