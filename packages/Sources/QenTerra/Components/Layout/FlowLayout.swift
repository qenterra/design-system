#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct DesignFlowLayout: Layout {
    public struct Arrangement: Equatable, Sendable {
        public let size: CGSize
        public let origins: [CGPoint]

        public init(size: CGSize, origins: [CGPoint]) {
            self.size = size
            self.origins = origins
        }
    }

    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    public var horizontalSpacing: CGFloat?
    public var verticalSpacing: CGFloat?

    public init(horizontalSpacing: CGFloat? = nil, verticalSpacing: CGFloat? = nil) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let childProposal = Self.childProposal(width: proposal.width)
        return Self.arrangement(
            sizes: subviews.map { $0.sizeThatFits(childProposal) },
            proposalWidth: childProposal.width,
            horizontalSpacing: resolvedHorizontalSpacing,
            verticalSpacing: resolvedVerticalSpacing
        ).size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let childProposal = Self.childProposal(width: proposal.width ?? bounds.width)
        let arrangement = Self.arrangement(
            sizes: subviews.map { $0.sizeThatFits(childProposal) },
            proposalWidth: childProposal.width,
            horizontalSpacing: resolvedHorizontalSpacing,
            verticalSpacing: resolvedVerticalSpacing
        )
        for (index, origin) in arrangement.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: childProposal
            )
        }
    }

    public static func arrangement(
        sizes: [CGSize],
        proposalWidth: CGFloat?,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> Arrangement {
        let width = childProposal(width: proposalWidth).width ?? .greatestFiniteMagnitude
        var origins: [CGPoint] = []
        var cursor = CGPoint.zero
        var rowHeight = CGFloat.zero
        var usedWidth = CGFloat.zero

        for size in sizes {
            if cursor.x > 0, cursor.x + size.width > width {
                cursor.x = 0
                cursor.y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            origins.append(cursor)
            usedWidth = max(usedWidth, cursor.x + size.width)
            rowHeight = max(rowHeight, size.height)
            cursor.x += size.width + horizontalSpacing
        }

        return Arrangement(
            size: CGSize(width: usedWidth, height: cursor.y + rowHeight),
            origins: origins
        )
    }

    private static func childProposal(width: CGFloat?) -> ProposedViewSize {
        ProposedViewSize(width: width.flatMap { $0.isFinite ? max(0, $0) : nil }, height: nil)
    }

    private var resolvedHorizontalSpacing: CGFloat {
        horizontalSpacing ?? metrics.controlGap
    }

    private var resolvedVerticalSpacing: CGFloat {
        verticalSpacing ?? metrics.contentGap
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
