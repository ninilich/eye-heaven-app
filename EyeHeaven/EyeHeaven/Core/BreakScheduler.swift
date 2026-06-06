import AppKit
import Foundation

@Observable
@MainActor
final class BreakScheduler {
    static let shared = BreakScheduler()

    private(set) var timerEngine: TimerEngine
    private let idleDetector: IdleDetector
    private let settings: AppSettings
    private let preBreakController = PreBreakWindowController()
    private let breakController = BreakWindowController()
    private var preBreakAcknowledged = false
    private var breakSoundPlayed = false

    private init() {
        settings = .shared
        timerEngine = TimerEngine(settings: AppSettings.shared)
        idleDetector = IdleDetector()
        setup()
    }

    // MARK: - Public

    var nextShortBreakDescription: String {
        let seconds = Int(timerEngine.nextShortBreakIn)
        let time = formatBreakIn(seconds: seconds)
        return "\(String(localized: "break.short.title")): \(time)"
    }

    var nextLongBreakDescription: String {
        let seconds = Int(timerEngine.nextLongBreakIn)
        let time = formatBreakIn(seconds: seconds)
        return "\(String(localized: "break.long.title")): \(time)"
    }

    private func formatBreakIn(seconds: Int) -> String {
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

    func startBreakNow(_ type: BreakType) {
        timerEngine.startBreakNow(type)
    }

    func reloadScheduleFromSettings() {
        timerEngine.reloadScheduleFromSettings()
    }

    // MARK: - Private

    private func setup() {
        idleDetector.start()
        setupSleepWakeObservers()
        observeTimerState()
        timerEngine.onBreakBegan = { [weak self] _ in self?.handleWindowState() }
    }

    private func observeTimerState() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        handleIdleIfNeeded()
        handleWindowState()
    }

    private func handleWindowState() {
        switch timerEngine.state {
        case let .inPreBreak(type, remaining):
            guard !preBreakAcknowledged else { return }
            let warningDuration = type == .short ? settings.shortBreakWarning : settings.longBreakWarning
            preBreakController.show(
                type: type,
                timeRemaining: remaining,
                warningDuration: warningDuration,
                onClose: { [weak self] in
                    self?.preBreakAcknowledged = true
                },
                onStartNow: type == .long ? { [weak self] in self?.timerEngine.startBreakNow(.long) } : nil,
                onPostpone: type == .long ? { [weak self] in self?.timerEngine.postponeLongBreak() } : nil,
                onSkip: type == .long && settings.longBreakAllowSkip ? { [weak self] in
                    self?.timerEngine.skipBreak(.long)
                    self?.preBreakController.hide()
                } : nil
            )

        case let .inBreak(type):
            preBreakController.hide()
            if !breakSoundPlayed {
                SoundPlayer.playBreakStart()
                breakSoundPlayed = true
            }
            let duration = type == .short ? settings.shortBreakDuration : settings.longBreakDuration
            let allowSkip = !settings.hardMode && (type == .short || settings.longBreakAllowSkip)
            breakController.show(
                type: type,
                duration: duration,
                allowSkip: allowSkip,
                onSkip: { [weak self] in
                    self?.timerEngine.skipBreak(type)
                    self?.breakController.hide()
                }
            )

        case .running:
            if breakSoundPlayed {
                SoundPlayer.playBreakEnd()
                breakSoundPlayed = false
            }
            preBreakAcknowledged = false
            preBreakController.hide()
            breakController.hide()

        case .paused:
            preBreakController.hide()
            breakController.hide()
        }
    }

    private func handleIdleIfNeeded() {
        guard case .running = timerEngine.state else { return }
        let idle = idleDetector.idleTime
        if idle >= settings.longBreakDuration {
            timerEngine.registerIdleBreak(.long)
        } else if idle >= settings.shortBreakDuration {
            timerEngine.registerIdleBreak(.short)
        }
    }

    private func setupSleepWakeObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.timerEngine.pause()
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.timerEngine.resume()
            }
        }
    }
}
