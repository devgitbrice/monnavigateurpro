import Foundation
import SwiftData

@Model
final class Bookmark {
    var id: UUID
    var title: String
    var url: String
    var dateAdded: Date
    var folder: String
    var sectionID: UUID?

    init(title: String, url: String, folder: String = "General", sectionID: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.dateAdded = Date()
        self.folder = folder
        self.sectionID = sectionID
    }
}
