#if canImport(SwiftUI)
import SwiftUI

public struct RowActionButtonStyle: ButtonStyle {
    private let state: DesignButtonState

    public init(state: DesignButtonState = .init()) {
        self.state = state
    }

    public func makeBody(configuration: Configuration) -> some View {
        DesignButtonStyle(role: .menuRow, state: state)
            .makeBody(configuration: configuration)
    }
}
#endif
