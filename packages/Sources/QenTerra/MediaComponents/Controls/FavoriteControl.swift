#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct FavoritePresentation: Equatable, Sendable {
    public let isFavorite: Bool
    public let isPending: Bool
    public let isRevealed: Bool
    public let accessibilityLabel: String
    public let accessibilityValue: String

    public init(
        isFavorite: Bool,
        isPending: Bool,
        isRevealed: Bool,
        accessibilityLabel: String,
        accessibilityValue: String
    ) {
        self.isFavorite = isFavorite
        self.isPending = isPending
        self.isRevealed = isRevealed
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
    }

    public static func resolve(
        isFavorite: Bool,
        isPending: Bool,
        isHovered: Bool,
        isFocused: Bool,
        accessibilityLabel: String,
        accessibilityValue: String
    ) -> Self {
        Self(
            isFavorite: isFavorite,
            isPending: isPending,
            isRevealed: isHovered || isFocused,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue
        )
    }

    public var visualOpacity: Double { isRevealed || isPending ? 1 : 0 }
    public var acceptsPointerInteraction: Bool { isRevealed && !isPending }
    public var isEnabled: Bool { !isPending }
    public var requestedValue: Bool { !isFavorite }
    public var symbolName: String { isFavorite ? "heart.fill" : "heart" }
}

public struct FavoriteControl: View {
    @Environment(\.designNativeEnvironment) private var environment
    @FocusState private var isFocused: Bool

    private let presentation: FavoritePresentation
    private let interactionContext: MediaAccessoryInteractionContext
    private let controlSize: CGFloat
    private let action: @MainActor (Bool) -> Void

    public init(
        presentation: FavoritePresentation,
        interactionContext: MediaAccessoryInteractionContext = .init(),
        controlSize: CGFloat = CGFloat(
            DesignTokens.Component.panelMediaCollectionFavoriteControlSize.points
        ),
        action: @escaping @MainActor (Bool) -> Void
    ) {
        self.presentation = presentation
        self.interactionContext = interactionContext
        self.controlSize = controlSize.isFinite ? max(controlSize, 0) : 0
        self.action = action
    }

    public var body: some View {
        Button {
            guard presentation.isEnabled else { return }
            action(presentation.requestedValue)
        } label: {
            Image(systemName: presentation.symbolName)
                .foregroundStyle(presentation.isFavorite ? Color.accentColor : .secondary)
                .frame(width: controlSize, height: controlSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($isFocused)
        .disabled(!presentation.isEnabled)
        .opacity(isRevealed ? 1 : 0)
        .allowsHitTesting(isRevealed)
        .animation(
            environment.reducesMotion
                ? nil
                : .easeOut(duration: DesignTokens.Motion.feedbackHover.seconds),
            value: isRevealed
        )
        .accessibilityLabel(Text(verbatim: presentation.accessibilityLabel))
        .accessibilityValue(Text(verbatim: presentation.accessibilityValue))
        .help(Text(verbatim: presentation.accessibilityLabel))
    }

    private var isRevealed: Bool {
        presentation.isRevealed
            || presentation.isPending
            || interactionContext.isContainerHovered
            || interactionContext.isContainerFocused
            || isFocused
    }
}
#endif
