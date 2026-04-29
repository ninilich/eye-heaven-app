import ServiceManagement
import SwiftUI

// MARK: - Breaks

struct BreaksSettingsView: View {
    @Bindable private var s = AppSettings.shared

    var body: some View {
        Form {
            Section(String(localized: "settings.section.short_break")) {
                timeRow(String(localized: "settings.interval"),
                        value: minutesBinding(\.shortBreakInterval, range: 1 ... 120),
                        unit: "min")
                timeRow(String(localized: "settings.duration"),
                        value: secondsBinding(\.shortBreakDuration, range: 5 ... 300),
                        unit: "sec")
                timeRow(String(localized: "settings.warning"),
                        value: secondsBinding(\.shortBreakWarning, range: 5 ... 60),
                        unit: "sec")
            }
            Section(String(localized: "settings.section.long_break")) {
                timeRow(String(localized: "settings.interval"),
                        value: minutesBinding(\.longBreakInterval, range: 10 ... 240),
                        unit: "min")
                timeRow(String(localized: "settings.duration"),
                        value: minutesBinding(\.longBreakDuration, range: 1 ... 30),
                        unit: "min")
                timeRow(String(localized: "settings.warning"),
                        value: secondsBinding(\.longBreakWarning, range: 10 ... 120),
                        unit: "sec")
                LabeledContent(String(localized: "settings.max_postpones")) {
                    IntField(
                        value: Binding(get: { s.longBreakMaxPostpones }, set: { s.longBreakMaxPostpones = $0 }),
                        range: 0 ... 5
                    )
                }
                Toggle(String(localized: "settings.allow_skip"), isOn: $s.longBreakAllowSkip)
            }
            Section(String(localized: "settings.section.mode")) {
                Toggle(isOn: $s.hardMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.hard_mode"))
                        Text(String(localized: "settings.hard_mode.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent(String(localized: "settings.overlay_opacity")) {
                    HStack(spacing: 8) {
                        Slider(value: $s.overlayOpacity, in: 0.2 ... 0.9, step: 0.05)
                            .frame(width: 150)
                        Text("\(Int(s.overlayOpacity * 100))%")
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
            Section(String(localized: "settings.section.meetings")) {
                Toggle(isOn: $s.meetingDetectionEnabled) {
                    HStack(spacing: 6) {
                        Text(String(localized: "settings.meeting_detection"))
                        Text("Beta")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                if s.meetingDetectionEnabled {
                    timeRow(String(localized: "settings.meeting_delay"),
                            value: minutesBinding(\.meetingDelay, range: 0 ... 10),
                            unit: "min")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 460)
    }

    private func timeRow(_ label: String, value: Binding<Int>, unit: String) -> some View {
        LabeledContent(label) { IntField(value: value, unit: unit) }
    }

    private func minutesBinding(_ kp: ReferenceWritableKeyPath<AppSettings, TimeInterval>, range: ClosedRange<Int>) -> Binding<Int> {
        let settings = AppSettings.shared
        return Binding(
            get: { Int(settings[keyPath: kp] / 60) },
            set: { settings[keyPath: kp] = Double(min(range.upperBound, max(range.lowerBound, $0))) * 60 }
        )
    }

    private func secondsBinding(_ kp: ReferenceWritableKeyPath<AppSettings, TimeInterval>, range: ClosedRange<Int>) -> Binding<Int> {
        let settings = AppSettings.shared
        return Binding(
            get: { Int(settings[keyPath: kp]) },
            set: { settings[keyPath: kp] = Double(min(range.upperBound, max(range.lowerBound, $0))) }
        )
    }
}

// MARK: - System

struct SystemSettingsView: View {
    @Bindable private var s = AppSettings.shared

    var body: some View {
        Form {
            Section(String(localized: "settings.section.system")) {
                Toggle(String(localized: "settings.launch_at_login"), isOn: Binding(
                    get: { s.launchAtLogin },
                    set: {
                        s.launchAtLogin = $0
                        applyLaunchAtLogin($0)
                    }
                ))
                Toggle(String(localized: "settings.sound_enabled"), isOn: $s.soundEnabled)
                Toggle(isOn: $s.respectFocusMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.respect_focus_mode"))
                        Text(String(localized: "settings.respect_focus_mode.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Toggle(isOn: $s.heartbeatEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.heartbeat"))
                        Text(String(localized: "settings.heartbeat.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 320)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {}
    }
}

// MARK: - Stereograms

struct StereogramsSettingsView: View {
    @Bindable private var s = AppSettings.shared

    var body: some View {
        Form {
            Section(String(localized: "settings.section.stereograms")) {
                Toggle(String(localized: "settings.stereograms_enabled"), isOn: $s.stereogramsEnabled)
                if s.stereogramsEnabled {
                    Button(String(localized: "settings.update_catalog")) {}
                        .buttonStyle(.borderless)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 160)
    }
}

// MARK: - About

struct AboutSettingsView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "eye.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            VStack(spacing: 4) {
                Text("EyeHeaven")
                    .font(.title.bold())
                Text("Version \(version) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(String(localized: "about.tagline"))
                .font(.body)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Link(String(localized: "about.github"), destination: URL(string: "https://github.com/ninilich/EyeHeaven")!)
                    .font(.body)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(String(localized: "about.license"))
                    .foregroundStyle(.secondary)
            }

            Text(String(localized: "about.author"))
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(width: 480, height: 280)
    }
}

// MARK: - IntField

struct IntField: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0 ... 9999
    var unit: String = ""

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commit() }
                .onAppear { text = "\(value)" }
                .onChange(of: value) { _, new in text = "\(new)" }
            if !unit.isEmpty {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
            }
        }
    }

    private func commit() {
        if let n = Int(text) {
            value = min(range.upperBound, max(range.lowerBound, n))
        }
        text = "\(value)"
    }
}
