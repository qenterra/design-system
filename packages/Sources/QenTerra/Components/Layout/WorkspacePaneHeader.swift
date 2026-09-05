#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct WorkspacePaneHeader<Trailing: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: String
    private let trailing: Trailing

    public init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: metrics.controlGap) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            Spacer(minLength: 0)
            trailing
        }
        .padding(.horizontal, metrics.panelInset)
        .frame(minHeight: metrics.rowHeight)
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}

public extension WorkspacePaneHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) {
            EmptyView()
        }
    }
}
#endif
