import Foundation

@Observable
class DownloadItem: Identifiable {
    let id = UUID()
    let fileName: String
    let url: URL
    var progress: Double = 0.0
    var totalBytes: Int64 = 0
    var downloadedBytes: Int64 = 0
    var isCompleted: Bool = false
    var isFailed: Bool = false
    var localURL: URL?
    var startDate: Date = Date()

    init(fileName: String, url: URL) {
        self.fileName = fileName
        self.url = url
    }

    var progressText: String {
        if isCompleted { return "Terminé" }
        if isFailed { return "Échoué" }
        if totalBytes > 0 {
            let downloaded = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
            let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
            return "\(downloaded) / \(total)"
        }
        return "Téléchargement..."
    }
}
