import SwiftUI

struct BreakView: View {
    let breakType: BreakType
    let duration: TimeInterval
    let allowSkip: Bool
    let onSkip: () -> Void

    @State private var elapsed: TimeInterval = 0
    @State private var timer: Timer?

    private var progress: Double {
        guard duration > 0 else { return 1 }
        return min(elapsed / duration, 1)
    }

    private var remaining: Int {
        max(0, Int(duration - elapsed))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Spacer()

                icon
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(spacing: 8) {
                    Text(titleKey)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(subtitleKey)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.7))
                }

                countdownRing

                if allowSkip {
                    Button(action: onSkip) {
                        Text(String(localized: "break.skip"))
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private var icon: Text {
        switch breakType {
        case .short: Text("👁️")
        case .long: Text("🌿")
        }
    }

    private var titleKey: LocalizedStringKey {
        breakType == .short ? "break.short.title" : "break.long.title"
    }

    private var subtitleKey: LocalizedStringKey {
        breakType == .short ? "break.short.subtitle" : "break.long.subtitle"
    }

    private var countdownRing: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.15), lineWidth: 6)
                .frame(width: 100, height: 100)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            Text("\(remaining)")
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                elapsed += 0.5
                if elapsed >= duration {
                    stopTimer()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
