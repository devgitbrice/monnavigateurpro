import SwiftUI

struct ChatSidebarView: View {
    @Bindable var viewModel: BrowserViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 10, height: 10)
                Text("Claude")
                    .font(.headline)
                Spacer()

                Button(action: { viewModel.chatMessages.removeAll() }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Effacer la conversation")
                .disabled(viewModel.chatMessages.isEmpty)
            }
            .padding(12)

            Divider()

            // Messages
            if viewModel.chatMessages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundStyle(.purple.opacity(0.5))
                    Text("Assistant Claude")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("Posez une question pour commencer")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.chatMessages) { message in
                                ChatBubbleView(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isChatLoading {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                    Text("Claude réfléchit...")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .id("loading")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onChange(of: viewModel.chatMessages.count) {
                        if let last = viewModel.chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isChatLoading) {
                        if viewModel.isChatLoading {
                            withAnimation {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            // Error message
            if let error = viewModel.chatError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                    Spacer()
                    Button(action: { viewModel.chatError = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.08))
            }

            // Input area
            HStack(spacing: 8) {
                TextField("Message...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isChatLoading
                            ? Color.gray
                            : Color.purple
                        )
                }
                .buttonStyle(.borderless)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isChatLoading)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
            )
            .padding(8)
        }
        .frame(maxHeight: .infinity)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !viewModel.isChatLoading else { return }

        let userMessage = ChatMessage(role: "user", content: text)
        viewModel.chatMessages.append(userMessage)
        inputText = ""
        viewModel.isChatLoading = true
        viewModel.chatError = nil

        ClaudeService.sendMessage(
            messages: viewModel.chatMessages,
            onResponse: { response in
                let assistantMessage = ChatMessage(role: "assistant", content: response)
                viewModel.chatMessages.append(assistantMessage)
                viewModel.isChatLoading = false
            },
            onError: { error in
                viewModel.chatError = error
                viewModel.isChatLoading = false
            }
        )
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isUser ? Color.purple : Color(.controlBackgroundColor))
                    )
                    .foregroundStyle(isUser ? .white : .primary)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }
}
