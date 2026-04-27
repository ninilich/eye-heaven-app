import SwiftUI

struct PreBreakView: View {
    let model: PreBreakModel
    let onClose: () -> Void

    @State private var elapsed: TimeInterval = 0
    @State private var tickTimer: Timer?

    private var timeLeft: TimeInterval {
        max(0, model.warningDuration - elapsed)
    }

    private var progress: Double {
        guard model.warningDuration > 0 else { return 0 }
        return min(elapsed / model.warningDuration, 1)
    }

    private var secondsLeft: Int {
        Int(timeLeft.rounded())
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 14) {
                progressRing
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 3) {
                    Text(titleKey)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(String(localized: "prebreak.in_seconds \(secondsLeft)"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if model.breakType == .long {
                    longBreakButtons
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            closeButton
                .offset(x: -6, y: 6)
        }
        .frame(width: 440)
        .background { background }
        .onAppear {
            elapsed = model.warningDuration - model.timeRemaining
            startTimer()
        }
        .onDisappear { stopTimer() }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        if #available(macOS 26.0, *) {
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .glassEffect(in: .rect(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                }
        }
    }

    // MARK: - Subviews

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.9), value: progress)

            Text("\(secondsLeft)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .contentTransition(.numericText(countsDown: true))
                .animation(.easeInOut(duration: 0.25), value: secondsLeft)
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16)
                .background(Color.primary.opacity(0.08), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var titleKey: LocalizedStringKey {
        model.breakType == .short ? "prebreak.short.title" : "prebreak.long.title"
    }

    private var longBreakButtons: some View {
        HStack(spacing: 6) {
            if let onStartNow = model.onStartNow {
                Button(String(localized: "prebreak.start_now"), action: onStartNow)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            if let onPostpone = model.onPostpone {
                Button(String(localized: "prebreak.postpone"), action: onPostpone)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            if let onSkip = model.onSkip {
                Button(String(localized: "prebreak.skip"), action: onSkip)
                    .buttonStyle(.plain)
                    .controlSize(.small)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                elapsed += 1
            }
        }
    }

    private func stopTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }
}
