import Foundation

@Observable
@MainActor
final class FocusDetector {
    private(set) var isFocusActive = false

    func start() {
        let center = DistributedNotificationCenter.default()

        center.addObserver(
            forName: NSNotification.Name("com.apple.notificationcenterui.dndstart"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.isFocusActive = true }
        }

        center.addObserver(
            forName: NSNotification.Name("com.apple.notificationcenterui.dndend"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.isFocusActive = false }
        }
    }
}
