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

public typealias PageRefreshAction = @MainActor @Sendable () async -> Void

public struct PageScrollView<Content: View>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let ownership: PageScrollOwnership
    private let sectionSpacing: CGFloat?
    private let maxContentWidth: CGFloat?
    private let usesLazyStack: Bool
    private let refreshAction: PageRefreshAction?
    private let content: Content

    public init(
        ownership: PageScrollOwnership = .component,
        sectionSpacing: CGFloat? = nil,
        maxContentWidth: CGFloat? = nil,
        usesLazyStack: Bool = false,
        refreshAction: PageRefreshAction? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.ownership = ownership
        self.sectionSpacing = sectionSpacing
        self.maxContentWidth = maxContentWidth
        self.usesLazyStack = usesLazyStack
        self.refreshAction = refreshAction
        self.content = content()
    }

    public var body: some View {
        if let refreshAction, ownership == .component {
            scrollContainer.refreshable {
                await refreshAction()
            }
        } else {
            switch Self.presentation(for: ownership) {
            case .componentScrollContainer: scrollContainer
            case .consumerContent: pageContent
            }
        }
    }

    public static func presentation(for ownership: PageScrollOwnership) -> PageScrollPresentation {
        ownership == .component ? .componentScrollContainer : .consumerContent
    }

    private var scrollContainer: some View {
        ScrollView(.vertical) {
            pageContent
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        if usesLazyStack {
            LazyVStack(alignment: .leading, spacing: sectionSpacing ?? metrics.sectionGap) {
                content
            }
            .frame(maxWidth: maxContentWidth ?? .infinity, alignment: .leading)
            .padding(metrics.pageInset)
            .frame(maxWidth: .infinity, alignment: .top)
        } else {
            VStack(alignment: .leading, spacing: sectionSpacing ?? metrics.sectionGap) {
                content
            }
            .frame(maxWidth: maxContentWidth ?? .infinity, alignment: .leading)
            .padding(metrics.pageInset)
        }
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
