#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum LyricsScrollDecision<ID: Hashable & Sendable>: Equatable, Sendable {
    case none
    case top
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

    public static func resolve<ResetID: Hashable & Sendable>(
        previousResetIdentity: ResetID?,
        currentResetIdentity: ResetID?,
        previousIdentity: ID?,
        currentIdentity: ID?,
        reducesMotion: Bool
    ) -> Self {
        if let currentResetIdentity,
           currentResetIdentity != previousResetIdentity {
            return .top
        }
        return resolve(
            previousIdentity: previousIdentity,
            currentIdentity: currentIdentity,
            reducesMotion: reducesMotion
        )
    }
}

public struct LyricsViewport<
    ID: Hashable & Sendable,
    ResetID: Hashable & Sendable,
    LineContent: View
>: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let lines: [LyricLinePresentation<ID>]
    private let currentIdentity: ID?
    private let resetIdentity: ResetID?
    private let alignment: TextAlignment
    private let showsEdgeFade: Bool
    private let lineContent: (LyricLinePresentation<ID>) -> LineContent
    @State private var followedIdentity: ID?
    @State private var followedResetIdentity: ResetID?

    public init(
        lines: [LyricLinePresentation<ID>],
        currentIdentity: ID?,
        resetIdentity: ResetID?,
        alignment: TextAlignment,
        showsEdgeFade: Bool = true,
        @ViewBuilder lineContent: @escaping (LyricLinePresentation<ID>) -> LineContent
    ) {
        self.lines = lines
        self.currentIdentity = currentIdentity
        self.resetIdentity = resetIdentity
        self.alignment = alignment
        self.showsEdgeFade = showsEdgeFade
        self.lineContent = lineContent
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(
                    alignment: stackAlignment,
                    spacing: DesignTokens.Component.panelLyricsLineGap.points
                ) {
                    ForEach(lines) { line in
                        if line.isBlankStanza {
                            Color.clear
                                .frame(
                                    height: DesignTokens.Component.panelLyricsStanzaBreakHeight
                                        .points
                                )
                                .id(line.id)
                        } else {
                            lineContent(line)
                                .id(line.id)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Component.panelLyricsViewportHorizontalPadding.points)
                .padding(.vertical, DesignTokens.Component.panelLyricsViewportVerticalPadding.points)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .id(LyricsViewportScrollTarget.top)
            }
            .scrollIndicators(.hidden)
            .overlay {
                if showsEdgeFade { LyricsEdgeFade() }
            }
            .onChange(
                of: LyricsViewportObservation(
                    currentIdentity: currentIdentity,
                    resetIdentity: resetIdentity
                ),
                initial: true
            ) { _, observation in
                let decision = LyricsScrollDecision.resolve(
                    previousResetIdentity: followedResetIdentity,
                    currentResetIdentity: observation.resetIdentity,
                    previousIdentity: followedIdentity,
                    currentIdentity: observation.currentIdentity,
                    reducesMotion: environment.reducesMotion
                )
                followedIdentity = observation.currentIdentity
                followedResetIdentity = observation.resetIdentity
                apply(decision, proxy: proxy)
            }
        }
    }

    private func apply(_ decision: LyricsScrollDecision<ID>, proxy: ScrollViewProxy) {
        switch decision {
        case .none:
            break
        case .top:
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                proxy.scrollTo(LyricsViewportScrollTarget.top, anchor: .top)
            }
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

public extension LyricsViewport where ResetID == ID, LineContent == LyricLine<ID> {
    init(
        lines: [LyricLinePresentation<ID>],
        currentIdentity: ID?,
        resetIdentity: ID? = nil,
        textSize: CGFloat,
        alignment: TextAlignment,
        showsEdgeFade: Bool = true,
        selectLine: @escaping @MainActor (ID) -> Void,
        editLine: @escaping @MainActor (ID) -> Void
    ) {
        self.init(
            lines: lines,
            currentIdentity: currentIdentity,
            resetIdentity: resetIdentity,
            alignment: alignment,
            showsEdgeFade: showsEdgeFade
        ) { line in
            LyricLine(
                presentation: line,
                textSize: textSize,
                alignment: alignment,
                select: { selectLine(line.id) },
                edit: { editLine(line.id) }
            )
        }
    }
}

private struct LyricsViewportObservation<
    ID: Hashable & Sendable,
    ResetID: Hashable & Sendable
>: Equatable {
    let currentIdentity: ID?
    let resetIdentity: ResetID?
}

private enum LyricsViewportScrollTarget {
    case top
}
#endif
