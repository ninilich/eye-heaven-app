import Foundation
import SwiftData

@Model
final class StereogramRecord {
    var imageId: String
    var lastShownAt: Date
    var timesShown: Int
    var downloadedAt: Date

    init(imageId: String) {
        self.imageId = imageId
        lastShownAt = .distantPast
        timesShown = 0
        downloadedAt = .now
    }
}
