import Foundation
import AppKit

@Observable
@MainActor
final class BreakScheduler {
    static let shared = BreakScheduler()

    private(set) var timerEngine: TimerEngine
    private let idleDetector: IdleDetector
    private let settings: AppSettings

    private init() {
        self.settings = .shared
        self.timerEngine = TimerEngine(settings: .shared)
        self.idleDetector = IdleDetector()
        setup()
    }

    // MARK: - Public

    var nextBreakDescription: String {
        let seconds = Int(timerEngine.nextShortBreakIn)
        if seconds < 60 { return String(localized: "break.in_seconds \(seconds)") }
        let minutes = seconds / 60
        return String(localized: "break.in_minutes \(minutes)")
    }

    func togglePause() {
        switch timerEngine.state {
        case .running: timerEngine.pause()
        case .paused: timerEngine.resume()
        default: break
        }
    }

    var isPaused: Bool {
        if case .paused = timerEngine.state { return true }
        return false
    }

    func skipNextBreak() {
        timerEngine.skipNextBreak()
    }

    // MARK: - Private

    private func setup() {
        idleDetector.start()
        setupSleepWakeObservers()
        observeTimerState()
    }

    private func observeTimerState() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.handleIdleIfNeeded() }
        }
    }

    private func handleIdleIfNeeded() {
        guard case .running = timerEngine.state else { return }
        let idle = idleDetector.idleTime
        if idle >= settings.longBreakDuration {
            timerEngine.breakFinished(.long)
        } else if idle >= settings.shortBreakDuration {
            timerEngine.breakFinished(.short)
        }
    }

    private func setupSleepWakeObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timerEngine.pause()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.timerEngine.resume()
        }
    }
}
