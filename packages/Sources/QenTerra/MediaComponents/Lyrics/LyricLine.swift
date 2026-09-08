#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct LyricLine<ID: Hashable & Sendable>: View {
    private let presentation: LyricLinePresentation<ID>
    private let textSize: CGFloat
    private let alignment: TextAlignment
    private let select: @MainActor () -> Void
    private let edit: @MainActor () -> Void

    public init(
        presentation: LyricLinePresentation<ID>,
        textSize: CGFloat,
        alignment: TextAlignment,
        select: @escaping @MainActor () -> Void,
        edit: @escaping @MainActor () -> Void
    ) {
        self.presentation = presentation
        self.textSize = textSize.isFinite ? max(textSize, 1) : 1
        self.alignment = alignment
        self.select = select
        self.edit = edit
    }

    public var body: some View {
        Button(action: select) {
            LyricLineLabel(
                presentation: presentation,
                textSize: textSize,
                alignment: alignment
            )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit Lyric Line", systemImage: "pencil", action: edit)
        }
        .accessibilityLabel(Text(verbatim: presentation.text))
        .accessibilityValue(presentation.isActive ? "Current lyric" : "")
    }

    private var frameAlignment: Alignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

public struct LyricLineLabel<ID: Hashable & Sendable>: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let presentation: LyricLinePresentation<ID>
    private let textSize: CGFloat
    private let alignment: TextAlignment
    private let lineLimit: Int?

    public init(
        presentation: LyricLinePresentation<ID>,
        textSize: CGFloat,
        alignment: TextAlignment,
        lineLimit: Int? = nil
    ) {
        self.presentation = presentation
        self.textSize = textSize.isFinite ? max(textSize, 1) : 1
        self.alignment = alignment
        self.lineLimit = lineLimit
    }

    public var body: some View {
        Text(verbatim: presentation.text)
            .font(.system(size: textSize, weight: .semibold))
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .lineSpacing(DesignTokens.Component.panelLyricsLineSpacing.points)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .foregroundStyle(presentation.tone == .primary ? .primary : .secondary)
            .opacity(presentation.opacity)
            .blur(radius: presentation.blurRadius)
            .animation(
                environment.reducesMotion
                    ? nil
                    : .smooth(
                        duration: DesignTokens.Component.panelLyricsFollowDurationMs.milliseconds
                            / 1000
                    ),
                value: presentation.isActive
            )
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
