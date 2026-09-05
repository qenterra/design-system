#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct PlaybackProgressPresentation: Equatable, Sendable {
    public let progress: Double
    public let leadingText: String
    public let trailingText: String
    public let accessibilityLabel: String
    public let isEnabled: Bool

    public init(
        progress: Double,
        leadingText: String,
        trailingText: String,
        accessibilityLabel: String,
        isEnabled: Bool
    ) {
        self.progress = progress
        self.leadingText = leadingText
        self.trailingText = trailingText
        self.accessibilityLabel = accessibilityLabel
        self.isEnabled = isEnabled
    }

    public var clampedProgress: Double {
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }
}

struct PlaybackProgressDragState: Equatable, Sendable {
    private(set) var localProgress: Double?

    mutating func update(to progress: Double) {
        localProgress = progress.isFinite ? min(max(progress, 0), 1) : 0
    }

    mutating func finish() -> Double? {
        defer { localProgress = nil }
        return localProgress
    }

    func displayedProgress(consumerProgress: Double) -> Double {
        if let localProgress { return localProgress }
        guard consumerProgress.isFinite else { return 0 }
        return min(max(consumerProgress, 0), 1)
    }
}

public struct PlaybackProgressControl: View {
    private let presentation: PlaybackProgressPresentation
    private let seek: @MainActor (Double) -> Void
    @State private var dragState = PlaybackProgressDragState()

    public init(
        presentation: PlaybackProgressPresentation,
        seek: @escaping @MainActor (Double) -> Void
    ) {
        self.presentation = presentation
        self.seek = seek
    }

    public var body: some View {
        HStack(spacing: DesignProductMetrics.cadence.compactGap) {
            timeLabel(presentation.leadingText, alignment: .leading)
            Slider(value: progressBinding, in: 0 ... 1) { isEditing in
                guard !isEditing, let value = dragState.finish() else { return }
                seek(value)
            }
            .accessibilityLabel(Text(verbatim: presentation.accessibilityLabel))
            .accessibilityValue(Text(verbatim: presentation.leadingText))
            .disabled(!presentation.isEnabled)
            timeLabel(presentation.trailingText, alignment: .trailing)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }

    private var progressBinding: Binding<Double> {
        Binding(
            get: { dragState.displayedProgress(consumerProgress: presentation.clampedProgress) },
            set: { dragState.update(to: $0) }
        )
    }

    private func timeLabel(_ text: String, alignment: Alignment) -> some View {
        Text(verbatim: text)
            .frame(minWidth: PlayerBarLayoutMetrics.progressLabelWidth, alignment: alignment)
    }
}
#endif
