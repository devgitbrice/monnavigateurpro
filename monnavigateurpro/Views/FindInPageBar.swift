import SwiftUI

struct FindInPageBar: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Rechercher dans la page...", text: $viewModel.findText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .frame(width: 200)
                .onSubmit {
                    viewModel.findInPage()
                }

            Button(action: { viewModel.findInPage() }) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.findText.isEmpty)
            .help("Suivant")

            Button(action: { viewModel.findNext() }) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.findText.isEmpty)
            .help("Précédent")

            Spacer()

            Button(action: { viewModel.dismissFind() }) {
                Text("Terminé")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
}
