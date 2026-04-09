import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("resendAPIKey") private var resendAPIKey: String = ""
    @AppStorage("resendFromEmail") private var resendFromEmail: String = ""
    @AppStorage("resendToEmail") private var resendToEmail: String = "contact@bricematter.com"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Paramètres")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
            .padding()

            Divider()

            Form {
                Section("Général") {
                    HStack {
                        Text("Page d'accueil")
                        Spacer()
                        TextField("URL", text: $viewModel.homepage)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }

                    Picker("Moteur de recherche", selection: $viewModel.searchEngine) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.rawValue).tag(engine)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    HStack {
                        Text("Clef API Resend")
                        Spacer()
                        SecureField("re_xxxxxxxxx", text: $resendAPIKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }

                    HStack {
                        Text("Email expéditeur")
                        Spacer()
                        TextField("noreply@votredomaine.com", text: $resendFromEmail)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }

                    HStack {
                        Text("Email destinataire")
                        Spacer()
                        TextField("contact@example.com", text: $resendToEmail)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        Text("Un email est envoyé à chaque nouvelle tâche ajoutée")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Notifications Email (Resend)", systemImage: "envelope.fill")
                }

                Section("Confidentialité") {
                    Toggle("Navigation privée par défaut", isOn: $viewModel.isPrivateMode)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Mode privé")
                                .font(.subheadline)
                            Text("En mode privé, l'historique et les cookies ne sont pas enregistrés")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.isPrivateMode {
                            Label("Activé", systemImage: "eye.slash.fill")
                                .font(.caption)
                                .foregroundStyle(.purple)
                        }
                    }
                }

                Section("À propos") {
                    HStack {
                        Text("MonNavigateurPro")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("Version 1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Moteur de rendu")
                        Spacer()
                        Text("WebKit")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Plateforme")
                        Spacer()
                        Text("macOS")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 560)
    }
}
