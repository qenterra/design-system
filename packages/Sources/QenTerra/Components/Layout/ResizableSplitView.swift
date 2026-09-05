#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct ResizableSplitLayout: Equatable, Sendable {
    public struct Resolution: Equatable, Sendable {
        public let leadingWidth: Double
        public let trailingWidth: Double
        public let separatorWidth: Double

        public init(
            leadingWidth: Double,
            trailingWidth: Double,
            separatorWidth: Double = DesignTokens.Stroke.hairline
        ) {
            self.leadingWidth = leadingWidth
            self.trailingWidth = trailingWidth
            self.separatorWidth = separatorWidth
        }
    }

    public enum AdjustmentDirection: Equatable, Sendable {
        case increment
        case decrement
    }

    public static func normalizedSeparatorWidth(
        _ separatorWidth: Double,
        availableWidth: Double = .greatestFiniteMagnitude
    ) -> Double {
        min(max(0, availableWidth), max(DesignTokens.Stroke.hairline, separatorWidth))
    }

    public static func pointerTargetWidth(for separatorWidth: Double) -> Double {
        max(DesignTokens.Size.targetPointer, normalizedSeparatorWidth(separatorWidth))
    }

    public static func resolve(
        availableWidth: Double,
        proposedLeadingWidth: Double,
        minimumLeadingWidth: Double,
        minimumTrailingWidth: Double,
        separatorWidth: Double
    ) -> Resolution {
        let resolvedSeparatorWidth = normalizedSeparatorWidth(
            separatorWidth,
            availableWidth: availableWidth
        )
        let contentWidth = max(0, availableWidth - resolvedSeparatorWidth)
        let leadingMinimum = min(max(0, minimumLeadingWidth), contentWidth)
        let trailingMinimum = min(max(0, minimumTrailingWidth), contentWidth - leadingMinimum)
        let leadingMaximum = max(leadingMinimum, contentWidth - trailingMinimum)
        let leadingWidth = min(max(proposedLeadingWidth, leadingMinimum), leadingMaximum)
        return Resolution(
            leadingWidth: leadingWidth,
            trailingWidth: contentWidth - leadingWidth,
            separatorWidth: resolvedSeparatorWidth
        )
    }

    public static func adjustedLeadingWidth(
        currentLeadingWidth: Double,
        direction: AdjustmentDirection,
        step: Double,
        availableWidth: Double,
        minimumLeadingWidth: Double,
        minimumTrailingWidth: Double,
        separatorWidth: Double
    ) -> Double {
        let delta = direction == .increment ? abs(step) : -abs(step)
        return resolve(
            availableWidth: availableWidth,
            proposedLeadingWidth: currentLeadingWidth + delta,
            minimumLeadingWidth: minimumLeadingWidth,
            minimumTrailingWidth: minimumTrailingWidth,
            separatorWidth: separatorWidth
        ).leadingWidth
    }
}

public struct ResizableSplitView<Leading: View, Trailing: View>: View {
    @Binding private var leadingWidth: Double
    private let minimumLeadingWidth: Double
    private let minimumTrailingWidth: Double
    private let separatorWidth: Double
    private let leading: Leading
    private let trailing: Trailing
    @State private var dragOrigin: Double?
    @State private var liveLeadingWidth: Double?

    public init(
        leadingWidth: Binding<Double>,
        minimumLeadingWidth: Double,
        minimumTrailingWidth: Double,
        separatorWidth: Double = 1,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        _leadingWidth = leadingWidth
        self.minimumLeadingWidth = minimumLeadingWidth
        self.minimumTrailingWidth = minimumTrailingWidth
        self.separatorWidth = separatorWidth
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        GeometryReader { proxy in
            let resolution = ResizableSplitLayout.resolve(
                availableWidth: proxy.size.width,
                proposedLeadingWidth: liveLeadingWidth ?? leadingWidth,
                minimumLeadingWidth: minimumLeadingWidth,
                minimumTrailingWidth: minimumTrailingWidth,
                separatorWidth: separatorWidth
            )
            HStack(spacing: 0) {
                leading
                    .frame(width: resolution.leadingWidth, alignment: .leading)
                divider(
                    resolution: resolution,
                    availableWidth: proxy.size.width
                )
                trailing
                    .frame(width: resolution.trailingWidth, alignment: .leading)
            }
        }
    }

    private func divider(
        resolution: ResizableSplitLayout.Resolution,
        availableWidth: Double
    ) -> some View {
        Color.clear
            .frame(width: resolution.separatorWidth)
            .overlay {
                Color.clear
                    .frame(width: ResizableSplitLayout.pointerTargetWidth(for: resolution.separatorWidth))
                    .contentShape(Rectangle())
                    .gesture(dragGesture(availableWidth: availableWidth))
                    .overlay {
                        DesignSeparator(orientation: .vertical)
                            .frame(width: DesignTokens.Stroke.hairline)
                    }
                    .resizableSplitKeyboardControls(
                        onDecrement: {
                            adjustLeadingWidth(
                                direction: .decrement,
                                availableWidth: availableWidth
                            )
                        },
                        onIncrement: {
                            adjustLeadingWidth(
                                direction: .increment,
                                availableWidth: availableWidth
                            )
                        }
                    )
                    .accessibilityElement()
                    .accessibilityLabel("Resize panes")
                    .accessibilityValue(Int(resolution.leadingWidth).formatted())
                    .accessibilityHint("Use the left and right arrow keys to resize panes.")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment:
                            adjustLeadingWidth(
                                direction: .increment,
                                availableWidth: availableWidth
                            )
                        case .decrement:
                            adjustLeadingWidth(
                                direction: .decrement,
                                availableWidth: availableWidth
                            )
                        @unknown default:
                            break
                        }
                    }
            }
    }

    private func dragGesture(availableWidth: Double) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let origin = dragOrigin ?? (liveLeadingWidth ?? leadingWidth)
                dragOrigin = origin
                liveLeadingWidth = ResizableSplitLayout.resolve(
                    availableWidth: availableWidth,
                    proposedLeadingWidth: origin + value.translation.width,
                    minimumLeadingWidth: minimumLeadingWidth,
                    minimumTrailingWidth: minimumTrailingWidth,
                    separatorWidth: separatorWidth
                ).leadingWidth
            }
            .onEnded { _ in
                if let liveLeadingWidth {
                    leadingWidth = liveLeadingWidth
                }
                liveLeadingWidth = nil
                dragOrigin = nil
            }
    }

    private func adjustLeadingWidth(
        direction: ResizableSplitLayout.AdjustmentDirection,
        availableWidth: Double
    ) {
        leadingWidth = ResizableSplitLayout.adjustedLeadingWidth(
            currentLeadingWidth: leadingWidth,
            direction: direction,
            step: DesignTokens.Space.value3,
            availableWidth: availableWidth,
            minimumLeadingWidth: minimumLeadingWidth,
            minimumTrailingWidth: minimumTrailingWidth,
            separatorWidth: separatorWidth
        )
    }
}

private extension View {
    @ViewBuilder
    func resizableSplitKeyboardControls(
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        focusable()
            .onMoveCommand { direction in
                switch direction {
                case .left:
                    onDecrement()
                case .right:
                    onIncrement()
                default:
                    break
                }
            }
        #else
        self
        #endif
    }
}
#endif
