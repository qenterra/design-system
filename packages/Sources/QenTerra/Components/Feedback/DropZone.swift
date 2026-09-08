#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum DropZoneState: Equatable, Sendable {
    case ready(accessibilityValue: String)
    case targeted(accessibilityValue: String)
    case unavailable(accessibilityValue: String)

    public var presentation: DropZonePresentation {
        switch self {
        case let .ready(accessibilityValue):
            DropZonePresentation(isEnabled: true, isTargeted: false, accessibilityValue: accessibilityValue)
        case let .targeted(accessibilityValue):
            DropZonePresentation(isEnabled: true, isTargeted: true, accessibilityValue: accessibilityValue)
        case let .unavailable(accessibilityValue):
            DropZonePresentation(isEnabled: false, isTargeted: false, accessibilityValue: accessibilityValue)
        }
    }
}

public struct DropZonePresentation: Equatable, Sendable {
    public let isEnabled: Bool
    public let isTargeted: Bool
    public let accessibilityValue: String

    public init(isEnabled: Bool, isTargeted: Bool, accessibilityValue: String) {
        self.isEnabled = isEnabled
        self.isTargeted = isTargeted
        self.accessibilityValue = accessibilityValue
    }
}

public struct DropZoneVisualStyle: Equatable, Sendable {
    public let maximumWidth: CGFloat?
    public let minimumHeight: CGFloat?
    public let overlayInset: CGFloat
    public let isWorkspaceOverlay: Bool

    public init(
        maximumWidth: CGFloat?,
        minimumHeight: CGFloat?,
        overlayInset: CGFloat,
        isWorkspaceOverlay: Bool
    ) {
        self.maximumWidth = maximumWidth
        self.minimumHeight = minimumHeight
        self.overlayInset = overlayInset
        self.isWorkspaceOverlay = isWorkspaceOverlay
    }

    public static let standard = Self(
        maximumWidth: nil,
        minimumHeight: nil,
        overlayInset: 0,
        isWorkspaceOverlay: false
    )
    public static let cadenceHero = Self(
        maximumWidth: 580,
        minimumHeight: 250,
        overlayInset: 0,
        isWorkspaceOverlay: false
    )
    public static let cadenceOverlay = Self(
        maximumWidth: nil,
        minimumHeight: nil,
        overlayInset: 18,
        isWorkspaceOverlay: true
    )
}

public struct DropZoneAction {
    public let title: String
    private let handler: @MainActor () -> Void

    public init(
        title: String,
        handler: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.handler = handler
    }

    @MainActor
    public func perform() {
        handler()
    }
}

public struct DropZone: View {
    private let state: DropZoneState
    private let title: String
    private let message: String
    private let action: DropZoneAction?
    private let visualStyle: DropZoneVisualStyle

    public init(
        state: DropZoneState,
        title: String,
        message: String,
        action: DropZoneAction? = nil,
        visualStyle: DropZoneVisualStyle = .standard
    ) {
        self.state = state
        self.title = title
        self.message = message
        self.action = action
        self.visualStyle = visualStyle
    }

    public var body: some View {
        VStack(spacing: visualStyle == .standard ? DesignTokens.Space.value2 : DesignTokens.Space.value4) {
            Image(systemName: visualStyle == .standard ? standardSymbol : "square.and.arrow.down")
                .font(
                    visualStyle == .standard
                        ? .title2
                        : .system(size: visualStyle.isWorkspaceOverlay ? 34 : 36, weight: .light)
                )
                .foregroundStyle(visualStyle == .standard ? .primary : .secondary)
                .accessibilityHidden(true)
            VStack(spacing: visualStyle == .standard ? 0 : DesignTokens.Space.value2) {
                Text(title)
                    .font(
                        visualStyle == .standard
                            ? .system(
                                size: DesignTokens.Typography.rowEmphasized.size,
                                weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                            )
                            : .title3.weight(.semibold)
                    )
                Text(message)
                    .font(
                        visualStyle == .standard
                            ? .system(
                                size: DesignTokens.Typography.supporting.size,
                                weight: DesignTokens.Typography.supporting.swiftUIWeight
                            )
                            : .callout
                    )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    .multilineTextAlignment(.center)
            }
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            if let action {
                Button(action.title) { action.perform() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(visualStyle == .standard ? DesignTokens.Space.value6 : 0)
        .frame(
            maxWidth: visualStyle.maximumWidth ?? .infinity,
            minHeight: visualStyle.minimumHeight
        )
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    border,
                    style: StrokeStyle(
                        lineWidth: visualStyle.isWorkspaceOverlay ? 2 : DesignTokens.Stroke.hairline,
                        dash: visualStyle.isWorkspaceOverlay ? [9, 7] : [7, 6]
                    )
                )
                .padding(visualStyle.overlayInset)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous)
                .stroke(
                    Color(designToken: DesignTokens.Color.textPrimary),
                    lineWidth: presentation.isTargeted ? DesignTokens.Stroke.focus : 0
                )
        }
        .opacity(presentation.isEnabled ? 1 : DesignTokens.Opacity.disabled)
        .disabled(!presentation.isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(presentation.accessibilityValue)
    }

    private var presentation: DropZonePresentation { state.presentation }

    private var standardSymbol: String {
        presentation.isTargeted
            ? "arrow.down.to.line.compact.fill"
            : "arrow.down.to.line.compact"
    }

    private var cornerRadius: Double {
        visualStyle == .standard ? DesignTokens.Radius.group : DesignTokens.Radius.hero
    }

    private var background: Color {
        if visualStyle.isWorkspaceOverlay {
            return Color(designToken: DesignTokens.Color.surfaceOverlay).opacity(0.97)
        }
        return Color(designToken: DesignTokens.Color.surfaceSecondary)
    }

    private var border: Color {
        if visualStyle.isWorkspaceOverlay {
            return Color.primary.opacity(0.34)
        }
        switch state {
        case .ready: return Color(designToken: DesignTokens.Color.borderDefault)
        case .targeted: return Color(designToken: DesignTokens.Color.borderFocus)
        case .unavailable: return Color(designToken: DesignTokens.Color.borderDefault)
        }
    }
}
#endif
