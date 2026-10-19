import Foundation
import SwiftData

@Model
final class StereogramRecord {
    var imageId: String
    var lastShownAt: Date
    var timesShown: Int
    var downloadedAt: Date

    init(imageId: String, downloadedAt: Date = .distantPast) {
        self.imageId = imageId
        lastShownAt = .distantPast
        timesShown = 0
        self.downloadedAt = downloadedAt
    }
}
