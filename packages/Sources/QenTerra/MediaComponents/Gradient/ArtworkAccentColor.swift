#if os(macOS)
    import Foundation

    /// A display-sRGB artwork colour supplied by the consumer.
    public struct ArtworkAccentColor: Hashable, Sendable {
        public let red: Double
        public let green: Double
        public let blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = min(max(red.isFinite ? red : 0, 0), 1)
            self.green = min(max(green.isFinite ? green : 0, 0), 1)
            self.blue = min(max(blue.isFinite ? blue : 0, 0), 1)
        }

        var relativeLuminance: Double {
            red * 0.2126 + green * 0.7152 + blue * 0.0722
        }

        func mixed(with other: Self, amount: Double) -> Self {
            Self(
                red: red + (other.red - red) * amount,
                green: green + (other.green - green) * amount,
                blue: blue + (other.blue - blue) * amount
            )
        }

        func scaled(by amount: Double) -> Self {
            Self(red: red * amount, green: green * amount, blue: blue * amount)
        }
    }
#endif
