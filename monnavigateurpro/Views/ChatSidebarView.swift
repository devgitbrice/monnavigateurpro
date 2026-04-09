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
                    .fill(viewModel.selectedAIModel.color)
                    .frame(width: 10, height: 10)
                Text("Chat AI")
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

            // Model selector
            HStack(spacing: 4) {
                ForEach(AIModel.allCases) { model in
                    Button(action: {
                        viewModel.selectedAIModel = model
                        viewModel.chatMessages.removeAll()
                        viewModel.chatError = nil
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: model.icon)
                                .font(.system(size: 9))
                            Text(model.rawValue)
                                .font(.system(size: 9, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(viewModel.selectedAIModel == model
                                      ? model.color.opacity(0.2)
                                      : Color.platformControlBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(viewModel.selectedAIModel == model
                                        ? model.color.opacity(0.5)
                                        : Color.clear, lineWidth: 1)
                        )
                        .foregroundStyle(viewModel.selectedAIModel == model
                                         ? model.color
                                         : .secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)

            Divider()

            // Messages
            if viewModel.chatMessages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: viewModel.selectedAIModel.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(viewModel.selectedAIModel.color.opacity(0.5))
                    Text(viewModel.selectedAIModel.rawValue)
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
                                ChatBubbleView(
                                    message: message,
                                    accentColor: viewModel.selectedAIModel.color,
                                    onLinkTapped: { url in
                                        viewModel.createNewTab(url: url)
                                    }
                                )
                                .id(message.id)
                            }

                            if viewModel.isChatLoading {
                                HStack(spacing: 6) {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                    Text("\(viewModel.selectedAIModel.rawValue) réfléchit...")
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
                            : viewModel.selectedAIModel.color
                        )
                }
                .buttonStyle(.borderless)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isChatLoading)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.platformTextBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.platformSeparator, lineWidth: 0.5)
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

        AIService.sendMessage(
            model: viewModel.selectedAIModel,
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
    var accentColor: Color = .purple
    var onLinkTapped: ((URL) -> Void)? = nil

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                LinkedTextView(
                    text: message.content,
                    isUser: isUser,
                    accentColor: accentColor,
                    onLinkTapped: onLinkTapped
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isUser ? accentColor : Color.platformControlBackground)
                )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            if !isUser { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 12)
    }
}

struct LinkedTextView: View {
    let text: String
    let isUser: Bool
    let accentColor: Color
    var onLinkTapped: ((URL) -> Void)? = nil

    var body: some View {
        Text(buildAttributedString())
            .font(.system(size: 13))
            .textSelection(.enabled)
            .tint(isUser ? .white : .blue)
            .environment(\.openURL, OpenURLAction { url in
                onLinkTapped?(url)
                return .handled
            })
    }

    private func buildAttributedString() -> AttributedString {
        let pattern = #"(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+(/[^\s]*)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            var attr = AttributedString(text)
            attr.foregroundColor = isUser ? .white : nil
            return attr
        }

        let nsText = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))

        var result = AttributedString()
        var lastEnd = 0

        for match in matches {
            let range = match.range

            // Text before the link
            if range.location > lastEnd {
                var before = AttributedString(nsText.substring(with: NSRange(location: lastEnd, length: range.location - lastEnd)))
                before.foregroundColor = isUser ? .white : nil
                result += before
            }

            // The link itself
            let urlString = nsText.substring(with: range)
            let fullURL: String
            if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                fullURL = urlString
            } else {
                fullURL = "https://\(urlString)"
            }

            var linkAttr = AttributedString(urlString)
            if let url = URL(string: fullURL) {
                linkAttr.link = url
            }
            linkAttr.underlineStyle = .single
            linkAttr.foregroundColor = isUser ? .white : .blue
            result += linkAttr

            lastEnd = range.location + range.length
        }

        // Remaining text
        if lastEnd < nsText.length {
            var remaining = AttributedString(nsText.substring(from: lastEnd))
            remaining.foregroundColor = isUser ? .white : nil
            result += remaining
        }

        if matches.isEmpty {
            var attr = AttributedString(text)
            attr.foregroundColor = isUser ? .white : nil
            return attr
        }

        return result
    }
}
