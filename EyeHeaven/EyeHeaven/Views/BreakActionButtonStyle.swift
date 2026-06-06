import SwiftUI

enum BreakActionRole {
    case primary
    case secondary
    case tertiary
}

enum BreakActionSize {
    case regular
    case compact
}

struct BreakActionButtonStyle: ButtonStyle {
    let role: BreakActionRole
    var size: BreakActionSize = .regular

    func makeBody(configuration: Configuration) -> some View {
        BreakActionButtonBody(configuration: configuration, role: role, size: size)
    }
}

private struct BreakActionButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let role: BreakActionRole
    let size: BreakActionSize

    @State private var isHovered = false

    var body: some View {
        let horizontalPadding: CGFloat = size == .compact ? 18 : 24
        let verticalPadding: CGFloat = size == .compact ? 9 : 10
        let fontSize: CGFloat = size == .compact ? 14 : 15

        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .fill(overlayColor)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.1), value: isHovered)
            .onHover { isHovered = $0 }
    }

    private var overlayColor: Color {
        if configuration.isPressed { return .black.opacity(0.18) }
        if isHovered { return .white.opacity(0.10) }
        return .clear
    }

    private var textColor: Color {
        switch role {
        case .primary: .white.opacity(0.93)
        case .secondary: .white.opacity(0.91)
        case .tertiary: .white.opacity(0.88)
        }
    }

    private var borderColor: Color {
        switch role {
        case .primary: .white.opacity(0.28)
        case .secondary: .white.opacity(0.24)
        case .tertiary: .white.opacity(0.20)
        }
    }

    private var gradientColors: [Color] {
        switch role {
        case .primary:
            [
                Color(red: 0.14, green: 0.50, blue: 0.78),
                Color(red: 0.09, green: 0.30, blue: 0.62),
            ]
        case .secondary:
            [
                Color(red: 0.30, green: 0.34, blue: 0.45),
                Color(red: 0.20, green: 0.24, blue: 0.34),
            ]
        case .tertiary:
            [
                Color(red: 0.26, green: 0.29, blue: 0.39),
                Color(red: 0.17, green: 0.20, blue: 0.29),
            ]
        }
    }
}
