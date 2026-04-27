import Foundation

@Observable
final class AppSettings {
    static let shared = AppSettings()

    // MARK: - Short Break

    var shortBreakInterval: TimeInterval {
        get { store.double(forKey: "shortBreakInterval").nonZero ?? 20 * 60 }
        set { store.set(newValue, forKey: "shortBreakInterval") }
    }

    var shortBreakDuration: TimeInterval {
        get { store.double(forKey: "shortBreakDuration").nonZero ?? 20 }
        set { store.set(newValue, forKey: "shortBreakDuration") }
    }

    var shortBreakWarning: TimeInterval {
        get { store.double(forKey: "shortBreakWarning").nonZero ?? 10 }
        set { store.set(newValue, forKey: "shortBreakWarning") }
    }

    // MARK: - Long Break

    var longBreakInterval: TimeInterval {
        get { store.double(forKey: "longBreakInterval").nonZero ?? 60 * 60 }
        set { store.set(newValue, forKey: "longBreakInterval") }
    }

    var longBreakDuration: TimeInterval {
        get { store.double(forKey: "longBreakDuration").nonZero ?? 5 * 60 }
        set { store.set(newValue, forKey: "longBreakDuration") }
    }

    var longBreakWarning: TimeInterval {
        get { store.double(forKey: "longBreakWarning").nonZero ?? 30 }
        set { store.set(newValue, forKey: "longBreakWarning") }
    }

    var longBreakMaxPostpones: Int {
        get { (store.object(forKey: "longBreakMaxPostpones") as? Int) ?? 2 }
        set { store.set(newValue, forKey: "longBreakMaxPostpones") }
    }

    var longBreakAllowSkip: Bool {
        get { store.object(forKey: "longBreakAllowSkip") as? Bool ?? true }
        set { store.set(newValue, forKey: "longBreakAllowSkip") }
    }

    // MARK: - Mode

    var hardMode: Bool {
        get { store.bool(forKey: "hardMode") }
        set { store.set(newValue, forKey: "hardMode") }
    }

    var overlayOpacity: Double {
        get { store.object(forKey: "overlayOpacity") as? Double ?? 0.6 }
        set { store.set(newValue, forKey: "overlayOpacity") }
    }

    // MARK: - Meetings

    var meetingDetectionEnabled: Bool {
        get { store.bool(forKey: "meetingDetectionEnabled") }
        set { store.set(newValue, forKey: "meetingDetectionEnabled") }
    }

    var meetingDelay: TimeInterval {
        get { store.double(forKey: "meetingDelay").nonZero ?? 60 }
        set { store.set(newValue, forKey: "meetingDelay") }
    }

    // MARK: - Stereograms

    var stereogramsEnabled: Bool {
        get { store.bool(forKey: "stereogramsEnabled") }
        set { store.set(newValue, forKey: "stereogramsEnabled") }
    }

    // MARK: - System

    var launchAtLogin: Bool {
        get { store.bool(forKey: "launchAtLogin") }
        set { store.set(newValue, forKey: "launchAtLogin") }
    }

    var soundEnabled: Bool {
        get { store.object(forKey: "soundEnabled") as? Bool ?? true }
        set { store.set(newValue, forKey: "soundEnabled") }
    }

    var respectFocusMode: Bool {
        get { store.object(forKey: "respectFocusMode") as? Bool ?? true }
        set { store.set(newValue, forKey: "respectFocusMode") }
    }

    var heartbeatEnabled: Bool {
        get { store.object(forKey: "heartbeatEnabled") as? Bool ?? true }
        set { store.set(newValue, forKey: "heartbeatEnabled") }
    }

    var appLanguage: String {
        get { store.string(forKey: "appLanguage") ?? "system" }
        set { store.set(newValue, forKey: "appLanguage") }
    }

    // MARK: - Private

    private let store = UserDefaults.standard
    private init() {}
}

private extension Double {
    var nonZero: Double? {
        self == 0 ? nil : self
    }
}
