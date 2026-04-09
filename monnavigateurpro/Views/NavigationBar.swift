import SwiftUI
import AppKit

struct NavigationBar: View {
    @Bindable var viewModel: BrowserViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showBookmarkAdded: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Navigation buttons
            HStack(spacing: 4) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                }
                .disabled(viewModel.activeTab?.canGoBack != true)
                .buttonStyle(.borderless)
                .help("Retour")

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .disabled(viewModel.activeTab?.canGoForward != true)
                .buttonStyle(.borderless)
                .help("Avancer")

                if viewModel.activeTab?.isLoading == true {
                    Button(action: { viewModel.stopLoading() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help("Arrêter")
                } else {
                    Button(action: { viewModel.reload() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .help("Recharger")
                }

                Button(action: { viewModel.goHome(modelContext: modelContext) }) {
                    Image(systemName: "house")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Accueil")
            }

            // Address bar
            HStack(spacing: 6) {
                if viewModel.activeTab?.isLoading == true {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: viewModel.isPrivateMode ? "eye.slash" : "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(viewModel.isPrivateMode ? .purple : .secondary)
                }

                TextField("Rechercher ou saisir une adresse...", text: $viewModel.addressBarText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit {
                        viewModel.navigateToAddress(modelContext: modelContext)
                    }

                if !viewModel.addressBarText.isEmpty {
                    Button(action: { viewModel.addressBarText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
            )

            // Progress bar overlay
            .overlay(alignment: .bottom) {
                if let tab = viewModel.activeTab, tab.isLoading {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.5))
                            .frame(width: geometry.size.width * tab.estimatedProgress, height: 2)
                            .animation(.linear, value: tab.estimatedProgress)
                    }
                    .frame(height: 2)
                    .offset(y: 1)
                }
            }

            // Action buttons
            HStack(spacing: 4) {
                Button(action: {
                    viewModel.addBookmark(modelContext: modelContext)
                    NSSound(named: .init("Tink"))?.play()
                    withAnimation(.spring(duration: 0.3)) {
                        showBookmarkAdded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showBookmarkAdded = false
                        }
                    }
                }) {
                    Image(systemName: "star")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Ajouter aux favoris")
                .overlay(alignment: .top) {
                    if showBookmarkAdded {
                        Text("Favori ajouté")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.green)
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            )
                            .offset(y: -28)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                Button(action: { viewModel.isShowingFindInPage.toggle() }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Rechercher dans la page")

                Button(action: { viewModel.isShowingTodoList.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(.green)
                            .frame(width: 18, height: 18)
                        Image(systemName: "checklist")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.borderless)
                .help("Tâches")

                Button(action: { viewModel.isShowingChatSidebar.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(.purple)
                            .frame(width: 18, height: 18)
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.borderless)
                .help("Claude AI")

                Button(action: { viewModel.isShowingDownloads.toggle() }) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Téléchargements")

                Button(action: { viewModel.isShowingSidebar.toggle() }) {
                    ZStack {
                        Circle()
                            .fill(.yellow)
                            .frame(width: 18, height: 18)
                        Image(systemName: "sidebar.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.borderless)
                .help("Favoris & Historique")

                Button(action: { viewModel.togglePrivateMode() }) {
                    Image(systemName: viewModel.isPrivateMode ? "eye.slash.fill" : "eye.slash")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(viewModel.isPrivateMode ? .purple : .primary)
                }
                .buttonStyle(.borderless)
                .help(viewModel.isPrivateMode ? "Désactiver la navigation privée" : "Navigation privée")

                Button(action: { viewModel.isShowingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.borderless)
                .help("Paramètres")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
