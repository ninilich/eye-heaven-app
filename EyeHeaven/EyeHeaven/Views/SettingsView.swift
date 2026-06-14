import ServiceManagement
import SwiftUI

// MARK: - Breaks

struct BreaksSettingsView: View {
    @Bindable private var s = AppSettings.shared

    var body: some View {
        Form {
            Section(String(localized: "settings.section.short_break")) {
                timeRow(String(localized: "settings.interval"),
                        value: minutesBinding(\.shortBreakInterval, range: 1 ... 120, reloadSchedule: true),
                        unit: "min")
                timeRow(String(localized: "settings.duration"),
                        value: secondsBinding(\.shortBreakDuration, range: 5 ... 300),
                        unit: "sec")
                timeRow(String(localized: "settings.warning"),
                        value: secondsBinding(\.shortBreakWarning, range: 5 ... 60),
                        unit: "sec")
            }
            Section(String(localized: "settings.section.long_break")) {
                LabeledContent("Long break every") {
                    HStack(spacing: 6) {
                        IntField(
                            value: Binding(
                                get: { s.longBreakEveryShortBreaks },
                                set: {
                                    s.longBreakEveryShortBreaks = $0
                                    BreakScheduler.shared.reloadScheduleFromSettings()
                                }
                            ),
                            range: 2 ... 12
                        )
                        Text("short breaks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent(String(localized: "settings.interval")) {
                    Text("\(Int(s.longBreakInterval / 60)) min")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .frame(width: 480, height: 460, alignment: .top)
    }

    private func timeRow(_ label: String, value: Binding<Int>, unit: String) -> some View {
        LabeledContent(label) { IntField(value: value, unit: unit) }
    }

    private func minutesBinding(
        _ kp: ReferenceWritableKeyPath<AppSettings, TimeInterval>,
        range: ClosedRange<Int>,
        reloadSchedule: Bool = false
    ) -> Binding<Int> {
        let settings = AppSettings.shared
        return Binding(
            get: { Int(settings[keyPath: kp] / 60) },
            set: {
                let normalized = Double(min(range.upperBound, max(range.lowerBound, $0))) * 60
                let oldValue = settings[keyPath: kp]
                guard oldValue != normalized else { return }
                settings[keyPath: kp] = normalized
                if reloadSchedule {
                    BreakScheduler.shared.reloadScheduleFromSettings()
                }
            }
        )
    }

    private func secondsBinding(
        _ kp: ReferenceWritableKeyPath<AppSettings, TimeInterval>,
        range: ClosedRange<Int>,
        reloadSchedule: Bool = false
    ) -> Binding<Int> {
        let settings = AppSettings.shared
        return Binding(
            get: { Int(settings[keyPath: kp]) },
            set: {
                let normalized = Double(min(range.upperBound, max(range.lowerBound, $0)))
                let oldValue = settings[keyPath: kp]
                guard oldValue != normalized else { return }
                settings[keyPath: kp] = normalized
                if reloadSchedule {
                    BreakScheduler.shared.reloadScheduleFromSettings()
                }
            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .frame(width: 480, height: 460, alignment: .top)
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
                    .onChange(of: s.stereogramsEnabled) { _, enabled in
                        if enabled {
                            let svc = CatalogService.shared
                            if svc.needsDownload {
                                Task { await svc.fetchAndDownload() }
                            }
                        }
                    }
                CatalogDownloadStatusView()
            }

            Section(String(localized: "settings.section.stereograms_updates")) {
                Toggle(isOn: $s.stereogramsAutoUpdate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings.stereograms_auto_update"))
                        Text(String(localized: "settings.stereograms_auto_update.description"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent(String(localized: "settings.stereograms_last_checked")) {
                    if let lastChecked = s.stereogramsLastChecked {
                        Text(lastChecked, style: .relative)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(localized: "settings.stereograms_last_checked.never"))
                            .foregroundStyle(.secondary)
                    }
                }
                CatalogUpdateButtonView()
            }
            .disabled(!s.stereogramsEnabled)
            .opacity(s.stereogramsEnabled ? 1 : 0.4)

            Section(String(localized: "settings.section.stereograms_storage")) {
                LabeledContent(String(localized: "settings.stereograms_max_images")) {
                    IntField(
                        value: Binding(
                            get: { s.stereogramsMaxImages },
                            set: { s.stereogramsMaxImages = $0 }
                        ),
                        range: 0 ... 999
                    )
                }
                Text(String(localized: "settings.stereograms_max_images.hint"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .disabled(!s.stereogramsEnabled)
            .opacity(s.stereogramsEnabled ? 1 : 0.4)
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .frame(width: 480, height: 460, alignment: .top)
    }
}

/// Isolated child: only this view re-renders on CatalogService changes
private struct CatalogDownloadStatusView: View {
    private let service = CatalogService.shared

    var body: some View {
        if service.isDownloading {
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: service.downloadProgress)
                Text(service.downloadStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        if let error = service.downloadError {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
        if !service.isDownloading, service.downloadError == nil, !service.images.isEmpty {
            let count = service.images.count(where: { service.localURL(for: $0) != nil })
            if service.downloadedCount > 0 {
                Text(String(localized: "settings.stereograms_downloaded \(service.downloadedCount)"))
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            Text(String(localized: "settings.stereograms_images_ready \(count)"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Isolated child: only this view re-renders on CatalogService.isDownloading changes
private struct CatalogUpdateButtonView: View {
    private let service = CatalogService.shared

    var body: some View {
        Button(String(localized: "settings.update_now")) {
            Task { await service.fetchAndDownload() }
        }
        .disabled(service.isDownloading)
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

// MARK: - About

struct AboutSettingsView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        VStack(spacing: 20) {
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .frame(width: 480, height: 460, alignment: .top)
        .padding(.top, 36)
    }
}

// MARK: - IntField

struct IntField: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 0 ... 9999
    var unit: String = ""

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 4) {
            TextField("", text: $text)
                .frame(width: 52)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit { commit() }
                .onAppear { text = "\(value)" }
                .onChange(of: text) { _, new in
                    commitIfValid(new)
                }
                .onChange(of: value) { _, new in
                    if !isFocused {
                        text = "\(new)"
                    }
                }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commit() }
                }
            if !unit.isEmpty {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
            }
        }
    }

    private func commit() {
        if let n = Int(text) {
            let clamped = min(range.upperBound, max(range.lowerBound, n))
            if value != clamped {
                value = clamped
            }
        }
        text = "\(value)"
    }

    private func commitIfValid(_ candidate: String) {
        guard let number = Int(candidate) else { return }
        let clamped = min(range.upperBound, max(range.lowerBound, number))
        if value != clamped {
            value = clamped
        }
    }
}
