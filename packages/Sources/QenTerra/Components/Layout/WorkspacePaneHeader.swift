#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct WorkspacePaneHeaderPresentation: Equatable, Sendable {
    public let minimumHeight: Double
    public let horizontalInset: Double?
    public let showsSeparator: Bool

    public static let standard = Self(minimumHeight: 0, horizontalInset: nil, showsSeparator: false)
    public static let cadence = Self(
        minimumHeight: 64,
        horizontalInset: DesignProductMetrics.cadence.contentGap,
        showsSeparator: true
    )

    public init(minimumHeight: Double, horizontalInset: Double?, showsSeparator: Bool) {
        self.minimumHeight = minimumHeight
        self.horizontalInset = horizontalInset
        self.showsSeparator = showsSeparator
    }
}

public struct WorkspacePaneHeader<Trailing: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let title: String
    private let presentation: WorkspacePaneHeaderPresentation
    private let trailing: Trailing

    public init(
        _ title: String,
        presentation: WorkspacePaneHeaderPresentation = .standard,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.presentation = presentation
        self.trailing = trailing()
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: metrics.controlGap) {
                Text(title)
                    .font(presentation == .cadence ? .title2.bold() : .headline)
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                Spacer(minLength: 0)
                trailing
            }
            .padding(.horizontal, presentation.horizontalInset ?? metrics.panelInset)
            .frame(minHeight: presentation.minimumHeight > 0 ? presentation.minimumHeight : metrics.rowHeight)

            if presentation.showsSeparator {
                DesignSeparator()
            }
        }
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}

public extension WorkspacePaneHeader where Trailing == EmptyView {
    init(
        _ title: String,
        presentation: WorkspacePaneHeaderPresentation = .standard
    ) {
        self.init(title, presentation: presentation) {
            EmptyView()
        }
    }
}
#endif
