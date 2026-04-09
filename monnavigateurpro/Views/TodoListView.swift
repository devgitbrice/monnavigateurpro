import SwiftUI
import SwiftData

struct TodoListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @Bindable var viewModel: BrowserViewModel
    @State private var newTaskTitle: String = ""
    @State private var draggingItem: TodoItem?
    @State private var showSentConfirmation: Bool = false
    @State private var focusedTaskID: UUID? = nil

    private var focusedTask: TodoItem? {
        guard let id = focusedTaskID else { return nil }
        return todos.first { $0.id == id }
    }

    var body: some View {
        ZStack {
            // Normal list view
            if focusedTaskID == nil {
                normalListView
            } else {
                // Focus mode: red background, single task
                focusView
            }
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Focus View (red)

    private var focusView: some View {
        ZStack {
            Color.red
                .ignoresSafeArea()

            if let task = focusedTask {
                Text(task.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(32)
            }

            // Close button top-right
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            focusedTaskID = nil
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .rotationEffect(.degrees(45))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                    }
                    .buttonStyle(.borderless)
                    .padding(12)
                }
                Spacer()
            }
        }
    }

    // MARK: - Normal List View

    private var normalListView: some View {
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

            // Send All button + confirmation
            if !todos.isEmpty {
                ZStack {
                    Button(action: { sendAllTasks() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 11))
                            Text("Send All")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.blue)
                        )
                    }
                    .buttonStyle(.borderless)

                    if showSentConfirmation {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Envoyé !")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.green)
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }

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
                                },
                                onFocus: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        focusedTaskID = todo.id
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
    }

    private func sendAllTasks() {
        let tasks = todos.map { (title: $0.title, isCompleted: $0.isCompleted) }
        ResendService.sendAllTasks(tasks)
        withAnimation(.spring(duration: 0.3)) {
            showSentConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSentConfirmation = false
            }
        }
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
        NSSound(named: .init("Purr"))?.play()
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
    var onFocus: (() -> Void)? = nil

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editText: String = ""

    var body: some View {
        HStack(spacing: 8) {
            // Focus cross button
            Button(action: { onFocus?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 14, height: 14)
                    .background(Circle().fill(.red))
            }
            .buttonStyle(.borderless)
            .help("Focus sur cette tâche")

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

            // Title (editable on double-click)
            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .onSubmit {
                        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            todo.title = trimmed
                        }
                        isEditing = false
                    }
                    .onExitCommand {
                        isEditing = false
                    }
            } else {
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
                .onTapGesture(count: 2) {
                    editText = todo.title
                    isEditing = true
                }
            }

            Spacer()

            if isHovering && !isEditing {
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
