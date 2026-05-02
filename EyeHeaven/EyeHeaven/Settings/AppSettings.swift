import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Short Break

    var shortBreakInterval: TimeInterval {
        didSet { store.set(shortBreakInterval, forKey: "shortBreakInterval") }
    }

    var shortBreakDuration: TimeInterval {
        didSet { store.set(shortBreakDuration, forKey: "shortBreakDuration") }
    }

    var shortBreakWarning: TimeInterval {
        didSet { store.set(shortBreakWarning, forKey: "shortBreakWarning") }
    }

    // MARK: - Long Break

    var longBreakEveryShortBreaks: Int {
        didSet {
            let normalized = Self.clampLongBreakEveryShortBreaks(longBreakEveryShortBreaks)
            if normalized != longBreakEveryShortBreaks {
                longBreakEveryShortBreaks = normalized
                return
            }
            store.set(longBreakEveryShortBreaks, forKey: "longBreakEveryShortBreaks")
        }
    }

    var longBreakInterval: TimeInterval {
        shortBreakInterval * Double(longBreakEveryShortBreaks)
    }

    var longBreakDuration: TimeInterval {
        didSet { store.set(longBreakDuration, forKey: "longBreakDuration") }
    }

    var longBreakWarning: TimeInterval {
        didSet { store.set(longBreakWarning, forKey: "longBreakWarning") }
    }

    var longBreakMaxPostpones: Int {
        didSet { store.set(longBreakMaxPostpones, forKey: "longBreakMaxPostpones") }
    }

    var longBreakAllowSkip: Bool {
        didSet { store.set(longBreakAllowSkip, forKey: "longBreakAllowSkip") }
    }

    // MARK: - Mode

    var hardMode: Bool {
        didSet { store.set(hardMode, forKey: "hardMode") }
    }

    var overlayOpacity: Double {
        didSet { store.set(overlayOpacity, forKey: "overlayOpacity") }
    }

    // MARK: - Meetings

    var meetingDetectionEnabled: Bool {
        didSet { store.set(meetingDetectionEnabled, forKey: "meetingDetectionEnabled") }
    }

    var meetingDelay: TimeInterval {
        didSet { store.set(meetingDelay, forKey: "meetingDelay") }
    }

    // MARK: - Stereograms

    var stereogramsEnabled: Bool {
        didSet { store.set(stereogramsEnabled, forKey: "stereogramsEnabled") }
    }

    var stereogramsAutoUpdate: Bool {
        didSet { store.set(stereogramsAutoUpdate, forKey: "stereogramsAutoUpdate") }
    }

    var stereogramsMaxImages: Int {
        didSet { store.set(stereogramsMaxImages, forKey: "stereogramsMaxImages") }
    }

    var stereogramsLastChecked: Date? {
        didSet { store.set(stereogramsLastChecked?.timeIntervalSince1970, forKey: "stereogramsLastChecked") }
    }

    // MARK: - System

    var launchAtLogin: Bool {
        didSet { store.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    var soundEnabled: Bool {
        didSet { store.set(soundEnabled, forKey: "soundEnabled") }
    }

    var respectFocusMode: Bool {
        didSet { store.set(respectFocusMode, forKey: "respectFocusMode") }
    }

    var heartbeatEnabled: Bool {
        didSet { store.set(heartbeatEnabled, forKey: "heartbeatEnabled") }
    }

    var appLanguage: String {
        didSet { store.set(appLanguage, forKey: "appLanguage") }
    }

    // MARK: - Private

    @ObservationIgnored private let store = UserDefaults.standard

    private init() {
        let storedShortBreakInterval = store.double(forKey: "shortBreakInterval").nonZero ?? 20 * 60
        shortBreakInterval = storedShortBreakInterval
        shortBreakDuration = store.double(forKey: "shortBreakDuration").nonZero ?? 20
        shortBreakWarning = store.double(forKey: "shortBreakWarning").nonZero ?? 10
        if let storedEvery = store.object(forKey: "longBreakEveryShortBreaks") as? Int {
            longBreakEveryShortBreaks = Self.clampLongBreakEveryShortBreaks(storedEvery)
        } else {
            let legacyLongInterval = store.double(forKey: "longBreakInterval").nonZero ?? 60 * 60
            let derived = Int((legacyLongInterval / max(storedShortBreakInterval, 60)).rounded())
            longBreakEveryShortBreaks = Self.clampLongBreakEveryShortBreaks(derived)
        }
        longBreakDuration = store.double(forKey: "longBreakDuration").nonZero ?? 5 * 60
        longBreakWarning = store.double(forKey: "longBreakWarning").nonZero ?? 30
        longBreakMaxPostpones = (store.object(forKey: "longBreakMaxPostpones") as? Int) ?? 2
        longBreakAllowSkip = store.object(forKey: "longBreakAllowSkip") as? Bool ?? true
        hardMode = store.bool(forKey: "hardMode")
        overlayOpacity = store.object(forKey: "overlayOpacity") as? Double ?? 0.6
        meetingDetectionEnabled = store.bool(forKey: "meetingDetectionEnabled")
        meetingDelay = store.double(forKey: "meetingDelay").nonZero ?? 60
        stereogramsEnabled = store.bool(forKey: "stereogramsEnabled")
        stereogramsAutoUpdate = store.object(forKey: "stereogramsAutoUpdate") as? Bool ?? true
        stereogramsMaxImages = store.object(forKey: "stereogramsMaxImages") as? Int ?? 0
        if let t = store.object(forKey: "stereogramsLastChecked") as? Double {
            stereogramsLastChecked = Date(timeIntervalSince1970: t)
        } else {
            stereogramsLastChecked = nil
        }
        launchAtLogin = store.bool(forKey: "launchAtLogin")
        soundEnabled = store.object(forKey: "soundEnabled") as? Bool ?? true
        respectFocusMode = store.object(forKey: "respectFocusMode") as? Bool ?? true
        heartbeatEnabled = store.object(forKey: "heartbeatEnabled") as? Bool ?? true
        appLanguage = store.string(forKey: "appLanguage") ?? "system"
    }

    private static func clampLongBreakEveryShortBreaks(_ value: Int) -> Int {
        min(12, max(2, value))
    }
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
