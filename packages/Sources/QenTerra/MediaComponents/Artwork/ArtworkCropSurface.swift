#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum ArtworkCropShape: Equatable, Sendable {
    case circle
    case square
}

public struct ArtworkCropTransform: Equatable, Sendable {
    public let scale: CGFloat
    public let normalizedOffset: CGSize

    public init(scale: CGFloat = 1, normalizedOffset: CGSize = .zero) {
        let minimum = CGFloat(DesignTokens.Component.panelArtworkCropMinimumScale.value)
        let maximum = CGFloat(DesignTokens.Component.panelArtworkCropMaximumScale.value)
        self.scale = scale.isFinite ? min(max(scale, minimum), maximum) : minimum
        self.normalizedOffset = CGSize(
            width: normalizedOffset.width.isFinite ? normalizedOffset.width : 0,
            height: normalizedOffset.height.isFinite ? normalizedOffset.height : 0
        )
    }

    public func maximumOffset(in viewportSize: CGSize, sourceSize: CGSize) -> CGSize {
        guard viewportSize.isValid, sourceSize.isValid else {
            return .zero
        }

        let fillScale = max(
            viewportSize.width / sourceSize.width,
            viewportSize.height / sourceSize.height
        )
        let renderedSize = CGSize(
            width: sourceSize.width * fillScale * scale,
            height: sourceSize.height * fillScale * scale
        )
        return CGSize(
            width: max((renderedSize.width - viewportSize.width) / 2, 0),
            height: max((renderedSize.height - viewportSize.height) / 2, 0)
        )
    }

    public func offset(in viewportSize: CGSize, sourceSize: CGSize) -> CGSize {
        guard viewportSize.isValid, sourceSize.isValid else {
            return .zero
        }
        let maximum = maximumOffset(in: viewportSize, sourceSize: sourceSize)
        let proposed = CGSize(
            width: normalizedOffset.width * viewportSize.width,
            height: normalizedOffset.height * viewportSize.height
        )
        return CGSize(
            width: min(max(proposed.width, -maximum.width), maximum.width),
            height: min(max(proposed.height, -maximum.height), maximum.height)
        )
    }
}

public struct ArtworkCropSurface<Content: View>: View {
    private let transform: ArtworkCropTransform
    private let sourceSize: CGSize
    private let viewportSize: CGSize
    private let shape: ArtworkCropShape
    private let title: String
    private let content: Content

    public init(
        transform: ArtworkCropTransform,
        sourceSize: CGSize,
        shape: ArtworkCropShape,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        let side = DesignTokens.Component.panelArtworkCropPreviewSide.points
        self.init(
            transform: transform,
            sourceSize: sourceSize,
            viewportSize: CGSize(width: side, height: side),
            shape: shape,
            title: title,
            content: content
        )
    }

    public init(
        transform: ArtworkCropTransform,
        sourceSize: CGSize,
        viewportSize: CGSize,
        shape: ArtworkCropShape,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.transform = transform
        self.sourceSize = sourceSize
        let side = DesignTokens.Component.panelArtworkCropPreviewSide.points
        self.viewportSize = viewportSize.isValid
            ? viewportSize
            : CGSize(width: side, height: side)
        self.shape = shape
        self.title = title
        self.content = content()
    }

    public var body: some View {
        let cropShape = shape.mask
        content
            .frame(width: viewportSize.width, height: viewportSize.height)
            .scaleEffect(transform.scale)
            .offset(transform.offset(in: viewportSize, sourceSize: sourceSize))
            .frame(width: viewportSize.width, height: viewportSize.height)
            .background {
                cropShape.fill(Color(designToken: DesignTokens.Color.surfaceSecondary))
            }
            .clipShape(cropShape)
            .overlay {
                cropShape.stroke(
                    .white.opacity(DesignTokens.Component.panelArtworkCropBorderOpacity.value),
                    lineWidth: DesignTokens.Stroke.default
                )
            }
            .contentShape(cropShape)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(shape.accessibilityName) crop preview for \(title)")
    }
}

private extension ArtworkCropShape {
    var mask: AnyShape {
        switch self {
        case .circle:
            AnyShape(Circle())
        case .square:
            AnyShape(
                RoundedRectangle(
                    cornerRadius: DesignTokens.Radius.group,
                    style: .continuous
                )
            )
        }
    }

    var accessibilityName: String {
        switch self {
        case .circle: "Circular"
        case .square: "Square"
        }
    }
}

private extension CGSize {
    var isValid: Bool {
        width.isFinite && width > 0 && height.isFinite && height > 0
    }
}
#endif
