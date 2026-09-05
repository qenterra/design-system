#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct LyricLine<ID: Hashable & Sendable>: View {
    @Environment(\.designNativeEnvironment) private var environment
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
            Text(verbatim: presentation.text)
                .font(.system(size: textSize, weight: .semibold))
                .multilineTextAlignment(alignment)
                .lineSpacing(DesignTokens.Component.panelLyricsLineSpacing.points)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: frameAlignment)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(presentation.tone == .primary ? .primary : .secondary)
        .opacity(presentation.opacity)
        .blur(radius: presentation.blurRadius)
        .animation(
            environment.reducesMotion
                ? nil
                : .smooth(duration: DesignTokens.Component.panelLyricsFollowDurationMs.milliseconds / 1000),
            value: presentation.isActive
        )
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
#endif
