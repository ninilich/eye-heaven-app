import AppKit
import Foundation

@Observable
@MainActor
final class BreakScheduler {
    static let shared = BreakScheduler()

    private(set) var timerEngine: TimerEngine
    private let idleDetector: IdleDetector
    private let focusDetector: FocusDetector
    private let settings: AppSettings
    private let preBreakController = PreBreakWindowController()
    private let breakController = BreakWindowController()
    private var preBreakAcknowledged = false
    private var breakSoundPlayed = false

    private init() {
        settings = .shared
        timerEngine = TimerEngine(settings: .shared)
        idleDetector = IdleDetector()
        focusDetector = FocusDetector()
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
        focusDetector.start()
        setupSleepWakeObservers()
        observeTimerState()
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
        if settings.respectFocusMode, focusDetector.isFocusActive {
            preBreakController.hide()
            breakController.hide()
            return
        }
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
            let allowSkip = !settings.hardMode && settings.longBreakAllowSkip
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
