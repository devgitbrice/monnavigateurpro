import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @Bindable var viewModel: BrowserViewModel
    @State private var newTaskTitle: String = ""
    @State private var draggingItem: TodoItem?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                Text("Tâches")
                    .font(.headline)
                Spacer()
                Text("\(todos.filter { !$0.isCompleted }.count) restante(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)

            Divider()

            // New task input
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 18))

                TextField("Nouvelle tâche...", text: $newTaskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        addTask()
                    }

                if !newTaskTitle.isEmpty {
                    Button(action: addTask) {
                        Text("Ajouter")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.green)
                            )
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Task list with drag & drop
            if todos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Aucune tâche")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Ajoutez une tâche ci-dessus")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(todos) { todo in
                            TodoRowView(
                                todo: todo,
                                onToggle: { toggleTask(todo) },
                                onDelete: { deleteTask(todo) },
                                onFullScreen: {
                                    if let idx = todos.firstIndex(where: { $0.id == todo.id }) {
                                        viewModel.todoFullScreenIndex = idx
                                        viewModel.isShowingTodoFullScreen = true
                                    }
                                }
                            )
                            .draggable(todo.id.uuidString) {
                                TodoRowView(
                                    todo: todo,
                                    onToggle: {},
                                    onDelete: {},
                                    onFullScreen: {}
                                )
                                .frame(width: 260)
                                .opacity(0.8)
                                .onAppear { draggingItem = todo }
                            }
                            .dropDestination(for: String.self) { items, _ in
                                guard let droppedIDString = items.first,
                                      let droppedID = UUID(uuidString: droppedIDString),
                                      let fromIndex = todos.firstIndex(where: { $0.id == droppedID }),
                                      let toIndex = todos.firstIndex(where: { $0.id == todo.id }),
                                      fromIndex != toIndex else { return false }
                                reorderTasks(from: fromIndex, to: toIndex)
                                return true
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 300, height: 450)
    }

    private func addTask() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let todo = TodoItem(title: title, sortOrder: todos.count)
        modelContext.insert(todo)
        newTaskTitle = ""
    }

    private func toggleTask(_ todo: TodoItem) {
        todo.isCompleted.toggle()
    }

    private func deleteTask(_ todo: TodoItem) {
        modelContext.delete(todo)
    }

    private func reorderTasks(from source: Int, to destination: Int) {
        var reordered = todos
        let item = reordered.remove(at: source)
        reordered.insert(item, at: destination)
        for (index, todo) in reordered.enumerated() {
            todo.sortOrder = index
        }
    }
}

struct TodoRowView: View {
    let todo: TodoItem
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onFullScreen: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)

            // Checkbox
            Button(action: onToggle) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(todo.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.borderless)

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(.system(size: 12, weight: .medium))
                    .strikethrough(todo.isCompleted)
                    .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                if !todo.note.isEmpty {
                    Text(todo.note)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isHovering {
                // Fullscreen button
                Button(action: onFullScreen) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Plein écran")

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .help("Supprimer")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color(.controlBackgroundColor) : Color.clear)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contentShape(Rectangle())
    }
}
