import Foundation
import SwiftData

@Model
final class Bookmark {
    var id: UUID
    var title: String
    var url: String
    var dateAdded: Date
    var folder: String

    init(title: String, url: String, folder: String = "General") {
        self.id = UUID()
        self.title = title
        self.url = url
        self.dateAdded = Date()
        self.folder = folder
    }
}
