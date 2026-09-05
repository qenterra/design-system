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
    public static let maximumColumnCount = 10_000

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
        guard let denominator = finiteSum(minimumWidth, spacing), denominator > 0,
              let numerator = finiteSum(width, spacing)
        else {
            return singleColumnMetrics(for: width)
        }
        let quotient = numerator / denominator
        guard quotient.isFinite, quotient > 0 else {
            return singleColumnMetrics(for: width)
        }
        let boundedCount = min(floor(quotient), CGFloat(Self.maximumColumnCount))
        let count = max(Int(boundedCount), 1)
        guard let gapWidth = finiteProduct(CGFloat(count - 1), spacing) else {
            return singleColumnMetrics(for: width)
        }
        let contentWidth = width - gapWidth
        guard contentWidth.isFinite, contentWidth > 0 else {
            return singleColumnMetrics(for: width)
        }
        let distributed = contentWidth / CGFloat(count)
        guard distributed.isFinite, distributed > 0 else {
            return singleColumnMetrics(for: width)
        }
        return MediaGridMetrics(
            columnCount: count,
            itemWidth: boundedItemWidth(distributed)
        )
    }

    private func singleColumnMetrics(for width: CGFloat) -> MediaGridMetrics {
        MediaGridMetrics(columnCount: 1, itemWidth: boundedItemWidth(width))
    }

    private func boundedItemWidth(_ width: CGFloat) -> CGFloat {
        min(max(width, minimumWidth), maximumWidth)
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

private func finiteSum(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat? {
    let result = lhs + rhs
    return result.isFinite ? result : nil
}

private func finiteProduct(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat? {
    let result = lhs * rhs
    return result.isFinite ? result : nil
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
