#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum PageScrollOwnership: Equatable, Sendable {
    case component
    case consumer
}

public enum PageScrollPresentation: Equatable, Sendable {
    case componentScrollContainer
    case consumerContent
}

public struct PageScrollView<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let ownership: PageScrollOwnership
    private let sectionSpacing: CGFloat?
    private let content: Content

    public init(
        ownership: PageScrollOwnership = .component,
        sectionSpacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.ownership = ownership
        self.sectionSpacing = sectionSpacing
        self.content = content()
    }

    public var body: some View {
        Group {
            switch Self.presentation(for: ownership) {
            case .componentScrollContainer:
                ScrollView {
                    pageContent
                }
            case .consumerContent:
                pageContent
            }
        }
    }

    public static func presentation(for ownership: PageScrollOwnership) -> PageScrollPresentation {
        ownership == .component ? .componentScrollContainer : .consumerContent
    }

    private var pageContent: some View {
        VStack(alignment: .leading, spacing: sectionSpacing ?? metrics.sectionGap) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(metrics.pageInset)
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
