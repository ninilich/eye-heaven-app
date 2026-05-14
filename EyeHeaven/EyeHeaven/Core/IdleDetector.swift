import CoreGraphics
import Foundation

@Observable
@MainActor
final class IdleDetector {
    private(set) var idleTime: TimeInterval = 0

    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func check() {
        let mouseIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyboardIdle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        idleTime = min(mouseIdle, keyboardIdle)
    }
}
