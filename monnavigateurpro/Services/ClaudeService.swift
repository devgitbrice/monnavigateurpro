import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date = Date()
}

enum AIModel: String, CaseIterable, Identifiable {
    case chatgpt = "ChatGPT 5.2"
    case gemini = "Gemini 3.1 Pro"
    case claude = "Claude Sonnet 4.6"
    case mistral = "Mistral Large"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .chatgpt: return .green
        case .gemini: return .blue
        case .claude: return .purple
        case .mistral: return .orange
        }
    }

    var icon: String {
        switch self {
        case .chatgpt: return "bolt.fill"
        case .gemini: return "sparkles"
        case .claude: return "brain.head.profile"
        case .mistral: return "wind"
        }
    }

    var envKey: String {
        switch self {
        case .chatgpt: return "OPENAI_API_KEY"
        case .gemini: return "GEMINI_API_KEY"
        case .claude: return "ANTHROPIC_API_KEY"
        case .mistral: return "MISTRAL_API_KEY"
        }
    }

    var modelID: String {
        switch self {
        case .chatgpt: return "chatgpt-4o-latest"
        case .gemini: return "gemini-3.1-pro-preview"
        case .claude: return "claude-sonnet-4-6"
        case .mistral: return "mistral-large-latest"
        }
    }
}

import SwiftUI

struct AIService {

    static func sendMessage(
        model: AIModel,
        messages: [ChatMessage],
        onResponse: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        let apiKey = EnvReader.value(forKey: model.envKey) ?? ""
        guard !apiKey.isEmpty else {
            onError("\(model.envKey) manquante dans le .env")
            return
        }

        switch model {
        case .chatgpt:
            callOpenAI(apiKey: apiKey, model: model.modelID, messages: messages, onResponse: onResponse, onError: onError)
        case .gemini:
            callGemini(apiKey: apiKey, model: model.modelID, messages: messages, onResponse: onResponse, onError: onError)
        case .claude:
            callAnthropic(apiKey: apiKey, model: model.modelID, messages: messages, onResponse: onResponse, onError: onError)
        case .mistral:
            callMistral(apiKey: apiKey, model: model.modelID, messages: messages, onResponse: onResponse, onError: onError)
        }
    }

    // MARK: - OpenAI (ChatGPT)

    private static func callOpenAI(
        apiKey: String, model: String, messages: [ChatMessage],
        onResponse: @escaping (String) -> Void, onError: @escaping (String) -> Void
    ) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "Tu es un assistant intégré dans MonNavigateurPro. Tu réponds en français de manière concise et utile."]
        ]
        apiMessages += messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": apiMessages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        executeRequest(request, parseResponse: { json in
            if let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String {
                return text
            }
            return nil
        }, onResponse: onResponse, onError: onError)
    }

    // MARK: - Anthropic (Claude)

    private static func callAnthropic(
        apiKey: String, model: String, messages: [ChatMessage],
        onResponse: @escaping (String) -> Void, onError: @escaping (String) -> Void
    ) {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let apiMessages = messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": "Tu es un assistant intégré dans MonNavigateurPro. Tu réponds en français de manière concise et utile.",
            "messages": apiMessages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        executeRequest(request, parseResponse: { json in
            if let content = json["content"] as? [[String: Any]],
               let firstBlock = content.first,
               let text = firstBlock["text"] as? String {
                return text
            }
            return nil
        }, onResponse: onResponse, onError: onError)
    }

    // MARK: - Google Gemini

    private static func callGemini(
        apiKey: String, model: String, messages: [ChatMessage],
        onResponse: @escaping (String) -> Void, onError: @escaping (String) -> Void
    ) {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let contents = messages.map { msg -> [String: Any] in
            ["role": msg.role == "assistant" ? "model" : "user",
             "parts": [["text": msg.content]]]
        }

        let body: [String: Any] = [
            "contents": contents,
            "systemInstruction": [
                "parts": [["text": "Tu es un assistant intégré dans MonNavigateurPro. Tu réponds en français de manière concise et utile."]]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        executeRequest(request, parseResponse: { json in
            if let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                return text
            }
            return nil
        }, onResponse: onResponse, onError: onError)
    }

    // MARK: - Mistral

    private static func callMistral(
        apiKey: String, model: String, messages: [ChatMessage],
        onResponse: @escaping (String) -> Void, onError: @escaping (String) -> Void
    ) {
        let url = URL(string: "https://api.mistral.ai/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "Tu es un assistant intégré dans MonNavigateurPro. Tu réponds en français de manière concise et utile."]
        ]
        apiMessages += messages.map { ["role": $0.role, "content": $0.content] }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": apiMessages
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        executeRequest(request, parseResponse: { json in
            if let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String {
                return text
            }
            return nil
        }, onResponse: onResponse, onError: onError)
    }

    // MARK: - Shared HTTP

    private static func executeRequest(
        _ request: URLRequest,
        parseResponse: @escaping ([String: Any]) -> String?,
        onResponse: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { onError("Erreur réseau: \(error.localizedDescription)") }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { onError("Aucune donnée reçue") }
                return
            }
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                DispatchQueue.main.async { onError("Erreur \(httpResponse.statusCode): \(body)") }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = parseResponse(json) {
                    DispatchQueue.main.async { onResponse(text) }
                } else {
                    DispatchQueue.main.async { onError("Réponse inattendue de l'API") }
                }
            } catch {
                DispatchQueue.main.async { onError("Erreur parsing: \(error.localizedDescription)") }
            }
        }.resume()
    }
}
