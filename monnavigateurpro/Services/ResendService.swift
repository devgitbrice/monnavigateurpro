import Foundation

struct ResendService {
    static func sendNewTaskEmail(taskTitle: String) {
        let apiKey = EnvReader.value(forKey: "RESEND_API_KEY")
            ?? UserDefaults.standard.string(forKey: "resendAPIKey")
            ?? ""
        let fromEmail = EnvReader.value(forKey: "RESEND_FROM_EMAIL")
            ?? UserDefaults.standard.string(forKey: "resendFromEmail")
            ?? ""
        let toEmail = EnvReader.value(forKey: "CONTACT_TO_EMAIL")
            ?? UserDefaults.standard.string(forKey: "resendToEmail")
            ?? ""

        guard !apiKey.isEmpty else {
            print("[Resend] RESEND_API_KEY manquante.")
            return
        }
        guard !fromEmail.isEmpty else {
            print("[Resend] RESEND_FROM_EMAIL manquante.")
            return
        }
        guard !toEmail.isEmpty else {
            print("[Resend] CONTACT_TO_EMAIL manquant.")
            return
        }

        print("[Resend] Envoi d'email à \(toEmail) depuis \(fromEmail)...")

        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "fr_FR")
        let dateString = dateFormatter.string(from: Date())

        let body: [String: Any] = [
            "from": fromEmail,
            "to": [toEmail],
            "subject": "Nouvelle tâche : \(taskTitle)",
            "html": """
                <div style="font-family: -apple-system, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px;">
                    <div style="background: #22c55e; color: white; padding: 16px 20px; border-radius: 12px 12px 0 0;">
                        <h2 style="margin: 0; font-size: 18px;">Nouvelle tâche ajoutée</h2>
                    </div>
                    <div style="background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; border-top: none; border-radius: 0 0 12px 12px;">
                        <p style="font-size: 20px; font-weight: 600; margin: 0 0 12px 0;">\(taskTitle)</p>
                        <p style="color: #6b7280; font-size: 13px; margin: 0;">\(dateString)</p>
                    </div>
                    <p style="color: #9ca3af; font-size: 11px; text-align: center; margin-top: 16px;">
                        Envoyé depuis MonNavigateurPro
                    </p>
                </div>
            """
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[Resend] Erreur réseau: \(error.localizedDescription)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                if (200...299).contains(httpResponse.statusCode) {
                    print("[Resend] Email envoyé avec succès! (\(httpResponse.statusCode))")
                } else {
                    print("[Resend] Erreur HTTP \(httpResponse.statusCode): \(responseBody)")
                }
            }
        }.resume()
    }
}
