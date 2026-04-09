import Foundation

struct ResendService {

    private static func getConfig() -> (apiKey: String, fromEmail: String, toEmail: String)? {
        let apiKey = EnvReader.value(forKey: "RESEND_API_KEY")
            ?? UserDefaults.standard.string(forKey: "resendAPIKey")
            ?? ""
        let fromEmail = EnvReader.value(forKey: "RESEND_FROM_EMAIL")
            ?? UserDefaults.standard.string(forKey: "resendFromEmail")
            ?? ""
        let toEmail = EnvReader.value(forKey: "CONTACT_TO_EMAIL")
            ?? UserDefaults.standard.string(forKey: "resendToEmail")
            ?? ""

        guard !apiKey.isEmpty, !fromEmail.isEmpty, !toEmail.isEmpty else {
            print("[Resend] Config manquante: apiKey=\(!apiKey.isEmpty), from=\(!fromEmail.isEmpty), to=\(!toEmail.isEmpty)")
            return nil
        }
        return (apiKey, fromEmail, toEmail)
    }

    private static func send(subject: String, html: String) {
        guard let config = getConfig() else { return }

        print("[Resend] Envoi à \(config.toEmail)...")

        let url = URL(string: "https://api.resend.com/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "from": config.fromEmail,
            "to": [config.toEmail],
            "subject": subject,
            "html": html
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
                    print("[Resend] Email envoyé avec succès!")
                } else {
                    print("[Resend] Erreur HTTP \(httpResponse.statusCode): \(responseBody)")
                }
            }
        }.resume()
    }

    static func sendAllTasks(_ tasks: [(title: String, isCompleted: Bool)]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale(identifier: "fr_FR")
        let dateString = dateFormatter.string(from: Date())

        let total = tasks.count
        let completed = tasks.filter { $0.isCompleted }.count
        let pending = total - completed

        var taskRows = ""
        for task in tasks {
            let icon = task.isCompleted ? "&#9745;" : "&#9744;"
            let style = task.isCompleted
                ? "color: #9ca3af; text-decoration: line-through;"
                : "color: #111827;"
            taskRows += """
                <tr>
                    <td style="padding: 10px 16px; border-bottom: 1px solid #f3f4f6; font-size: 15px; \(style)">
                        \(icon) \(task.title)
                    </td>
                </tr>
            """
        }

        let html = """
            <div style="font-family: -apple-system, sans-serif; max-width: 550px; margin: 0 auto; padding: 20px;">
                <div style="background: #22c55e; color: white; padding: 16px 20px; border-radius: 12px 12px 0 0;">
                    <h2 style="margin: 0; font-size: 18px;">Liste des tâches</h2>
                    <p style="margin: 6px 0 0 0; font-size: 13px; opacity: 0.9;">\(dateString)</p>
                </div>
                <div style="background: white; border: 1px solid #e5e7eb; border-top: none;">
                    <div style="display: flex; padding: 12px 16px; background: #f9fafb; border-bottom: 1px solid #e5e7eb;">
                        <span style="font-size: 13px; color: #6b7280;">
                            \(total) tâche(s) &bull; \(completed) terminée(s) &bull; \(pending) restante(s)
                        </span>
                    </div>
                    <table style="width: 100%; border-collapse: collapse;">
                        \(taskRows)
                    </table>
                </div>
                <div style="border-radius: 0 0 12px 12px; overflow: hidden;">
                </div>
                <p style="color: #9ca3af; font-size: 11px; text-align: center; margin-top: 16px;">
                    Envoyé depuis MonNavigateurPro
                </p>
            </div>
        """

        send(
            subject: "Mes tâches (\(pending) restante\(pending > 1 ? "s" : ""))",
            html: html
        )
    }
}
