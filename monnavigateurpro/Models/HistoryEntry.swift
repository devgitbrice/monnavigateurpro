import Foundation
import SwiftData

@Model
final class HistoryEntry {
    var id: UUID
    var title: String
    var url: String
    var visitDate: Date

    init(title: String, url: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.visitDate = Date()
    }
}
