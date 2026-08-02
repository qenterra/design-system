#if canImport(SwiftUI)
import SwiftUI

public extension Color {
    init(qds value: QDSColorValue, appearance: QDSAppearance) {
        let source = value.value(for: appearance)
        let hex = source.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var number: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&number)
        let red = Double((number >> 16) & 0xFF) / 255
        let green = Double((number >> 8) & 0xFF) / 255
        let blue = Double(number & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
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

public extension View {
    func qdsGroupContainer(appearance: QDSAppearance) -> some View {
        modifier(QDSGroupContainer(appearance: appearance))
    }
}
#endif
