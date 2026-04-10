import SwiftUI
import SwiftData

struct TodoFullScreenView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.dateCreated, order: .reverse) private var todos: [TodoItem]
    @Bindable var viewModel: BrowserViewModel
    @FocusState private var isFocused: Bool

    var currentTodo: TodoItem? {
        guard viewModel.todoFullScreenIndex >= 0,
              viewModel.todoFullScreenIndex < todos.count else { return nil }
        return todos[viewModel.todoFullScreenIndex]
    }

    var body: some View {
        ZStack {
            // Full black background
            Color.black
                .ignoresSafeArea()

            if let todo = currentTodo {
                // Task title centered
                Text(todo.title)
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 80)

                // Counter top-left
                VStack {
                    HStack {
                        Text("\(viewModel.todoFullScreenIndex + 1) / \(todos.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(20)
                        Spacer()

                        // Close button
                        Button(action: { viewModel.isShowingTodoFullScreen = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.white.opacity(0.1)))
                        }
                        .buttonStyle(.borderless)
                        .padding(20)
                    }
                    Spacer()
                }

                // Left arrow
                HStack {
                    Button(action: goToPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white.opacity(viewModel.todoFullScreenIndex > 0 ? 0.6 : 0.1))
                            .frame(width: 80, height: 80)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.todoFullScreenIndex <= 0)
                    .padding(.leading, 20)

                    Spacer()

                    // Right arrow
                    Button(action: goToNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white.opacity(viewModel.todoFullScreenIndex < todos.count - 1 ? 0.6 : 0.1))
                            .frame(width: 80, height: 80)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(viewModel.todoFullScreenIndex >= todos.count - 1)
                    .padding(.trailing, 20)
                }

                // Status at bottom
                VStack {
                    Spacer()
                    if todo.isCompleted {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                            Text("Terminée")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(.green)
                        .padding(.bottom, 30)
                    }
                }

            } else {
                Text("Aucune tâche")
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.title2)
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
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
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.todoFullScreenIndex -= 1
            }
        }
    }

    private func goToNext() {
        if viewModel.todoFullScreenIndex < todos.count - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.todoFullScreenIndex += 1
            }
        }
    }
}
