import AppKit
import Combine
import SwiftUI

struct StereogramBreakView: View {
    @State private var currentImage: NSImage
    @State private var currentSource: String?
    @State private var currentAuthor: String?
    @State private var elapsed: TimeInterval = 0
    @State private var hasNext = true

    let duration: TimeInterval
    let allowSkip: Bool
    let onSkip: () -> Void
    let pickNext: () -> (NSImage, String?, String?)?

    private let hudHeight: CGFloat = 64
    private let padding: CGFloat = 48

    init(
        image: NSImage,
        source: String?,
        author: String?,
        duration: TimeInterval,
        allowSkip: Bool,
        onSkip: @escaping () -> Void,
        pickNext: @escaping () -> (NSImage, String?, String?)?
    ) {
        _currentImage = State(initialValue: image)
        _currentSource = State(initialValue: source)
        _currentAuthor = State(initialValue: author)
        self.duration = duration
        self.allowSkip = allowSkip
        self.onSkip = onSkip
        self.pickNext = pickNext
    }

    private var remaining: Int {
        max(0, Int(duration - elapsed))
    }

    private var countdownText: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        GeometryReader { geo in
            let cardWidth = min(max(geo.size.width * 0.9, 680), 1_420)
            let cardHeight = min(max(geo.size.height * 0.88, 520), 980)
            let imageMaxHeight = geo.size.height * 0.75

            ZStack {
                VStack(spacing: 0) {
                    Image(nsImage: currentImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: cardWidth - padding * 2, maxHeight: imageMaxHeight)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.top, 28)
                        .padding(.horizontal, padding)
                        .padding(.bottom, 20)

                    hudBar
                        .frame(height: hudHeight)
                }
                .frame(width: cardWidth, height: cardHeight)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.14, green: 0.22, blue: 0.48),
                                    Color(red: 0.08, green: 0.13, blue: 0.32),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.94)
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 24, y: 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            guard elapsed < duration else { return }
            elapsed += 0.5
        }
    }

    private var hudBar: some View {
        HStack(spacing: 14) {
            attributionView
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .regular))
                Text(countdownText)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.62))
            .padding(.trailing, 22)

            if allowSkip {
                Button(action: onSkip) {
                    Text(String(localized: "break.skip"))
                }
                .buttonStyle(BreakActionButtonStyle(role: .tertiary, size: .compact))
            }

            if hasNext {
                Button {
                    if let (img, src, auth) = pickNext() {
                        currentImage = img
                        currentSource = src
                        currentAuthor = auth
                    } else {
                        hasNext = false
                    }
                } label: {
                    Label(String(localized: "break.stereogram.next"), systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(BreakActionButtonStyle(role: .primary, size: .compact))
            }
        }
        .padding(.horizontal, 24)
        .background(.black.opacity(0.38))
    }

    private var attributionView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let source = currentSource {
                Text(source)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
            }
            if let author = currentAuthor {
                Text(author)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}
