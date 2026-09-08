#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public enum TransportControl: CaseIterable, Equatable, Sendable {
    case shuffle
    case previous
    case playPause
    case next
    case repeatMode
}

public struct TransportControlPresentation: Equatable, Sendable {
    public let control: TransportControl
    public let symbolName: String
    public let accessibilityLabel: String
    public let accessibilityValue: String?
    public let isEnabled: Bool
    public let isActive: Bool

    public static func all(
        hasCurrentItem: Bool,
        isPlaying: Bool,
        isShuffleEnabled: Bool,
        repeatMode: TransportRepeatMode,
        isShuffleActionAvailable: Bool = true,
        isRepeatActionAvailable: Bool = true
    ) -> [Self] {
        TransportControl.allCases.map { control in
            let isActionAvailable: Bool
            switch control {
            case .shuffle: isActionAvailable = isShuffleActionAvailable
            case .repeatMode: isActionAvailable = isRepeatActionAvailable
            default: isActionAvailable = true
            }
            return resolve(
                control,
                hasCurrentItem: hasCurrentItem,
                isPlaying: isPlaying,
                isShuffleEnabled: isShuffleEnabled,
                repeatMode: repeatMode,
                isActionAvailable: isActionAvailable
            )
        }
    }

    public static func resolve(
        _ control: TransportControl,
        hasCurrentItem: Bool,
        isPlaying: Bool,
        isShuffleEnabled: Bool,
        repeatMode: TransportRepeatMode,
        isActionAvailable: Bool = true
    ) -> Self {
        let symbol: String
        let label: String
        let accessibilityValue: String?
        let active: Bool
        switch control {
        case .shuffle:
            symbol = "shuffle"
            label = String(localized: "Shuffle")
            active = isShuffleEnabled
            accessibilityValue = active ? String(localized: "On") : String(localized: "Off")
        case .previous:
            symbol = "backward.fill"
            label = String(localized: "Previous Track")
            active = false
            accessibilityValue = nil
        case .playPause:
            symbol = isPlaying ? "pause.fill" : "play.fill"
            label = isPlaying ? String(localized: "Pause") : String(localized: "Play")
            active = isPlaying
            accessibilityValue = nil
        case .next:
            symbol = "forward.fill"
            label = String(localized: "Next Track")
            active = false
            accessibilityValue = nil
        case .repeatMode:
            switch repeatMode {
            case .off:
                symbol = "repeat"
                label = String(localized: "Repeat Off")
                active = false
            case .all:
                symbol = "repeat"
                label = String(localized: "Repeat All")
                active = true
            case .one:
                symbol = "repeat.1"
                label = String(localized: "Repeat One")
                active = true
            }
            accessibilityValue = nil
        }
        return Self(
            control: control,
            symbolName: symbol,
            accessibilityLabel: label,
            accessibilityValue: accessibilityValue,
            isEnabled: hasCurrentItem && isActionAvailable,
            isActive: active
        )
    }
}

public struct TransportControls: View {
    @Environment(\.designNativeEnvironment) private var environment
    private let presentation: PlayerBarPresentation
    private let actions: PlayerBarActions

    public init(presentation: PlayerBarPresentation, actions: PlayerBarActions) {
        self.presentation = presentation
        self.actions = actions
    }

    public var body: some View {
        HStack(spacing: DesignProductMetrics.cadence.controlGap) {
            ForEach(TransportControl.allCases, id: \.self) { control in
                let item = TransportControlPresentation.resolve(
                    control,
                    hasCurrentItem: presentation.hasCurrentItem,
                    isPlaying: presentation.isPlaying,
                    isShuffleEnabled: presentation.isShuffleEnabled,
                    repeatMode: presentation.repeatMode,
                    isActionAvailable: actionIsAvailable(for: control)
                )
                Button { perform(control) } label: {
                    Image(systemName: item.symbolName)
                        .symbolVariant(item.isActive ? .fill : .none)
                        .font(
                            control == .playPause
                                ? .system(size: 14, weight: .bold)
                                : .body
                        )
                        .foregroundStyle(
                            control == .playPause
                                ? Color(designToken: DesignTokens.Color.surfaceContent)
                                : primaryControlColor
                        )
                        .frame(
                            width: DesignTokens.Component.panelPlayerControlSize.points,
                            height: DesignTokens.Component.panelPlayerControlSize.points
                        )
                        .background {
                            if control == .playPause {
                                Circle().fill(primaryControlColor)
                            } else if item.isActive {
                                RoundedRectangle(
                                    cornerRadius: DesignTokens.Radius.control,
                                    style: .continuous
                                )
                                .fill(Color(designToken: DesignTokens.Color.fillSelected))
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(!item.isEnabled)
                .accessibilityLabel(Text(verbatim: item.accessibilityLabel))
                .accessibilityValue(Text(verbatim: item.accessibilityValue ?? ""))
                .help(Text(verbatim: item.accessibilityLabel))
            }
        }
    }

    private func perform(_ control: TransportControl) {
        switch control {
        case .shuffle: actions.toggleShuffle?()
        case .previous: actions.previous()
        case .playPause: actions.togglePlayback()
        case .next: actions.next()
        case .repeatMode: actions.cycleRepeatMode?()
        }
    }

    private func actionIsAvailable(for control: TransportControl) -> Bool {
        switch control {
        case .shuffle: actions.toggleShuffle != nil
        case .repeatMode: actions.cycleRepeatMode != nil
        default: true
        }
    }

    private var primaryControlColor: Color {
        environment.productProfile == .cadence
            ? Color(designToken: DesignTokens.Color.textPrimary)
            : Color.primary
    }
}
#endif
