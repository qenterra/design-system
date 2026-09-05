#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct ArtworkMosaicLayout: Equatable, Sendable {
    public let slotCount: Int

    public init(slotCount: Int) {
        self.slotCount = min(max(slotCount, 0), 4)
    }

    public func frames(in bounds: CGRect) -> [CGRect] {
        guard slotCount > 0 else {
            return []
        }

        let gap = CGFloat(DesignTokens.Component.panelArtworkMosaicGap.points)
        let width = max(bounds.width, 0)
        let height = max(bounds.height, 0)
        let columnWidth = max((width - gap) / 2, 0)
        let rowHeight = max((height - gap) / 2, 0)
        let leadingX = bounds.minX
        let trailingX = bounds.minX + columnWidth + gap
        let topY = bounds.minY
        let bottomY = bounds.minY + rowHeight + gap

        switch slotCount {
        case 1:
            return [CGRect(x: leadingX, y: topY, width: width, height: height)]
        case 2:
            return [
                CGRect(x: leadingX, y: topY, width: columnWidth, height: height),
                CGRect(x: trailingX, y: topY, width: columnWidth, height: height),
            ]
        case 3:
            return [
                CGRect(x: leadingX, y: topY, width: columnWidth, height: height),
                CGRect(x: trailingX, y: topY, width: columnWidth, height: rowHeight),
                CGRect(x: trailingX, y: bottomY, width: columnWidth, height: rowHeight),
            ]
        default:
            return [
                CGRect(x: leadingX, y: topY, width: columnWidth, height: rowHeight),
                CGRect(x: trailingX, y: topY, width: columnWidth, height: rowHeight),
                CGRect(x: leadingX, y: bottomY, width: columnWidth, height: rowHeight),
                CGRect(x: trailingX, y: bottomY, width: columnWidth, height: rowHeight),
            ]
        }
    }
}

public struct ArtworkMosaic<SlotContent: View>: View {
    private let layout: ArtworkMosaicLayout
    private let title: String
    private let cornerRadius: CGFloat
    private let slotContent: (Int) -> SlotContent

    public init(
        slotCount: Int,
        title: String,
        cornerRadius: CGFloat = DesignTokens.Radius.group,
        @ViewBuilder content: @escaping (Int) -> SlotContent
    ) {
        layout = ArtworkMosaicLayout(slotCount: slotCount)
        self.title = title
        self.cornerRadius = cornerRadius.isFinite ? max(cornerRadius, 0) : 0
        slotContent = content
    }

    public var body: some View {
        GeometryReader { geometry in
            let frames = layout.frames(in: CGRect(origin: .zero, size: geometry.size))
            ZStack(alignment: .topLeading) {
                if frames.isEmpty {
                    emptyArtwork
                } else {
                    ForEach(frames.indices, id: \.self) { index in
                        let frame = frames[index]
                        slotContent(index)
                            .frame(width: frame.width, height: frame.height)
                            .clipped()
                            .offset(x: frame.minX, y: frame.minY)
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    .white.opacity(DesignTokens.Component.panelArtworkMosaicBorderOpacity.value),
                    lineWidth: DesignTokens.Stroke.hairline
                )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Artwork mosaic for \(title)")
    }

    private var emptyArtwork: some View {
        ZStack {
            Color(designToken: DesignTokens.Color.surfaceSecondary)
            Image(systemName: ArtworkPlaceholderKind.collection.symbolName)
                .font(
                    .system(
                        size: DesignTokens.Component.panelArtworkMosaicEmptySymbolSize.points,
                        weight: .ultraLight
                    )
                )
                .foregroundStyle(.tertiary)
        }
    }
}
#endif
