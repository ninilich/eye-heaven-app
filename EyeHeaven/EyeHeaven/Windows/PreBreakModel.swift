import Foundation

@Observable
@MainActor
final class PreBreakModel {
    var breakType: BreakType = .short
    var timeRemaining: TimeInterval = 0
    var warningDuration: TimeInterval = 10
    var onClose: (() -> Void)?
    var onStartNow: (() -> Void)?
    var onPostpone: (() -> Void)?
    var onSkip: (() -> Void)?
}
