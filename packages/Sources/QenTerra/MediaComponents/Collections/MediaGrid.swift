#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct MediaGridMetrics: Equatable, Sendable {
    public let columnCount: Int
    public let itemWidth: CGFloat

    public init(columnCount: Int, itemWidth: CGFloat) {
        self.columnCount = columnCount
        self.itemWidth = itemWidth
    }
}

public struct MediaGridLayout: Equatable, Sendable {
    public let minimumWidth: CGFloat
    public let maximumWidth: CGFloat
    public let spacing: CGFloat

    public static func resolve(
        productProfile: DesignProductProfile,
        minimumWidth: CGFloat? = nil,
        maximumWidth: CGFloat? = nil,
        spacing: CGFloat? = nil
    ) -> Self {
        let defaultMinimum = CGFloat(
            DesignTokens.Component.panelMediaCollectionGridMinimumWidth.points
        )
        let defaultMaximum = CGFloat(
            DesignTokens.Component.panelMediaCollectionGridMaximumWidth.points
        )
        let defaultSpacing = CGFloat(DesignProductMetrics.cadence.contentGap)
        let acceptsOverrides = productProfile != .cadence
        let resolvedMinimum = acceptsOverrides
            ? finitePositive(minimumWidth) ?? defaultMinimum
            : defaultMinimum
        let requestedMaximum = acceptsOverrides
            ? finitePositive(maximumWidth) ?? defaultMaximum
            : defaultMaximum
        let resolvedSpacing = acceptsOverrides
            ? finiteNonnegative(spacing) ?? defaultSpacing
            : defaultSpacing
        return Self(
            minimumWidth: resolvedMinimum,
            maximumWidth: max(requestedMaximum, resolvedMinimum),
            spacing: resolvedSpacing
        )
    }

    public func metrics(availableWidth: CGFloat) -> MediaGridMetrics {
        let width = availableWidth.isFinite
            ? max(availableWidth, minimumWidth)
            : minimumWidth
        let denominator = minimumWidth + spacing
        let count = denominator > 0
            ? max(Int((width + spacing) / denominator), 1)
            : 1
        let distributed = (
            width - CGFloat(max(count - 1, 0)) * spacing
        ) / CGFloat(count)
        return MediaGridMetrics(
            columnCount: count,
            itemWidth: min(max(distributed, minimumWidth), maximumWidth)
        )
    }

    var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: minimumWidth, maximum: maximumWidth),
                spacing: spacing,
                alignment: .top
            ),
        ]
    }

    private init(minimumWidth: CGFloat, maximumWidth: CGFloat, spacing: CGFloat) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self.spacing = spacing
    }
}

private func finitePositive(_ value: CGFloat?) -> CGFloat? {
    guard let value, value.isFinite, value > 0 else { return nil }
    return value
}

private func finiteNonnegative(_ value: CGFloat?) -> CGFloat? {
    guard let value, value.isFinite, value >= 0 else { return nil }
    return value
}

public struct MediaGrid<Content: View>: View {
    @Environment(\.designProductProfile) private var productProfile

    private let minimumWidth: CGFloat?
    private let maximumWidth: CGFloat?
    private let spacing: CGFloat?
    private let content: Content

    public init(
        minimumWidth: CGFloat? = nil,
        maximumWidth: CGFloat? = nil,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumWidth = minimumWidth
        self.maximumWidth = maximumWidth
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        let layout = MediaGridLayout.resolve(
            productProfile: productProfile,
            minimumWidth: minimumWidth,
            maximumWidth: maximumWidth,
            spacing: spacing
        )
        LazyVGrid(
            columns: layout.columns,
            alignment: .leading,
            spacing: layout.spacing
        ) {
            content
        }
    }
}
#endif
