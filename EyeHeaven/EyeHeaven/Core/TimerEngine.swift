import Foundation

enum BreakType {
    case short, long
}

enum TimerState {
    case running
    case paused
    case inBreak(BreakType)
    case inPreBreak(BreakType, timeRemaining: TimeInterval)
}

@Observable
@MainActor
final class TimerEngine {
    private(set) var state: TimerState = .running
    private(set) var nextShortBreakIn: TimeInterval = 0
    private(set) var nextLongBreakIn: TimeInterval = 0

    private let settings: AppSettings
    private var timer: Timer?
    private var breakTask: Task<Void, Never>?
    private var shortBreakElapsed: TimeInterval = 0
    private var longBreakElapsed: TimeInterval = 0
    private var postponeCount: Int = 0
    private var skipNextShort = false
    private var skipNextLong = false

    init(settings: AppSettings = .shared) {
        self.settings = settings
        resetTimers()
        start()
    }

    // MARK: - Public

    func pause() {
        guard case .running = state else { return }
        state = .paused
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard case .paused = state else { return }
        state = .running
        start()
    }

    func skipNextBreak() {
        skipNextShort = true
        skipNextLong = true
    }

    func postponeLongBreak() {
        guard postponeCount < settings.longBreakMaxPostpones else { return }
        postponeCount += 1
        longBreakElapsed = max(0, longBreakElapsed - settings.longBreakInterval / 3)
        state = .running
    }

    func startBreakNow(_ type: BreakType) {
        beginBreak(type)
    }

    func skipBreak(_ type: BreakType) {
        guard settings.longBreakAllowSkip || type == .short else { return }
        cancelBreakTask()
        state = .running
        switch type {
        case .short: shortBreakElapsed = 0; skipNextShort = false
        case .long: longBreakElapsed = 0; skipNextLong = false; postponeCount = 0
        }
        start()
    }

    func breakFinished(_ type: BreakType) {
        guard case .inBreak = state else { return }
        cancelBreakTask()
        state = .running
        switch type {
        case .short: shortBreakElapsed = 0; skipNextShort = false
        case .long: longBreakElapsed = 0; skipNextLong = false; postponeCount = 0
        }
        start()
    }

    // MARK: - Private

    private func resetTimers() {
        shortBreakElapsed = 0
        longBreakElapsed = 0
        updateNextBreakTimes()
    }

    private func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        switch state {
        case .running, .inPreBreak: break
        default: return
        }
        shortBreakElapsed += 1
        longBreakElapsed += 1
        updateNextBreakTimes()
        checkForBreak()
    }

    private func updateNextBreakTimes() {
        nextShortBreakIn = max(0, settings.shortBreakInterval - shortBreakElapsed)
        nextLongBreakIn = max(0, settings.longBreakInterval - longBreakElapsed)
    }

    private func checkForBreak() {
        // Long break takes priority
        let longWarningStart = settings.longBreakInterval - settings.longBreakWarning
        let shortWarningStart = settings.shortBreakInterval - settings.shortBreakWarning

        if longBreakElapsed >= settings.longBreakInterval {
            if skipNextLong {
                longBreakElapsed = 0; skipNextLong = false; state = .running
            } else {
                beginBreak(.long)
            }
            return
        }

        if longBreakElapsed >= longWarningStart {
            let remaining = settings.longBreakInterval - longBreakElapsed
            if skipNextLong {
                if case .inPreBreak(.long, _) = state { state = .running }
            } else {
                state = .inPreBreak(.long, timeRemaining: remaining)
            }
            return
        }

        if shortBreakElapsed >= settings.shortBreakInterval {
            if skipNextShort {
                shortBreakElapsed = 0; skipNextShort = false; state = .running
            } else {
                beginBreak(.short)
            }
            return
        }

        if shortBreakElapsed >= shortWarningStart {
            let remaining = settings.shortBreakInterval - shortBreakElapsed
            if skipNextShort {
                if case .inPreBreak(.short, _) = state { state = .running }
            } else {
                state = .inPreBreak(.short, timeRemaining: remaining)
            }
        }
    }

    private func beginBreak(_ type: BreakType) {
        state = .inBreak(type)
        timer?.invalidate()
        timer = nil

        let duration = type == .short ? settings.shortBreakDuration : settings.longBreakDuration
        breakTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            await MainActor.run {
                self.breakFinished(type)
                self.start()
            }
        }
    }

    private func cancelBreakTask() {
        breakTask?.cancel()
        breakTask = nil
    }
}
