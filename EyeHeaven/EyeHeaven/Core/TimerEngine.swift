import Foundation

enum BreakType {
    case short, long
}

protocol TimerSettingsProviding: AnyObject {
    var shortBreakInterval: TimeInterval { get set }
    var shortBreakDuration: TimeInterval { get set }
    var shortBreakWarning: TimeInterval { get set }
    var longBreakInterval: TimeInterval { get }
    var longBreakDuration: TimeInterval { get set }
    var longBreakWarning: TimeInterval { get set }
    var longBreakMaxPostpones: Int { get set }
    var longBreakAllowSkip: Bool { get set }
}

extension AppSettings: TimerSettingsProviding {}

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
    private(set) var nextBreakType: BreakType = .short

    private let settings: any TimerSettingsProviding
    private var timer: Timer?
    private var breakTask: Task<Void, Never>?
    private let postponeDuration: TimeInterval = 180
    private var shortCountdown: TimeInterval = 0
    private var longCountdown: TimeInterval = 0
    private var postponeCount: Int = 0
    private var skipNextShort = false
    private var skipNextLong = false
    private let autoStart: Bool

    init(settings: any TimerSettingsProviding = AppSettings.shared, autoStart: Bool = true) {
        self.settings = settings
        self.autoStart = autoStart
        resetCycle()
        if autoStart {
            start()
        }
    }

    // MARK: - Public

    func pause() {
        switch state {
        case .running, .inPreBreak:
            break
        default:
            return
        }
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
        guard case .inPreBreak(.long, _) = state else { return }
        guard postponeCount < settings.longBreakMaxPostpones else { return }
        postponeCount += 1
        longCountdown += postponeDuration
        state = .running
        updatePublishedCountdowns()
    }

    func startBreakNow(_ type: BreakType) {
        beginBreak(type)
    }

    func skipBreak(_ type: BreakType) {
        guard settings.longBreakAllowSkip || type == .short else { return }
        cancelBreakTask()
        completeBreak(type)
        state = .running
        start()
    }

    func breakFinished(_ type: BreakType) {
        guard case .inBreak = state else { return }
        cancelBreakTask()
        completeBreak(type)
        state = .running
        start()
    }

    func registerIdleBreak(_ type: BreakType) {
        switch state {
        case .running, .inPreBreak:
            break
        default:
            return
        }

        completeBreak(type)
        state = .running
    }

    func reloadScheduleFromSettings() {
        shortCountdown = settings.shortBreakInterval
        longCountdown = settings.longBreakInterval
        postponeCount = 0
        updatePublishedCountdowns()

        switch state {
        case .running, .inPreBreak:
            evaluateTransitions()
        case .paused, .inBreak:
            break
        }
    }

    func advanceTimeForTesting(by seconds: Int) {
        guard seconds > 0 else { return }
        for _ in 0 ..< seconds {
            tick()
        }
    }

    // MARK: - Private

    private func resetCycle() {
        shortCountdown = settings.shortBreakInterval
        longCountdown = settings.longBreakInterval
        postponeCount = 0
        skipNextShort = false
        skipNextLong = false
        state = .running
        updatePublishedCountdowns()
    }

    private func start() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        switch state {
        case .running, .inPreBreak: break
        default: return
        }
        stepCountdowns(by: 1)
        evaluateTransitions()
    }

    private func stepCountdowns(by seconds: TimeInterval) {
        shortCountdown = max(0, shortCountdown - seconds)
        longCountdown = max(0, longCountdown - seconds)
        updatePublishedCountdowns()
    }

    private func updatePublishedCountdowns() {
        nextShortBreakIn = max(0, shortCountdown)
        nextLongBreakIn = max(0, longCountdown)
        nextBreakType = nextLongBreakIn <= nextShortBreakIn ? .long : .short
    }

    private func evaluateTransitions() {
        // Long break takes priority
        if longCountdown <= 0 {
            if skipNextLong {
                skipNextLong = false
                completeBreak(.long)
                state = .running
            } else {
                beginBreak(.long)
            }
            return
        }

        if longCountdown <= settings.longBreakWarning {
            state = .inPreBreak(.long, timeRemaining: longCountdown)
            return
        }

        if shortCountdown <= 0 {
            if skipNextShort {
                skipNextShort = false
                completeBreak(.short)
                state = .running
            } else {
                beginBreak(.short)
            }
            return
        }

        if shortCountdown <= settings.shortBreakWarning {
            state = .inPreBreak(.short, timeRemaining: shortCountdown)
            return
        }

        state = .running
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
            }
        }
    }

    private func cancelBreakTask() {
        breakTask?.cancel()
        breakTask = nil
    }

    private func completeBreak(_ type: BreakType) {
        switch type {
        case .short:
            shortCountdown = settings.shortBreakInterval

        case .long:
            shortCountdown = settings.shortBreakInterval
            longCountdown = settings.longBreakInterval
            postponeCount = 0
        }
        updatePublishedCountdowns()
    }
}
