import SwiftUI

struct DownloadsView: View {
    @Bindable var viewModel: BrowserViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Téléchargements")
                    .font(.headline)
                Spacer()
                if !viewModel.downloads.isEmpty {
                    Button("Tout effacer") {
                        viewModel.downloads.removeAll { $0.isCompleted || $0.isFailed }
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)

            Divider()

            if viewModel.downloads.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("Aucun téléchargement")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.downloads) { item in
                        DownloadItemRow(item: item)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct DownloadItemRow: View {
    let item: DownloadItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : item.isFailed ? "xmark.circle.fill" : "arrow.down.circle")
                .font(.system(size: 18))
                .foregroundStyle(item.isCompleted ? .green : item.isFailed ? .red : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.fileName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                Text(item.progressText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)

                if !item.isCompleted && !item.isFailed {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
