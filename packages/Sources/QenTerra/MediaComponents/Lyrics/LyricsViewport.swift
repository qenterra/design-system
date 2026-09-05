#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum LyricsScrollDecision<ID: Hashable & Sendable>: Equatable, Sendable {
    case none
    case line(id: ID, duration: Double)

    public static func resolve(
        previousIdentity: ID?,
        currentIdentity: ID?,
        reducesMotion: Bool
    ) -> Self {
        guard currentIdentity != previousIdentity, let currentIdentity else { return .none }
        return .line(
            id: currentIdentity,
            duration: reducesMotion
                ? 0
                : DesignTokens.Component.panelLyricsFollowDurationMs.milliseconds / 1000
        )
    }
}

public struct LyricsViewport<ID: Hashable & Sendable>: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let lines: [LyricLinePresentation<ID>]
    private let currentIdentity: ID?
    private let textSize: CGFloat
    private let alignment: TextAlignment
    private let showsEdgeFade: Bool
    private let selectLine: @MainActor (ID) -> Void
    private let editLine: @MainActor (ID) -> Void
    @State private var followedIdentity: ID?

    public init(
        lines: [LyricLinePresentation<ID>],
        currentIdentity: ID?,
        textSize: CGFloat,
        alignment: TextAlignment,
        showsEdgeFade: Bool = true,
        selectLine: @escaping @MainActor (ID) -> Void,
        editLine: @escaping @MainActor (ID) -> Void
    ) {
        self.lines = lines
        self.currentIdentity = currentIdentity
        self.textSize = textSize.isFinite ? max(textSize, 1) : 1
        self.alignment = alignment
        self.showsEdgeFade = showsEdgeFade
        self.selectLine = selectLine
        self.editLine = editLine
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(
                    alignment: stackAlignment,
                    spacing: DesignTokens.Component.panelLyricsLineGap.points
                ) {
                    ForEach(lines) { line in
                        LyricLine(
                            presentation: line,
                            textSize: textSize,
                            alignment: alignment,
                            select: { selectLine(line.id) },
                            edit: { editLine(line.id) }
                        )
                        .id(line.id)
                    }
                }
                .padding(.horizontal, DesignTokens.Component.panelLyricsViewportHorizontalPadding.points)
                .padding(.vertical, DesignTokens.Component.panelLyricsViewportVerticalPadding.points)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
            }
            .scrollIndicators(.hidden)
            .overlay {
                if showsEdgeFade { LyricsEdgeFade() }
            }
            .onChange(of: currentIdentity, initial: true) { _, identity in
                let decision = LyricsScrollDecision.resolve(
                    previousIdentity: followedIdentity,
                    currentIdentity: identity,
                    reducesMotion: environment.reducesMotion
                )
                followedIdentity = identity
                apply(decision, proxy: proxy)
            }
        }
    }

    private func apply(_ decision: LyricsScrollDecision<ID>, proxy: ScrollViewProxy) {
        switch decision {
        case .none:
            break
        case let .line(id, duration):
            if duration > 0 {
                withAnimation(.smooth(duration: duration)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            } else {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }

    private var stackAlignment: HorizontalAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}
#endif
