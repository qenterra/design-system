#if canImport(SwiftUI)
import SwiftUI

public extension Color {
    init(qds value: QDSColorValue, appearance: QDSAppearance) {
        let source = value.value(for: appearance)
        guard let components = QDSColorComponents(source) else {
            self = .clear
            return
        }
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.alpha
        )
    }
}

private struct QDSColorComponents {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init?(_ source: String) {
        let value = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") {
            let hex = String(value.dropFirst())
            guard hex.count == 6, let number = UInt64(hex, radix: 16) else { return nil }
            red = Double((number >> 16) & 0xFF) / 255
            green = Double((number >> 8) & 0xFF) / 255
            blue = Double(number & 0xFF) / 255
            alpha = 1
            return
        }

        guard value.lowercased().hasPrefix("rgba("), value.hasSuffix(")") else { return nil }
        let arguments = value.dropFirst(5).dropLast().split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard
            arguments.count == 4,
            let redChannel = Double(arguments[0]),
            let greenChannel = Double(arguments[1]),
            let blueChannel = Double(arguments[2]),
            let opacity = Double(arguments[3]),
            (0 ... 255).contains(redChannel),
            (0 ... 255).contains(greenChannel),
            (0 ... 255).contains(blueChannel),
            (0 ... 1).contains(opacity)
        else { return nil }
        red = redChannel / 255
        green = greenChannel / 255
        blue = blueChannel / 255
        alpha = opacity
    }
}

public struct QDSPrimaryButtonStyle: ButtonStyle {
    private let appearance: QDSAppearance

    public init(appearance: QDSAppearance) {
        self.appearance = appearance
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: QDS.Typography.body.size, weight: .semibold))
            .foregroundStyle(Color(qds: QDS.Color.actionPrimaryContent, appearance: appearance))
            .padding(.horizontal, QDS.Component.buttonPaddingXStandard.points)
            .frame(minHeight: QDS.Component.buttonHeightsStandard.points)
            .background(Color(qds: QDS.Color.actionPrimary, appearance: appearance))
            .clipShape(RoundedRectangle(cornerRadius: QDS.Radius.control, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: QDS.Motion.feedbackPress.seconds), value: configuration.isPressed)
    }
}

public struct QDSGroupContainer: ViewModifier {
    private let appearance: QDSAppearance

    public init(appearance: QDSAppearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content
            .padding(QDS.Component.groupPadding.points)
            .background(Color(qds: QDS.Color.surfaceSecondary, appearance: appearance))
            .clipShape(RoundedRectangle(cornerRadius: QDS.Radius.group, style: .continuous))
    }
}

public struct QDSInteractiveRowSurface<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let state: QDSInteractiveRowState
    private let appearance: QDSAppearance
    private let content: Content

    public init(
        state: QDSInteractiveRowState,
        appearance: QDSAppearance,
        @ViewBuilder content: () -> Content
    ) {
        self.state = state
        self.appearance = appearance
        self.content = content()
    }

    public var body: some View {
        content
            .contentShape(Rectangle())
            .background(fillColor)
            .overlay {
                if let border = state.border {
                    RoundedRectangle(cornerRadius: QDS.Radius.control, style: .continuous)
                        .stroke(
                            Color(qds: border, appearance: appearance),
                            lineWidth: state.borderWidth
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: QDS.Radius.control, style: .continuous))
            .opacity(state.contentOpacity)
            .animation(
                reduceMotion ? nil : .easeOut(duration: QDS.Motion.feedbackPress.seconds),
                value: state
            )
    }

    private var fillColor: Color {
        state.fill.map { Color(qds: $0, appearance: appearance) } ?? .clear
    }
}

public extension View {
    func qdsGroupContainer(appearance: QDSAppearance) -> some View {
        modifier(QDSGroupContainer(appearance: appearance))
    }
}
#endif
