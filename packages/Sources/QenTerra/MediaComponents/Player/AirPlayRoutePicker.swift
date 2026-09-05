#if os(macOS)
import AVFoundation
import AVKit
import SwiftUI

public struct AirPlayRoutePicker: NSViewRepresentable {
    private final class WeakPlayerReference {
        weak var player: AVPlayer?

        init(_ player: AVPlayer?) {
            self.player = player
        }
    }

    private let playerReference: WeakPlayerReference

    public init(player: AVPlayer?) {
        playerReference = WeakPlayerReference(player)
    }

    public func makeNSView(context _: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        picker.player = Self.routingPlayer(playerReference.player)
        return picker
    }

    public func updateNSView(_ picker: AVRoutePickerView, context _: Context) {
        picker.player = Self.routingPlayer(playerReference.player)
    }

    static func routingPlayer(_ player: AVPlayer?) -> AVPlayer? {
        guard player?.currentItem != nil else { return nil }
        return player
    }
}
#endif
