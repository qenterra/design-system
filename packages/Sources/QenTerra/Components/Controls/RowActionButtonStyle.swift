#if canImport(SwiftUI)
import SwiftUI

public enum RowActionButtonPresentation: Equatable, Sendable {
    case standard
    case contentOnly

    public func opacity(isPressed: Bool) -> Double {
        guard self == .contentOnly else { return 1 }
        return isPressed ? 0.72 : 1
    }
}

public struct RowActionButtonStyle: ButtonStyle {
    private let state: DesignButtonState
    private let presentation: RowActionButtonPresentation

    public init(
        state: DesignButtonState = .init(),
        presentation: RowActionButtonPresentation = .standard
    ) {
        self.state = state
        self.presentation = presentation
    }

    @ViewBuilder
    public func makeBody(configuration: Configuration) -> some View {
        if presentation == .contentOnly {
            configuration.label
                .opacity(presentation.opacity(isPressed: configuration.isPressed))
        } else {
            DesignButtonStyle(role: .menuRow, state: state)
                .makeBody(configuration: configuration)
        }
    }
}
#endif
