import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var note: String
    var isCompleted: Bool
    var sortOrder: Int
    var dateCreated: Date

    init(title: String, note: String = "", sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.note = note
        self.isCompleted = false
        self.sortOrder = sortOrder
        self.dateCreated = Date()
    }
}
