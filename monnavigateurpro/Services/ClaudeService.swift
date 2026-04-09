import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date = Date()
}

class ClaudeService {
    static func sendMessage(
        messages: [ChatMessage],
        onResponse: @escaping (String) -> Void,
        onError: @escaping (String) -> Void
    ) {
        let apiKey = EnvReader.value(forKey: "ANTHROPIC_API_KEY")
            ?? UserDefaults.standard.string(forKey: "anthropicAPIKey")
            ?? ""

        guard !apiKey.isEmpty else {
            onError("ANTHROPIC_API_KEY manquante dans le .env")
            return
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let apiMessages = messages.map { msg in
            ["role": msg.role, "content": msg.content]
        }

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
            "system": "Tu es un assistant intégré dans MonNavigateurPro, un navigateur web macOS. Tu réponds en français de manière concise et utile. Tu peux aider l'utilisateur avec ses tâches, ses recherches web, et toute question.",
            "messages": apiMessages
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    onError("Erreur réseau: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    onError("Aucune donnée reçue")
                }
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                let body = String(data: data, encoding: .utf8) ?? ""
                DispatchQueue.main.async {
                    onError("Erreur HTTP \(httpResponse.statusCode): \(body)")
                }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let content = json["content"] as? [[String: Any]],
                   let firstBlock = content.first,
                   let text = firstBlock["text"] as? String {
                    DispatchQueue.main.async {
                        onResponse(text)
                    }
                } else {
                    DispatchQueue.main.async {
                        onError("Réponse inattendue de l'API")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    onError("Erreur de parsing: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}
