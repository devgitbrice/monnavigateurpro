import SwiftUI

struct TabBarView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(viewModel.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == viewModel.activeTabID,
                            onSelect: { viewModel.selectTab(tab) },
                            onClose: { viewModel.closeTab(tab) }
                        )
                    }

                    // New tab button right after last tab
                    Button(action: { viewModel.createNewTab() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.borderless)
                    .help("Nouvel onglet")
                }
                .padding(.leading, 4)
            }

            Spacer()
        }
        .frame(height: 36)
        .background(
            viewModel.isPrivateMode
                ? Color.purple.opacity(0.1)
                : Color.platformWindowBackground
        )
    }
}

struct TabItemView: View {
    let tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            if tab.isLoading {
                ProgressView()
                    .scaleEffect(0.4)
                    .frame(width: 14, height: 14)
            } else if tab.isPrivate {
                Image(systemName: "eye.slash")
                    .font(.system(size: 10))
                    .foregroundStyle(.purple)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Text(tab.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: 150, alignment: .leading)

            if isHovering || isActive {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 14, height: 14)
                        .background(
                            Circle()
                                .fill(Color.platformSeparator.opacity(0.5))
                        )
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 100, maxWidth: 200)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? Color.platformControlBackground : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isActive ? Color.platformSeparator.opacity(0.5) : Color.clear, lineWidth: 0.5)
        )
        .onTapGesture(perform: onSelect)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
