import SwiftData

enum DataStack {
    static let container: ModelContainer = try! ModelContainer(for: StereogramRecord.self)
}
