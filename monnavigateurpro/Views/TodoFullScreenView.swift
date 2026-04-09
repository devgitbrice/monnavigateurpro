import SwiftUI
import SwiftData

struct TodoFullScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.sortOrder) private var todos: [TodoItem]
    @Bindable var viewModel: BrowserViewModel

    var currentTodo: TodoItem? {
        guard viewModel.todoFullScreenIndex >= 0,
              viewModel.todoFullScreenIndex < todos.count else { return nil }
        return todos[viewModel.todoFullScreenIndex]
    }

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.isShowingTodoFullScreen = false
                }

            if let todo = currentTodo {
                HStack(spacing: 0) {
                    // Left arrow
                    Button(action: goToPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white.opacity(viewModel.todoFullScreenIndex > 0 ? 0.8 : 0.2))
                            .frame(width: 60, height: 60)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.todoFullScreenIndex <= 0)
                    .padding(.leading, 20)

                    Spacer()

                    // Main card
                    VStack(spacing: 24) {
                        // Close button
                        HStack {
                            // Task counter
                            Text("\(viewModel.todoFullScreenIndex + 1) / \(todos.count)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button(action: { viewModel.isShowingTodoFullScreen = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                        }

                        Spacer()

                        // Status icon
                        Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle.dotted")
                            .font(.system(size: 64))
                            .foregroundStyle(todo.isCompleted ? .green : .blue)

                        // Title
                        Text(todo.title)
                            .font(.system(size: 28, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .strikethrough(todo.isCompleted)
                            .foregroundStyle(todo.isCompleted ? .secondary : .primary)

                        // Note (editable)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)

                            TextEditor(text: Binding(
                                get: { todo.note },
                                set: { todo.note = $0 }
                            ))
                            .font(.system(size: 14))
                            .frame(height: 120)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.textBackgroundColor))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                                    )
                            )
                        }

                        // Created date
                        Text("Créée le \(todo.dateCreated.formatted(date: .long, time: .shortened))")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)

                        Spacer()

                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                todo.isCompleted.toggle()
                            }) {
                                Label(
                                    todo.isCompleted ? "Marquer comme non terminée" : "Marquer comme terminée",
                                    systemImage: todo.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                )
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(todo.isCompleted ? .orange : .green)
                                )
                            }
                            .buttonStyle(.borderless)

                            Button(action: {
                                let idx = viewModel.todoFullScreenIndex
                                modelContext.delete(todo)
                                if todos.count <= 1 {
                                    viewModel.isShowingTodoFullScreen = false
                                } else if idx >= todos.count - 1 {
                                    viewModel.todoFullScreenIndex = max(0, todos.count - 2)
                                }
                            }) {
                                Label("Supprimer", systemImage: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.red.opacity(0.8))
                                    )
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .padding(32)
                    .frame(width: 550, height: 520)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.windowBackgroundColor))
                            .shadow(color: .black.opacity(0.3), radius: 30, y: 10)
                    )

                    Spacer()

                    // Right arrow
                    Button(action: goToNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white.opacity(viewModel.todoFullScreenIndex < todos.count - 1 ? 0.8 : 0.2))
                            .frame(width: 60, height: 60)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.todoFullScreenIndex >= todos.count - 1)
                    .padding(.trailing, 20)
                }
            } else {
                Text("Aucune tâche")
                    .foregroundStyle(.white)
                    .font(.title2)
            }
        }
        .onKeyPress(.leftArrow) {
            goToPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            goToNext()
            return .handled
        }
        .onKeyPress(.escape) {
            viewModel.isShowingTodoFullScreen = false
            return .handled
        }
    }

    private func goToPrevious() {
        if viewModel.todoFullScreenIndex > 0 {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.todoFullScreenIndex -= 1
            }
        }
    }

    private func goToNext() {
        if viewModel.todoFullScreenIndex < todos.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.todoFullScreenIndex += 1
            }
        }
    }
}
